from __future__ import annotations
from typing import Optional
"""
Session Repository — database queries for UserSession.
Tokens are stored as hashes — never raw.
"""

import uuid
from datetime import datetime

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.session import UserSession
from app.utils.hashing import generate_token, hash_token, verify_token_hash
from app.utils.time import utcnow


class SessionRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def get_by_id(self, session_id: str) -> Optional[UserSession]:
        result = await self._db.execute(
            select(UserSession).where(UserSession.id == session_id)
        )
        return result.scalar_one_or_none()

    async def get_active_by_id(self, session_id: str) -> Optional[UserSession]:
        """Load a session that is not revoked and not expired."""
        result = await self._db.execute(
            select(UserSession).where(
                UserSession.id == session_id,
                UserSession.is_revoked == False,
                UserSession.expires_at > utcnow(),
            )
        )
        return result.scalar_one_or_none()

    def create(
        self,
        user_id: str,
        raw_refresh_token: str,
        expires_at: datetime,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        device_id: Optional[str] = None,
    ) -> tuple[UserSession, str]:
        """
        Create a new UserSession with an explicitly generated UUID.
        The UUID is generated here so it can be embedded in the JWT before the DB commit.

        Returns:
            (session, session_id): The unsaved session ORM object and its ID.
            Caller must db.add(session) and db.flush() before creating JWT.
        """
        session_id = str(uuid.uuid4())
        session = UserSession(
            id=session_id,
            user_id=user_id,
            refresh_token_hash=hash_token(raw_refresh_token),
            expires_at=expires_at,
            ip_address=ip_address,
            user_agent=user_agent,
            device_id=device_id,
        )
        return session, session_id

    async def rotate_token(
        self,
        session: UserSession,
        new_raw_token: str,
    ) -> str:
        """Replace the stored hash with a new token hash. Returns the new raw token."""
        session.refresh_token_hash = hash_token(new_raw_token)
        session.last_used_at = utcnow()
        return new_raw_token

    def verify_token(self, raw_token: str, session: UserSession) -> bool:
        """Return True if raw_token matches the stored hash."""
        return verify_token_hash(raw_token, session.refresh_token_hash)

    async def revoke(self, session: UserSession) -> None:
        """Revoke a single session."""
        session.is_revoked = True

    async def revoke_by_id(self, session_id: str) -> None:
        """Revoke a session by ID without loading it."""
        await self._db.execute(
            update(UserSession)
            .where(UserSession.id == session_id)
            .values(is_revoked=True)
        )

    async def revoke_all_for_user(self, user_id: str) -> None:
        """Revoke all active sessions for a user (logout-all)."""
        await self._db.execute(
            update(UserSession)
            .where(UserSession.user_id == user_id, UserSession.is_revoked == False)
            .values(is_revoked=True)
        )
