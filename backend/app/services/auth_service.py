from __future__ import annotations
from typing import Optional
"""
AuthService — all authentication business logic.

Responsibilities:
  - employee login (mobile)
  - admin login (dashboard)
  - session creation with explicit UUID (for JWT sid claim)
  - token refresh with rotation
  - logout (single session)
  - logout-all (all sessions)
  - login audit recording
  - user validation

The JWT 'role' claim is for client UX only — authorization is always DB-driven.
"""

from datetime import timedelta

from fastapi import Request
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.exceptions import AuthenticationError, InvalidTokenError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
    verify_password,
)
from app.db.models.login_audit import LoginAudit
from app.db.models.organization import Organization
from app.db.models.organization_settings import OrganizationSettings
from app.repositories.session_repository import SessionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth import LoginResponse, TokenResponse, UserInToken
from app.utils.hashing import generate_token
from app.utils.time import offline_session_expires_at, utcnow


class AuthService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._users = UserRepository(db)
        self._sessions = SessionRepository(db)

    # ── Employee Login ────────────────────────────────────────────────────────

    async def employee_login(
        self,
        employee_code: str,
        password: str,
        request: Request,
    ) -> LoginResponse:
        """
        Mobile login: employee_code (globally unique) + password.
        No organization code required — employee_code is unambiguous.
        """
        identifier = employee_code.strip().upper()
        user = await self._users.get_by_employee_code(identifier)

        if not user or not verify_password(password, user.password_hash):
            await self._write_audit(
                identifier=identifier,
                success=False,
                failure_reason="INVALID_CREDENTIALS",
                request=request,
            )
            # Generic message — do not reveal whether identifier or password was wrong
            raise AuthenticationError(message="Invalid Employee ID or password.")

        await self._write_audit(
            identifier=identifier,
            success=True,
            user_id=user.id,
            organization_id=user.organization_id,
            request=request,
        )
        return await self._build_login_response(user, request)

    # ── Admin Login ───────────────────────────────────────────────────────────

    async def admin_login(
        self,
        organisation_code: str,
        email: str,
        password: str,
        request: Request,
    ) -> LoginResponse:
        """Admin login: org_code (uppercase) + email (lowercase) + password."""
        norm_code = organisation_code.strip().upper()
        norm_email = email.strip().lower()

        org_result = await self._db.execute(
            select(Organization).where(
                Organization.code == norm_code,
                Organization.active == True,
            )
        )
        org = org_result.scalar_one_or_none()
        if not org:
            await self._write_audit(
                identifier=norm_email,
                success=False,
                failure_reason="ORG_NOT_FOUND",
                request=request,
            )
            raise AuthenticationError(message="Invalid credentials.")

        user = await self._users.get_by_email_in_org(norm_email, org.id)

        if not user or not verify_password(password, user.password_hash):
            await self._write_audit(
                identifier=norm_email,
                success=False,
                failure_reason="INVALID_CREDENTIALS",
                organization_id=org.id,
                request=request,
            )
            raise AuthenticationError(message="Invalid credentials.")

        await self._write_audit(
            identifier=norm_email,
            success=True,
            user_id=user.id,
            organization_id=org.id,
            request=request,
        )
        return await self._build_login_response(user, request)

    # ── Refresh ───────────────────────────────────────────────────────────────

    async def refresh(self, raw_refresh_token: str) -> TokenResponse:
        """
        Rotate refresh token and issue new access + refresh tokens.

        Flow:
          1. Decode and validate refresh JWT
          2. Load session by sid (NOT by user_id)
          3. Verify session belongs to the JWT subject
          4. Verify session is not revoked / expired
          5. Verify raw token against stored hash
          6. On hash mismatch → revoke session (reuse signal)
          7. Rotate hash → generate new tokens
          8. Return new token pair
        """
        try:
            payload = decode_refresh_token(raw_refresh_token)
        except Exception:
            raise InvalidTokenError(message="Invalid refresh token.")

        sid = payload.get("sid")
        sub = payload.get("sub")
        if not sid or not sub:
            raise InvalidTokenError(message="Malformed refresh token.")

        session = await self._sessions.get_active_by_id(sid)
        if not session:
            raise InvalidTokenError(message="Session not found or expired.")

        # Verify the session belongs to the token subject
        if session.user_id != sub:
            raise InvalidTokenError(message="Token/session mismatch.")

        # Verify the raw token against the stored hash
        if not self._sessions.verify_token(raw_refresh_token, session):
            # Hash mismatch — potential token reuse. Revoke the session.
            await self._sessions.revoke(session)
            await self._db.commit()
            raise InvalidTokenError(message="Refresh token already used. Session revoked.")

        user = await self._users.get_active_by_id(sub)
        if not user:
            raise InvalidTokenError(message="User not found or inactive.")

        # Rotate: generate new raw refresh token and update hash
        new_raw_refresh = generate_token()
        await self._sessions.rotate_token(session, new_raw_refresh)

        role_name = user.role.name if user.role else "EMPLOYEE"
        new_access = create_access_token(
            subject=user.id,
            organization_id=user.organization_id,
            role=role_name,
            session_id=session.id,
        )
        new_refresh = create_refresh_token(subject=user.id, session_id=session.id)

        await self._db.commit()

        return TokenResponse(
            access_token=new_access,
            refresh_token=new_refresh,
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )

    # ── Logout ────────────────────────────────────────────────────────────────

    async def logout(self, session_id: str) -> None:
        """Revoke only the current session (identified by sid from access token)."""
        await self._sessions.revoke_by_id(session_id)
        await self._db.commit()

    async def logout_all(self, user_id: str) -> None:
        """Revoke all sessions for the user (logout of all devices)."""
        await self._sessions.revoke_all_for_user(user_id)
        await self._db.commit()

    # ── Internal helpers ──────────────────────────────────────────────────────

    async def _build_login_response(self, user, request: Request) -> LoginResponse:
        """Create session, tokens, and return LoginResponse."""
        # Load org settings for offline trust metadata
        settings_result = await self._db.execute(
            select(OrganizationSettings).where(
                OrganizationSettings.organization_id == user.organization_id
            )
        )
        org_settings = settings_result.scalar_one_or_none()
        max_offline_days = org_settings.max_offline_days if org_settings else settings.MAX_OFFLINE_DAYS
        offline_enabled = org_settings.offline_enabled if org_settings else True

        raw_refresh = generate_token()
        expires_at = utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

        # Create session with explicit UUID so sid can be embedded in JWT
        session, session_id = self._sessions.create(
            user_id=user.id,
            raw_refresh_token=raw_refresh,
            expires_at=expires_at,
            ip_address=request.client.host if request.client else None,
            user_agent=request.headers.get("user-agent"),
        )
        self._db.add(session)
        # Flush so the session row exists before we reference session_id in JWT
        await self._db.flush()

        role_name = user.role.name if user.role else "EMPLOYEE"
        access = create_access_token(
            subject=user.id,
            organization_id=user.organization_id,
            role=role_name,
            session_id=session_id,
        )
        refresh = create_refresh_token(subject=user.id, session_id=session_id)

        # Update last login
        user.last_login_at = utcnow()
        await self._db.commit()

        server_time = utcnow()
        offline_exp = offline_session_expires_at(server_time, max_offline_days) if offline_enabled else None

        first_device_login = not user.device_registered
        return LoginResponse(
            tokens=TokenResponse(
                access_token=access,
                refresh_token=refresh,
                expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            ),
            user=UserInToken(
                id=user.id,
                employee_code=user.employee_code,
                full_name=user.full_name,
                email=user.email,
                role=role_name,
                organization_id=user.organization_id,
                face_enrolled=user.face_enrolled,
                device_registered=user.device_registered,
                first_device_login=first_device_login,
            ),
            server_time=server_time,
            offline_session_expires_at=offline_exp,
        )

    async def _write_audit(
        self,
        identifier: str,
        success: bool,
        failure_reason: Optional[str] = None,
        user_id: Optional[str] = None,
        organization_id: Optional[str] = None,
        request: Optional[Request] = None,
    ) -> None:
        """Write a LoginAudit record. Never logs passwords or tokens."""
        audit = LoginAudit(
            organization_id=organization_id,
            user_id=user_id,
            identifier=identifier,
            success=success,
            failure_reason=failure_reason,
            ip_address=request.client.host if request and request.client else None,
            user_agent=request.headers.get("user-agent") if request else None,
        )
        self._db.add(audit)
        # Flush immediately so audit is preserved even if caller rolls back
        await self._db.flush()
