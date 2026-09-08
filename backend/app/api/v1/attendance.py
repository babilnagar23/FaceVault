"""
Attendance endpoints — attempt submission, history, detail.
The server ALWAYS recalculates GPS distance server-side.
"""
from datetime import date

from fastapi import APIRouter, Query
from sqlalchemy import and_, desc, select

from app.config import settings
from app.core.constants import (
    AttemptStatus,
    AttendanceRecordStatus,
    RiskFlag,
)
from app.core.exceptions import AttendanceNotFoundError, AssignmentNotFoundError
from app.db.models.assignment import Assignment
from app.db.models.attendance_attempt import AttendanceAttempt
from app.db.models.attendance_exception import AttendanceException
from app.db.models.attendance_record import AttendanceRecord
from app.db.models.location import Location
from app.db.models.shift import Shift
from app.dependencies import CurrentUser, DbSession
from app.geo.anti_spoof import detect_risk_flags
from app.geo.geofence import validate_geofence
from app.schemas.attendance import (
    AttendanceAttemptCreate,
    AttendanceAttemptOut,
    AttendanceRecordOut,
)
from app.utils.time import clock_drift_seconds, utcnow

router = APIRouter()


def _attempt_status_to_record_status(attempt: AttendanceAttempt, shift: Shift | None) -> str:
    """Map attempt result to official attendance status."""
    if attempt.status not in (AttemptStatus.VERIFIED, AttemptStatus.PENDING_REVIEW):
        return AttendanceRecordStatus.ABSENT
    if attempt.status == AttemptStatus.PENDING_REVIEW:
        return AttendanceRecordStatus.PENDING_REVIEW

    if not shift or not attempt.client_timestamp:
        return AttendanceRecordStatus.PRESENT

    # Parse shift start time
    try:
        shift_h, shift_m = map(int, shift.start_time.split(":"))
        checkin_h = attempt.client_timestamp.hour
        checkin_m = attempt.client_timestamp.minute
        minutes_late = (checkin_h * 60 + checkin_m) - (shift_h * 60 + shift_m)
        if minutes_late > shift.late_threshold_minutes:
            return AttendanceRecordStatus.LATE
    except Exception:
        pass

    return AttendanceRecordStatus.PRESENT


