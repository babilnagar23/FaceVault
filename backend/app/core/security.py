"""
FaceVault API — JWT Security Utilities
"""
from datetime import UTC, datetime, timedelta
from typing import Any

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import settings
from app.core.exceptions import InvalidTokenError, TokenExpiredError

# ─── Password Hashing (Argon2id) ─────────────────────────────────────────────
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")


def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


# ─── JWT Tokens ───────────────────────────────────────────────────────────────
def _create_token(
    data: dict[str, Any],
    secret: str,
    expire_delta: timedelta,
) -> str:
    payload = data.copy()
    payload["exp"] = datetime.now(UTC) + expire_delta
    payload["iat"] = datetime.now(UTC)
    return jwt.encode(payload, secret, algorithm=settings.JWT_ALGORITHM)


def create_access_token(
    subject: str,
    organization_id: str,
    role: str,
    extra: dict[str, Any] | None = None,
) -> str:
    data: dict[str, Any] = {
        "sub": subject,
        "org": organization_id,
        "role": role,
        "type": "access",
    }
    if extra:
        data.update(extra)
    return _create_token(
        data,
        settings.JWT_SECRET_KEY,
        timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )


def create_refresh_token(subject: str, session_id: str) -> str:
    return _create_token(
        {"sub": subject, "sid": session_id, "type": "refresh"},
        settings.JWT_REFRESH_SECRET_KEY,
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )


def decode_access_token(token: str) -> dict[str, Any]:
    try:
        payload = jwt.decode(
            token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
        )
        if payload.get("type") != "access":
            raise InvalidTokenError()
        return payload
    except JWTError as exc:
        # Distinguish expired from malformed
        if "expired" in str(exc).lower():
            raise TokenExpiredError() from exc
        raise InvalidTokenError() from exc


def decode_refresh_token(token: str) -> dict[str, Any]:
    try:
        payload = jwt.decode(
            token, settings.JWT_REFRESH_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
        )
        if payload.get("type") != "refresh":
            raise InvalidTokenError()
        return payload
    except JWTError as exc:
        if "expired" in str(exc).lower():
            raise TokenExpiredError() from exc
        raise InvalidTokenError() from exc
