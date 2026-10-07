from __future__ import annotations
from typing import Optional
"""
Assignment Repository — queries for effective assignments.
Always scoped by organization_id.
"""

from datetime import date

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.db.models.assignment import Assignment


class AssignmentRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def get_effective(
        self,
        user_id: str,
        organization_id: str,
        attendance_date: date,
    ) -> Optional[Assignment]:
        """
        Load the effective active assignment for a user on a given local attendance date.

        Selection criteria:
          - belongs to the correct organization (tenant safety)
          - belongs to the user
          - is_active = True
          - effective_from <= attendance_date
          - effective_to IS NULL OR attendance_date <= effective_to

        If multiple assignments match (should not happen with the EXCLUDE constraint),
        the one with the latest effective_from is preferred.
        """
        result = await self._db.execute(
            select(Assignment)
            .options(
                joinedload(Assignment.project),
                joinedload(Assignment.location),
                joinedload(Assignment.shift),
            )
            .where(
                Assignment.organization_id == organization_id,
                Assignment.user_id == user_id,
                Assignment.is_active == True,
                Assignment.effective_from <= attendance_date,
                (Assignment.effective_to == None) | (Assignment.effective_to >= attendance_date),
            )
            .order_by(Assignment.effective_from.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    async def get_by_id_in_org(
        self,
        assignment_id: str,
        organization_id: str,
    ) -> Optional[Assignment]:
        result = await self._db.execute(
            select(Assignment).where(
                Assignment.id == assignment_id,
                Assignment.organization_id == organization_id,
            )
        )
        return result.scalar_one_or_none()
