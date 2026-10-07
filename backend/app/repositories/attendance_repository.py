from __future__ import annotations
from typing import Optional
"""
Attendance Repository — queries for attendance attempts, records, and exceptions.
Always scoped by organization_id.
"""

from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.attendance_attempt import AttendanceAttempt
from app.db.models.attendance_exception import AttendanceException
from app.db.models.attendance_record import AttendanceRecord


class AttendanceRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    # ── Attempt ───────────────────────────────────────────────────────────────

    async def get_attempt_by_event_id(
        self, client_event_id: str, organization_id: str
    ) -> Optional[AttendanceAttempt]:
        """Idempotency lookup — returns existing attempt for a given client_event_id."""
        result = await self._db.execute(
            select(AttendanceAttempt).where(
                AttendanceAttempt.client_event_id == client_event_id,
                AttendanceAttempt.organization_id == organization_id,
            )
        )
        return result.scalar_one_or_none()

    async def get_attempt_by_id(
        self, attempt_id: str, organization_id: str
    ) -> Optional[AttendanceAttempt]:
        result = await self._db.execute(
            select(AttendanceAttempt).where(
                AttendanceAttempt.id == attempt_id,
                AttendanceAttempt.organization_id == organization_id,
            )
        )
        return result.scalar_one_or_none()

    # ── Official Record ───────────────────────────────────────────────────────

    async def get_record_for_date(
        self,
        user_id: str,
        organization_id: str,
        attendance_date: date,
        shift_id: str,
    ) -> Optional[AttendanceRecord]:
        """Load the official daily record for a user+date+shift combination."""
        result = await self._db.execute(
            select(AttendanceRecord).where(
                AttendanceRecord.user_id == user_id,
                AttendanceRecord.organization_id == organization_id,
                AttendanceRecord.attendance_date == attendance_date,
                AttendanceRecord.shift_id == shift_id,
            )
        )
        return result.scalar_one_or_none()

    # ── Exception ─────────────────────────────────────────────────────────────

    async def get_exception_by_attempt(
        self, attempt_id: str, organization_id: str
    ) -> Optional[AttendanceException]:
        result = await self._db.execute(
            select(AttendanceException).where(
                AttendanceException.attendance_attempt_id == attempt_id,
                AttendanceException.organization_id == organization_id,
            )
        )
        return result.scalar_one_or_none()

    async def get_exception_by_id(
        self, exception_id: str, organization_id: str
    ) -> Optional[AttendanceException]:
        result = await self._db.execute(
            select(AttendanceException).where(
                AttendanceException.id == exception_id,
                AttendanceException.organization_id == organization_id,
            )
        )
        return result.scalar_one_or_none()

    async def list_pending_exceptions(
        self, organization_id: str
    ) -> list[AttendanceException]:
        result = await self._db.execute(
            select(AttendanceException).where(
                AttendanceException.organization_id == organization_id,
                AttendanceException.status.in_(["NEEDS_REVIEW", "PENDING_EXPLANATION"]),
            )
        )
        return list(result.scalars().all())
