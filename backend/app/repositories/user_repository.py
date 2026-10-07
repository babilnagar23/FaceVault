from __future__ import annotations
from typing import Optional
"""
User Repository — database queries related to users.
All tenant-sensitive queries include organization_id scope.
"""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.user import User


class UserRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def get_by_id(self, user_id: str) -> Optional[User]:
        result = await self._db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_active_by_id(self, user_id: str) -> Optional[User]:
        result = await self._db.execute(
            select(User).where(User.id == user_id, User.status == "ACTIVE")
        )
        return result.scalar_one_or_none()

    async def get_by_employee_code(self, employee_code: str) -> Optional[User]:
        """Look up by globally unique employee_code (mobile login — no org needed)."""
        result = await self._db.execute(
            select(User).where(
                User.employee_code == employee_code.strip().upper(),
                User.status == "ACTIVE",
            )
        )
        return result.scalar_one_or_none()

    async def get_by_email_in_org(self, email: str, organization_id: str) -> Optional[User]:
        """Look up admin user by email within their organization."""
        result = await self._db.execute(
            select(User).where(
                User.organization_id == organization_id,
                User.email == email.strip().lower(),
                User.status == "ACTIVE",
            )
        )
        return result.scalar_one_or_none()

    async def get_active_in_org(self, user_id: str, organization_id: str) -> Optional[User]:
        """Load a user scoped to an organization — prevents cross-org access."""
        result = await self._db.execute(
            select(User).where(
                User.id == user_id,
                User.organization_id == organization_id,
                User.status == "ACTIVE",
            )
        )
        return result.scalar_one_or_none()
