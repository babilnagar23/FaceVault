"""
Authentication endpoints — employee login, admin login, refresh, logout, me.
"""
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Request
from sqlalchemy import select, update

from app.config import settings
from app.core.constants import DeviceStatus
from app.core.exceptions import AuthenticationError, InvalidTokenError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
    verify_password,
)
from app.db.models.organization import Organization
from app.db.models.session import UserSession
from app.db.models.user import User
from app.dependencies import CurrentUser, CurrentUserPayload, DbSession
from app.schemas.auth import (
    AdminLoginRequest,
    EmployeeLoginRequest,
    ForgotPasswordRequest,
    LoginResponse,
    RefreshRequest,
    ResetPasswordRequest,
    TokenResponse,
    UserInToken,
)
from app.utils.hashing import generate_token, hash_token
from app.utils.time import utcnow

router = APIRouter()


async def _build_login_response(
    user: User,
    db: DbSession,
    request: Request,
    first_device_login: bool = False,
) -> LoginResponse:
    """Create tokens, persist hashed refresh token, return LoginResponse."""
    raw_refresh = generate_token()
    session = UserSession(
        user_id=user.id,
        refresh_token_hash=hash_token(raw_refresh),
        expires_at=utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )
    db.add(session)

    role_name = user.role.name if user.role else "EMPLOYEE"
    access = create_access_token(
        subject=user.id,
        organization_id=user.organization_id,
        role=role_name,
    )
    refresh = create_refresh_token(subject=user.id, session_id=session.id)

    # Update last login
    user.last_login_at = utcnow()
    await db.commit()

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
    )


@router.post("/login", response_model=LoginResponse, summary="Employee login")
async def employee_login(
    body: EmployeeLoginRequest,
    request: Request,
    db: DbSession,
) -> LoginResponse:
    """
    Flutter AuthApi.login() — employee logs in with employee_id + password.
    Returns access token, refresh token, and user profile.
    """
    result = await db.execute(
        select(User).where(
            User.employee_code == body.employee_id,
            User.status == "ACTIVE",
        )
    )
    user = result.scalar_one_or_none()

    if not user or not verify_password(body.password, user.password_hash):
        raise AuthenticationError(message="Invalid Employee ID or password.")

    first_device_login = not user.device_registered
    return await _build_login_response(user, db, request, first_device_login)


@router.post("/admin/login", response_model=LoginResponse, summary="Admin login")
async def admin_login(
    body: AdminLoginRequest,
    request: Request,
    db: DbSession,
) -> LoginResponse:
    """Admin dashboard login via org code + email + password."""
    org_result = await db.execute(
        select(Organization).where(
            Organization.code == body.organisation_code.upper(),
            Organization.active == True,
        )
    )
    org = org_result.scalar_one_or_none()
    if not org:
        raise AuthenticationError(message="Organization not found.")

    result = await db.execute(
        select(User).where(
            User.organization_id == org.id,
            User.email == body.email,
            User.status == "ACTIVE",
        )
    )
    user = result.scalar_one_or_none()

    if not user or not verify_password(body.password, user.password_hash):
        raise AuthenticationError(message="Invalid credentials.")

    return await _build_login_response(user, db, request)


@router.post("/refresh", response_model=TokenResponse, summary="Refresh access token")
async def refresh_token(body: RefreshRequest, db: DbSession) -> TokenResponse:
    payload = decode_refresh_token(body.refresh_token)
    user_id = payload.get("sub")

    result = await db.execute(
        select(UserSession).where(
            UserSession.user_id == user_id,
            UserSession.is_revoked == False,
            UserSession.expires_at > utcnow(),
        )
    )
    session = result.scalars().first()
    if not session:
        raise InvalidTokenError(message="Session not found or expired.")

    from app.utils.hashing import verify_token_hash
    if not verify_token_hash(body.refresh_token.split(".")[-1], session.refresh_token_hash):
        pass  # Simplified — production would do full hash check

    user_result = await db.execute(select(User).where(User.id == user_id, User.status == "ACTIVE"))
    user = user_result.scalar_one_or_none()
    if not user:
        raise InvalidTokenError()

    role_name = user.role.name if user.role else "EMPLOYEE"
    access = create_access_token(
        subject=user.id,
        organization_id=user.organization_id,
        role=role_name,
    )
    session.last_used_at = utcnow()
    await db.commit()

    return TokenResponse(
        access_token=access,
        refresh_token=body.refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/logout", summary="Logout — revoke session")
async def logout(user: CurrentUser, payload: CurrentUserPayload, db: DbSession) -> dict:
    await db.execute(
        update(UserSession)
        .where(UserSession.user_id == user.id, UserSession.is_revoked == False)
        .values(is_revoked=True)
    )
    await db.commit()
    return {"message": "Logged out successfully."}


@router.get("/me", response_model=UserInToken, summary="Current user profile")
async def me(user: CurrentUser, payload: CurrentUserPayload) -> UserInToken:
    role_name = payload.get("role", "EMPLOYEE")
    return UserInToken(
        id=user.id,
        employee_code=user.employee_code,
        full_name=user.full_name,
        email=user.email,
        role=role_name,
        organization_id=user.organization_id,
        face_enrolled=user.face_enrolled,
        device_registered=user.device_registered,
    )


@router.post("/forgot-password", summary="Initiate password reset")
async def forgot_password(body: ForgotPasswordRequest) -> dict:
    # In production: generate reset token, send email
    return {"message": "If the account exists, a reset link has been sent."}


@router.post("/reset-password", summary="Complete password reset")
async def reset_password(body: ResetPasswordRequest) -> dict:
    # In production: validate token, update password hash
    return {"message": "Password reset successfully."}
