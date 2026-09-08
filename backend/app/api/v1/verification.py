"""Verification queue — admin review of flagged attendance attempts."""
from fastapi import APIRouter
from sqlalchemy import select

from app.core.exceptions import NotFoundError
from app.db.models.attendance_exception import AttendanceException
from app.db.models.attendance_attempt import AttendanceAttempt
from app.db.models.user import User
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import VerificationCaseOut, VerificationDecision
from app.utils.time import utcnow

router = APIRouter()


@router.get("", response_model=list[VerificationCaseOut], summary="List pending verifications")
async def list_verifications(user: CurrentUser, db: DbSession) -> list[VerificationCaseOut]:
    """Admin verificationApi.list()."""
    result = await db.execute(
        select(AttendanceException)
        .where(
            AttendanceException.organization_id == user.organization_id,
            AttendanceException.status == "NEEDS_REVIEW",
        )
        .order_by(AttendanceException.created_at.desc())
        .limit(50)
    )
    exceptions = result.scalars().all()
    out = []
    for exc in exceptions:
        attempt = await db.get(AttendanceAttempt, exc.attendance_attempt_id)
        emp = await db.get(User, exc.user_id)
        if not attempt or not emp:
            continue
        lat = attempt.latitude or 0.0
        lon = attempt.longitude or 0.0
        out.append(VerificationCaseOut(
            id=exc.id,
            employee=emp.full_name,
            scan_time=attempt.client_timestamp.strftime("%I:%M %p") if attempt.client_timestamp else "—",
            assigned_site="—",
            current_coordinates=f"{lat:.4f}, {lon:.4f}",
            distance=f"{round(attempt.distance_from_site_meters or 0)} m",
            gps_accuracy=f"{round(attempt.gps_accuracy_meters or 0)} m",
            face_score=attempt.face_score or 0.0,
            liveness_score=attempt.liveness_score or 0.0,
            status=exc.status,
            reason=exc.reason,
        ))
    return out


@router.get("/{exc_id}", response_model=VerificationCaseOut, summary="Verification detail")
async def get_verification(exc_id: str, user: CurrentUser, db: DbSession) -> VerificationCaseOut:
    exc = await db.get(AttendanceException, exc_id)
    if not exc or exc.organization_id != user.organization_id:
        raise NotFoundError()
    attempt = await db.get(AttendanceAttempt, exc.attendance_attempt_id)
    emp = await db.get(User, exc.user_id)
    lat = (attempt.latitude if attempt else None) or 0.0
    lon = (attempt.longitude if attempt else None) or 0.0
    return VerificationCaseOut(
        id=exc.id,
        employee=emp.full_name if emp else "Unknown",
        scan_time=attempt.client_timestamp.strftime("%I:%M %p") if attempt and attempt.client_timestamp else "—",
        assigned_site="—",
        current_coordinates=f"{lat:.4f}, {lon:.4f}",
        distance=f"{round((attempt.distance_from_site_meters if attempt else None) or 0)} m",
        gps_accuracy=f"{round((attempt.gps_accuracy_meters if attempt else None) or 0)} m",
        face_score=(attempt.face_score if attempt else None) or 0.0,
        liveness_score=(attempt.liveness_score if attempt else None) or 0.0,
        status=exc.status,
        reason=exc.reason,
    )


@router.post("/{exc_id}/approve", summary="Approve exception")
async def approve(exc_id: str, body: VerificationDecision, user: CurrentUser, db: DbSession) -> dict:
    exc = await db.get(AttendanceException, exc_id)
    if not exc or exc.organization_id != user.organization_id:
        raise NotFoundError()
    exc.status = "APPROVED"
    exc.reviewed_by_id = user.id
    exc.reviewed_at = utcnow()
    exc.notes = body.notes
    # Update attendance record to approved
    if exc.attendance_record_id:
        from app.db.models.attendance_record import AttendanceRecord
        record = await db.get(AttendanceRecord, exc.attendance_record_id)
        if record:
            record.status = "APPROVED_EXCEPTION"
            record.approved_by_id = user.id
            record.approved_at = utcnow()
    await db.commit()
    return {"id": exc_id, "decision": "approved"}


@router.post("/{exc_id}/reject", summary="Reject exception")
async def reject(exc_id: str, body: VerificationDecision, user: CurrentUser, db: DbSession) -> dict:
    exc = await db.get(AttendanceException, exc_id)
    if not exc or exc.organization_id != user.organization_id:
        raise NotFoundError()
    exc.status = "REJECTED"
    exc.reviewed_by_id = user.id
    exc.reviewed_at = utcnow()
    exc.notes = body.notes
    if exc.attendance_record_id:
        from app.db.models.attendance_record import AttendanceRecord
        record = await db.get(AttendanceRecord, exc.attendance_record_id)
        if record:
            record.status = "REJECTED"
    await db.commit()
    return {"id": exc_id, "decision": "rejected"}


@router.post("/{exc_id}/request-explanation", summary="Request explanation")
async def request_explanation(exc_id: str, body: VerificationDecision, user: CurrentUser, db: DbSession) -> dict:
    exc = await db.get(AttendanceException, exc_id)
    if not exc or exc.organization_id != user.organization_id:
        raise NotFoundError()
    exc.status = "PENDING_EXPLANATION"
    exc.notes = body.notes
    await db.commit()
    return {"id": exc_id, "decision": "pending_explanation"}
