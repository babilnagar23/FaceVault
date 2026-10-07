from __future__ import annotations
from typing import Optional
"""
VerificationService — owns the verification/review workflow for attendance exceptions.

Every review decision is audited.
State transitions:
  NEEDS_REVIEW → APPROVED / REJECTED / PENDING_EXPLANATION
  PENDING_EXPLANATION → APPROVED / REJECTED
"""

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import AttendanceRecordStatus, VerificationStatus
from app.db.models.attendance_exception import AttendanceException
from app.db.models.attendance_record import AttendanceRecord
from app.repositories.attendance_repository import AttendanceRepository
from app.services.audit_service import AuditService
from app.utils.time import utcnow


class VerificationService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._repo = AttendanceRepository(db)
        self._audit = AuditService(db)

    async def get_exception(
        self, exception_id: str, organization_id: str
    ) -> Optional[AttendanceException]:
        return await self._repo.get_exception_by_id(exception_id, organization_id)

    async def list_pending(self, organization_id: str) -> list[AttendanceException]:
        return await self._repo.list_pending_exceptions(organization_id)

    async def approve(
        self,
        exception_id: str,
        organization_id: str,
        reviewer_id: str,
        notes: Optional[str] = None,
        ip_address: Optional[str] = None,
    ) -> AttendanceException:
        """
        Approve an attendance exception.
        Updates the AttendanceException and the linked AttendanceRecord.
        """
        exc = await self._get_or_raise(exception_id, organization_id)

        exc.status = VerificationStatus.APPROVED
        exc.reviewed_by_id = reviewer_id
        exc.reviewed_at = utcnow()
        exc.notes = notes

        # Update the official attendance record
        if exc.attendance_record_id:
            from sqlalchemy import select
            rec_result = await self._db.execute(
                select(AttendanceRecord).where(
                    AttendanceRecord.id == exc.attendance_record_id,
                    AttendanceRecord.organization_id == organization_id,
                )
            )
            record = rec_result.scalar_one_or_none()
            if record:
                record.status = AttendanceRecordStatus.APPROVED_EXCEPTION
                record.approved_by_id = reviewer_id
                record.approved_at = utcnow()
                record.remarks = notes

        await self._db.flush()

        await self._audit.log(
            organization_id=organization_id,
            actor_id=reviewer_id,
            action="attendance_exception.approve",
            entity_type="attendance_exception",
            entity_id=exception_id,
            ip_address=ip_address,
        )

        return exc

    async def reject(
        self,
        exception_id: str,
        organization_id: str,
        reviewer_id: str,
        notes: Optional[str] = None,
        ip_address: Optional[str] = None,
    ) -> AttendanceException:
        """Reject an attendance exception."""
        exc = await self._get_or_raise(exception_id, organization_id)

        exc.status = VerificationStatus.REJECTED
        exc.reviewed_by_id = reviewer_id
        exc.reviewed_at = utcnow()
        exc.notes = notes

        if exc.attendance_record_id:
            from sqlalchemy import select
            rec_result = await self._db.execute(
                select(AttendanceRecord).where(
                    AttendanceRecord.id == exc.attendance_record_id,
                    AttendanceRecord.organization_id == organization_id,
                )
            )
            record = rec_result.scalar_one_or_none()
            if record:
                record.status = AttendanceRecordStatus.REJECTED
                record.approved_by_id = reviewer_id
                record.approved_at = utcnow()
                record.remarks = notes

        await self._db.flush()

        await self._audit.log(
            organization_id=organization_id,
            actor_id=reviewer_id,
            action="attendance_exception.reject",
            entity_type="attendance_exception",
            entity_id=exception_id,
            ip_address=ip_address,
        )

        return exc

    async def request_explanation(
        self,
        exception_id: str,
        organization_id: str,
        reviewer_id: str,
        notes: Optional[str] = None,
        ip_address: Optional[str] = None,
    ) -> AttendanceException:
        """Request an explanation from the employee."""
        exc = await self._get_or_raise(exception_id, organization_id)

        exc.status = VerificationStatus.PENDING_EXPLANATION
        exc.reviewed_by_id = reviewer_id
        exc.notes = notes
        await self._db.flush()

        await self._audit.log(
            organization_id=organization_id,
            actor_id=reviewer_id,
            action="attendance_exception.request_explanation",
            entity_type="attendance_exception",
            entity_id=exception_id,
            ip_address=ip_address,
        )

        return exc

    async def _get_or_raise(self, exception_id: str, organization_id: str) -> AttendanceException:
        from app.core.exceptions import NotFoundError
        exc = await self._repo.get_exception_by_id(exception_id, organization_id)
        if not exc:
            raise NotFoundError(message=f"Exception {exception_id} not found.")
        return exc
