"""
FaceVault API — FastAPI Dependencies
All authentication, authorization, and DB session dependencies live here.
"""
from typing import Annotated

from fastapi import Depends, Header, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import (
    DeviceRevokedError,
    InvalidTokenError,
    OrganizationMismatchError,
    PermissionDeniedError,
)
from app.core.permissions import Permission
from app.core.security import decode_access_token
from app.db.session import get_db

bearer_scheme = HTTPBearer(auto_error=False)

DbSession = Annotated[AsyncSession, Depends(get_db)]


# ─── Current User ─────────────────────────────────────────────────────────────

async def get_current_user_payload(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
) -> dict:
    """Decode the JWT and return the raw payload dict."""
    if not credentials:
        raise InvalidTokenError(message="Authorization header missing.")
    return decode_access_token(credentials.credentials)


CurrentUserPayload = Annotated[dict, Depends(get_current_user_payload)]


async def get_current_user(
    db: DbSession,
    payload: CurrentUserPayload,
) -> "User":  # type: ignore[name-defined]
    """Load the User ORM object from the token subject."""
    from app.db.models.user import User
    from sqlalchemy import select

    user_id: str = payload.get("sub", "")
    result = await db.execute(select(User).where(User.id == user_id, User.status == "ACTIVE"))
    user = result.scalar_one_or_none()
    if user is None:
        raise InvalidTokenError(message="User not found or inactive.")
    return user


CurrentUser = Annotated["User", Depends(get_current_user)]  # type: ignore[name-defined]


# ─── Organization scope guard ─────────────────────────────────────────────────

def require_same_org(user: "User", resource_org_id: str) -> None:  # type: ignore[name-defined]
    """Raise 403 if user's org does not match the resource's org."""
    if user.organization_id != resource_org_id:
        raise OrganizationMismatchError()


# ─── RBAC ─────────────────────────────────────────────────────────────────────

def require_permission(required: Permission):
    """Returns a FastAPI dependency that checks a specific permission."""

    async def _check(
        db: DbSession,
        payload: CurrentUserPayload,
        user: CurrentUser,
    ) -> "User":  # type: ignore[name-defined]
        role_name = payload.get("role", "")

        # Load role permissions from DB (or use defaults)
        from app.core.permissions import ROLE_DEFAULT_PERMISSIONS, Role
        try:
            role = Role(role_name)
        except ValueError:
            raise PermissionDeniedError()

        allowed = ROLE_DEFAULT_PERMISSIONS.get(role, set())
        if required not in allowed:
            raise PermissionDeniedError(
                message=f"Permission '{required}' is required.",
                details={"required": required, "role": role_name},
            )
        return user

    return Depends(_check)


def require_admin_role():
    """Require at least ADMIN or OWNER role."""
    async def _check(payload: CurrentUserPayload) -> dict:
        role = payload.get("role", "")
        if role not in ("ADMIN", "OWNER", "HR", "MANAGER", "SUPERVISOR"):
            raise PermissionDeniedError(message="Admin access required.")
        return payload

    return Depends(_check)
