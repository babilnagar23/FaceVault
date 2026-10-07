from __future__ import annotations
from typing import Optional
"""
AttendanceService — the single authoritative entry point for attendance processing.

Business Rules:
  Face match + Liveness + Location → PRESENT or LATE
  Face match + Liveness + Location mismatch → LOCATION_FAILED + exception
  Face mismatch → FACE_FAILED, attendance not recorded
  Liveness mismatch → LIVENESS_FAILED, attendance not recorded

AttendanceAttempt = raw event log (every scan, success or failure)
AttendanceRecord  = official authoritative attendance (only successful verifications)
AttendanceException = review workflow for borderline/rejected cases
"""

from datetime import datetime

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import AttemptStatus, AttendanceRecordStatus
from app.db.models.attendance_attempt import AttendanceAttempt
from app.db.models.attendance_exception import AttendanceException
from app.db.models.attendance_record import AttendanceRecord
from app.repositories.attendance_repository import AttendanceRepository
from app.repositories.assignment_repository import AssignmentRepository
from app.services.location_service import LocationService
from app.utils.time import attendance_date_local, clock_drift_seconds, utcnow


class AttendanceService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._att_repo = AttendanceRepository(db)
        self._asgn_repo = AssignmentRepository(db)
        self._loc_svc = LocationService(db)

    async def submit_attempt(
        self,
        user_id: str,
        organization_id: str,
        org_timezone: str,
        client_event_id: str,
        event_type: str,
        client_timestamp: Optional[datetime],
        latitude: Optional[float],
        longitude: Optional[float],
        gps_accuracy_meters: Optional[float],
        face_verified: bool,
        face_score: Optional[float],
        liveness_verified: bool,
        liveness_score: Optional[float],
        offline_created: bool = False,
        network_type: Optional[str] = None,
        battery_level: Optional[int] = None,
        device_id: Optional[str] = None,
        risk_flags: Optional[list] = None,
        attempt_number: int = 1,
    ) -> AttendanceAttempt:
        """
        Process one attendance attempt and return the persisted AttendanceAttempt.

        Steps:
          1. Idempotency check (return existing if already processed)
          2. Determine server-received timestamp
          3. Calculate local attendance date (using org timezone)
          4. Load effective assignment for that date
          5. Server-side geofence calculation
          6. Determine attempt status based on biometric + location results
          7. Persist AttendanceAttempt
          8. Create/update official AttendanceRecord if eligible
          9. Create AttendanceException if needed
        """
        server_now = utcnow()

        # ── 1. Idempotency ─────────────────────────────────────────────────────
        existing = await self._att_repo.get_attempt_by_event_id(client_event_id, organization_id)
        if existing:
            return existing

        # ── 2. Clock drift ─────────────────────────────────────────────────────
        clock_offset: Optional[float] = None
        if client_timestamp:
            clock_offset = clock_drift_seconds(client_timestamp, server_now)

        # ── 3. Local attendance date ───────────────────────────────────────────
        local_date = attendance_date_local(server_now, org_timezone)

        # ── 4. Effective assignment ────────────────────────────────────────────
        assignment = await self._asgn_repo.get_effective(user_id, organization_id, local_date)
        location_id: Optional[str] = None
        shift_id: Optional[str] = None
        project_id: Optional[str] = None
        assignment_id: Optional[str] = None

        if assignment:
            location_id = assignment.location_id
            shift_id = assignment.shift_id
            project_id = assignment.project_id
            assignment_id = assignment.id

        # ── 5. Server-side geofence calculation ────────────────────────────────
        distance_from_site: Optional[float] = None
        location_verified = False

        if latitude is not None and longitude is not None and location_id:
            location = await self._loc_svc.get_active_location(location_id, organization_id)
            if location:
                inside, distance = self._loc_svc.is_within_geofence(latitude, longitude, location)
                distance_from_site = distance
                location_verified = inside

        # ── 6. Determine attempt status ────────────────────────────────────────
        status = self._calculate_status(
            face_verified=face_verified,
            liveness_verified=liveness_verified,
            location_verified=location_verified,
            latitude=latitude,
            longitude=longitude,
            assignment=assignment,
        )

        # ── 7. Persist AttendanceAttempt ───────────────────────────────────────
        attempt = AttendanceAttempt(
            client_event_id=client_event_id,
            organization_id=organization_id,
            user_id=user_id,
            device_id=device_id,
            assignment_id=assignment_id,
            project_id=project_id,
            location_id=location_id,
            shift_id=shift_id,
            event_type=event_type,
            attempt_number=attempt_number,
            client_timestamp=client_timestamp,
            server_received_at=server_now,
            device_clock_offset_seconds=clock_offset,
            latitude=latitude,
            longitude=longitude,
            gps_accuracy_meters=gps_accuracy_meters,
            distance_from_site_meters=distance_from_site,
            face_verified=face_verified,
            face_score=face_score,
            liveness_verified=liveness_verified,
            liveness_score=liveness_score,
            location_verified=location_verified,
            offline_created=offline_created,
            network_type=network_type,
            battery_level=battery_level,
            status=status,
            risk_flags=risk_flags,
        )
        self._db.add(attempt)

        try:
            await self._db.flush()
        except IntegrityError:
            # Concurrent duplicate — load and return the existing one
            await self._db.rollback()
            existing = await self._att_repo.get_attempt_by_event_id(client_event_id, organization_id)
            if existing:
                return existing
            raise

        # ── 8. Create/update official AttendanceRecord ─────────────────────────
        if status in (AttemptStatus.VERIFIED, AttemptStatus.PENDING_REVIEW) and shift_id:
            await self._upsert_record(
                attempt=attempt,
                user_id=user_id,
                organization_id=organization_id,
                local_date=local_date,
                shift_id=shift_id,
                assignment_id=assignment_id,
                project_id=project_id,
                location_id=location_id,
            )

        # ── 9. Create AttendanceException if needed ────────────────────────────
        if status == AttemptStatus.LOCATION_FAILED:
            await self._create_exception(
                attempt=attempt,
                user_id=user_id,
                organization_id=organization_id,
                reason="Location verification failed — employee may be outside geofence.",
            )

        return attempt

    def _calculate_status(
        self,
        face_verified: bool,
        liveness_verified: bool,
        location_verified: bool,
        latitude: Optional[float],
        longitude: Optional[float],
        assignment,
    ) -> str:
        if not face_verified:
            return AttemptStatus.FACE_FAILED
        if not liveness_verified:
            return AttemptStatus.LIVENESS_FAILED
        if latitude is None or longitude is None:
            return AttemptStatus.GPS_FAILED
        if not assignment:
            return AttemptStatus.PENDING_REVIEW
        if not location_verified:
            return AttemptStatus.LOCATION_FAILED
        return AttemptStatus.VERIFIED

    async def _upsert_record(
        self,
        attempt: AttendanceAttempt,
        user_id: str,
        organization_id: str,
        local_date,
        shift_id: str,
        assignment_id: Optional[str],
        project_id: Optional[str],
        location_id: Optional[str],
    ) -> None:
        """Create or update the official daily AttendanceRecord."""
        record = await self._att_repo.get_record_for_date(
            user_id, organization_id, local_date, shift_id
        )

        record_status = self._record_status_from_attempt(attempt)

        if record is None:
            record = AttendanceRecord(
                organization_id=organization_id,
                user_id=user_id,
                assignment_id=assignment_id,
                project_id=project_id,
                location_id=location_id,
                shift_id=shift_id,
                attendance_date=local_date,
                status=record_status,
                source="MOBILE",
                check_in_attempt_id=attempt.id if attempt.event_type == "CHECK_IN" else None,
                check_out_attempt_id=attempt.id if attempt.event_type == "CHECK_OUT" else None,
                check_in_time=attempt.server_received_at if attempt.event_type == "CHECK_IN" else None,
                check_out_time=attempt.server_received_at if attempt.event_type == "CHECK_OUT" else None,
                face_score=attempt.face_score,
                liveness_score=attempt.liveness_score,
                location_distance_meters=attempt.distance_from_site_meters,
            )
            self._db.add(record)
        else:
            # Update with check-out time if this is a check-out
            if attempt.event_type == "CHECK_OUT" and record.check_out_time is None:
                record.check_out_time = attempt.server_received_at
                record.check_out_attempt_id = attempt.id

        try:
            await self._db.flush()
        except IntegrityError:
            # Already exists — concurrent insert, acceptable
            await self._db.rollback()

    def _record_status_from_attempt(self, attempt: AttendanceAttempt) -> str:
        if attempt.status == AttemptStatus.PENDING_REVIEW:
            return AttendanceRecordStatus.PENDING_REVIEW

        shift = getattr(attempt, 'shift', None)
        if attempt.client_timestamp and shift and hasattr(shift, 'start_time'):
            try:
                shift_h, shift_m = map(int, shift.start_time.split(":"))
                ts = attempt.client_timestamp
                minutes_late = (ts.hour * 60 + ts.minute) - (shift_h * 60 + shift_m)
                if minutes_late > getattr(shift, 'late_threshold_minutes', 30):
                    return AttendanceRecordStatus.LATE
            except Exception:
                pass

        return AttendanceRecordStatus.PRESENT

    async def _create_exception(
        self,
        attempt: AttendanceAttempt,
        user_id: str,
        organization_id: str,
        reason: str,
    ) -> None:
        exc = AttendanceException(
            organization_id=organization_id,
            attendance_attempt_id=attempt.id,
            user_id=user_id,
            status="NEEDS_REVIEW",
            reason=reason,
        )
        self._db.add(exc)
        await self._db.flush()