@router.post("/attendance/attempt", response_model=AttendanceAttemptOut, summary="Submit attendance attempt")
async def submit_attempt(
    body: AttendanceAttemptCreate,
    user: CurrentUser,
    db: DbSession,
) -> AttendanceAttemptOut:
    """
    Implements Flutter AttendanceApi.markAttendance() and runVerification().
    - Accepts biometric results from mobile (face + liveness)
    - Server recalculates GPS distance independently
    - Creates AttendanceAttempt record
    - Conditionally creates/updates AttendanceRecord
    - Sends to verification queue if needed
    """
    server_now = utcnow()

    # ── Check idempotency — return existing if already processed ──────────────
    existing = await db.execute(
        select(AttendanceAttempt).where(AttendanceAttempt.client_event_id == body.client_event_id)
    )
    existing_attempt = existing.scalar_one_or_none()
    if existing_attempt:
        return _to_attempt_out(existing_attempt)

    # ── Load active assignment ────────────────────────────────────────────────
    assignment_result = await db.execute(
        select(Assignment)
        .where(
            Assignment.user_id == user.id,
            Assignment.is_active == True,
        )
        .order_by(desc(Assignment.created_at))
        .limit(1)
    )
    assignment = assignment_result.scalar_one_or_none()

    location: Location | None = None
    shift: Shift | None = None
    if assignment:
        loc_result = await db.execute(select(Location).where(Location.id == assignment.location_id))
        location = loc_result.scalar_one_or_none()
        shift_result = await db.execute(select(Shift).where(Shift.id == assignment.shift_id))
        shift = shift_result.scalar_one_or_none()

    # ── Server-side GPS validation ────────────────────────────────────────────
    location_verified = False
    distance_meters: float | None = None

    if location and body.latitude is not None and body.longitude is not None:
        geo = validate_geofence(
            user_lat=body.latitude,
            user_lon=body.longitude,
            site_lat=location.latitude,
            site_lon=location.longitude,
            radius_meters=location.radius_meters,
            location_name=location.name,
        )
        location_verified = geo.inside
        distance_meters = geo.distance_meters
    elif body.latitude is None or body.longitude is None:
        # No GPS — offline attempt
        location_verified = False

    # ── Clock drift ───────────────────────────────────────────────────────────
    clock_offset = None
    if body.client_timestamp:
        clock_offset = clock_drift_seconds(body.client_timestamp, server_now)

    # ── Risk flag detection ───────────────────────────────────────────────────
    risk_flags = detect_risk_flags(
        gps_accuracy_meters=body.gps_accuracy_meters,
        client_timestamp=body.client_timestamp,
        server_timestamp=server_now,
    )

    # ── Determine attempt status ───────────────────────────────────────────────
    if not body.face_verified:
        status = AttemptStatus.FACE_FAILED
        failure_reason = "Face verification failed."
    elif not body.liveness_verified:
        status = AttemptStatus.LIVENESS_FAILED
        failure_reason = "Liveness check failed."
    elif location and not location_verified:
        status = AttemptStatus.LOCATION_FAILED
        failure_reason = f"Outside geofence: {round(distance_meters or 0)}m from site."
    elif risk_flags:
        status = AttemptStatus.PENDING_REVIEW
        failure_reason = f"Risk signals: {', '.join(risk_flags)}"
    else:
        status = AttemptStatus.VERIFIED
        failure_reason = None

    # ── Persist AttendanceAttempt ─────────────────────────────────────────────
    attempt = AttendanceAttempt(
        client_event_id=body.client_event_id,
        organization_id=user.organization_id,
        user_id=user.id,
        assignment_id=assignment.id if assignment else None,
        project_id=assignment.project_id if assignment else None,
        location_id=assignment.location_id if assignment else None,
        shift_id=assignment.shift_id if assignment else None,
        event_type=body.event_type,
        client_timestamp=body.client_timestamp,
        server_received_at=server_now,
        device_clock_offset_seconds=clock_offset,
        latitude=body.latitude,
        longitude=body.longitude,
        gps_accuracy_meters=body.gps_accuracy_meters,
        distance_from_site_meters=distance_meters,
        face_verified=body.face_verified,
        face_score=body.face_score,
        liveness_verified=body.liveness_verified,
        liveness_score=body.liveness_score,
        location_verified=location_verified,
        offline_created=body.offline_created,
        network_type=body.network_type,
        battery_level=body.battery_level,
        status=status,
        failure_reason=failure_reason,
        risk_flags=risk_flags if risk_flags else None,
        event_signature=body.event_signature,
        signature_algorithm=body.signature_algorithm,
    )
    db.add(attempt)
    await db.flush()  # get attempt.id

    attendance_record_id: str | None = None

    # ── Create/update AttendanceRecord for successful attempts ─────────────────
    if status in (AttemptStatus.VERIFIED, AttemptStatus.PENDING_REVIEW):
        attendance_date_val = (body.client_timestamp or server_now).date()

        record_result = await db.execute(
            select(AttendanceRecord).where(
                AttendanceRecord.user_id == user.id,
                AttendanceRecord.attendance_date == attendance_date_val,
            )
        )
        record = record_result.scalar_one_or_none()

        record_status = _attempt_status_to_record_status(attempt, shift)

        if not record:
            record = AttendanceRecord(
                organization_id=user.organization_id,
                user_id=user.id,
                assignment_id=assignment.id if assignment else None,
                project_id=assignment.project_id if assignment else None,
                location_id=assignment.location_id if assignment else None,
                shift_id=assignment.shift_id if assignment else None,
                attendance_date=attendance_date_val,
                check_in_attempt_id=attempt.id if body.event_type == "CHECK_IN" else None,
                check_out_attempt_id=attempt.id if body.event_type == "CHECK_OUT" else None,
                check_in_time=attempt.client_timestamp if body.event_type == "CHECK_IN" else None,
                check_out_time=attempt.client_timestamp if body.event_type == "CHECK_OUT" else None,
                status=record_status,
                face_score=body.face_score,
                liveness_score=body.liveness_score,
                location_distance_meters=distance_meters,
                remarks=failure_reason,
            )
            db.add(record)
            await db.flush()
        elif body.event_type == "CHECK_OUT" and not record.check_out_time:
            record.check_out_attempt_id = attempt.id
            record.check_out_time = attempt.client_timestamp

        attendance_record_id = record.id

        # ── Send to verification queue if pending review ───────────────────────
        if status == AttemptStatus.PENDING_REVIEW:
            exception = AttendanceException(
                organization_id=user.organization_id,
                attendance_attempt_id=attempt.id,
                attendance_record_id=record.id,
                user_id=user.id,
                status="NEEDS_REVIEW",
                reason=failure_reason,
            )
            db.add(exception)

    await db.commit()
    await db.refresh(attempt)
    result = _to_attempt_out(attempt)
    result.attendance_record_id = attendance_record_id
    return result


