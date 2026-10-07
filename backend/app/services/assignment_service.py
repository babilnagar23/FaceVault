"""
AssignmentService — business logic for employee assignments.
"""
from __future__ import annotations
from datetime import date

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.db.models.assignment import Assignment
from app.repositories.assignment_repository import AssignmentRepository


class AssignmentService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._repo = AssignmentRepository(db)

    async def get_effective_assignment(
        self,
        user_id: str,
        organization_id: str,
        attendance_date: date,
    ) -> Assignment:
        """
        Return the effective assignment for a user on a given local attendance date.

        Selection rules:
          - organization_id must match (tenant safety)
          - is_active = True
          - effective_from <= attendance_date
          - effective_to IS NULL OR attendance_date <= effective_to

        Raises NotFoundError if no effective assignment is found.
        The attendance_date must already be in the organization's local timezone.
        """
        assignment = await self._repo.get_effective(user_id, organization_id, attendance_date)
        if not assignment:
            raise NotFoundError(
                message=(
                    f"No active assignment found for user {user_id} "
                    f"on {attendance_date} in org {organization_id}."
                )
            )
        return assignment