@router.get("/attendance/history", response_model=list[AttendanceRecordOut], summary="Attendance history")
async def attendance_history(
    user: CurrentUser,
    db: DbSession,
    limit: int = Query(default=30, ge=1, le=90),
    offset: int = Query(default=0, ge=0),
) -> list[AttendanceRecordOut]:
    """Flutter AttendanceApi.history()."""
    result = await db.execute(
        select(AttendanceRecord)
        .where(AttendanceRecord.user_id == user.id)
        .order_by(desc(AttendanceRecord.attendance_date))
        .limit(limit)
        .offset(offset)
    )
    records = result.scalars().all()
    return [_to_record_out(r) for r in records]


@router.get("/attendance/today", response_model=AttendanceRecordOut | None, summary="Today's attendance")
async def today_attendance(user: CurrentUser, db: DbSession) -> AttendanceRecordOut | None:
    today = utcnow().date()
    result = await db.execute(
        select(AttendanceRecord).where(
            AttendanceRecord.user_id == user.id,
            AttendanceRecord.attendance_date == today,
        )
    )
    record = result.scalar_one_or_none()
    return _to_record_out(record) if record else None


@router.get("/attendance/{record_id}", response_model=AttendanceRecordOut, summary="Attendance detail")
async def attendance_detail(record_id: str, user: CurrentUser, db: DbSession) -> AttendanceRecordOut:
    """Flutter AttendanceApi.detail(id)."""
    result = await db.execute(
        select(AttendanceRecord).where(
            AttendanceRecord.id == record_id,
            AttendanceRecord.user_id == user.id,
        )
    )
    record = result.scalar_one_or_none()
    if not record:
        raise AttendanceNotFoundError()
    return _to_record_out(record)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _to_attempt_out(attempt: AttendanceAttempt, attendance_record_id: str | None = None) -> AttendanceAttemptOut:
    return AttendanceAttemptOut(
        id=attempt.id,
        client_event_id=attempt.client_event_id,
        status=attempt.status,
        event_type=attempt.event_type,
        face_verified=attempt.face_verified,
        face_score=attempt.face_score,
        liveness_verified=attempt.liveness_verified,
        liveness_score=attempt.liveness_score,
        location_verified=attempt.location_verified,
        distance_from_site_meters=attempt.distance_from_site_meters,
        gps_accuracy_meters=attempt.gps_accuracy_meters,
        failure_reason=attempt.failure_reason,
        risk_flags=attempt.risk_flags,
        server_received_at=attempt.server_received_at,
        attendance_record_id=attendance_record_id,
    )


def _to_record_out(record: AttendanceRecord) -> AttendanceRecordOut:
    face_status = "Verified" if record.face_score and record.face_score >= 0.85 else "Failed"
    liveness_status = "Verified" if record.liveness_score and record.liveness_score >= 0.80 else "Failed"
    location_status = "Verified" if (record.location_distance_meters is not None and record.location_distance_meters < 200) else "Unknown"

    return AttendanceRecordOut(
        id=record.id,
        attendance_date=record.attendance_date.isoformat() if record.attendance_date else "",
        status=record.status,
        check_in_time=record.check_in_time,
        check_out_time=record.check_out_time,
        assigned_site=None,  # Join populated in production
        distance_meters=int(record.location_distance_meters) if record.location_distance_meters else None,
        face_status=face_status,
        liveness_status=liveness_status,
        location_status=location_status,
        sync_status="SYNCED",
        remarks=record.remarks,
        face_score=record.face_score,
        liveness_score=record.liveness_score,
    )
