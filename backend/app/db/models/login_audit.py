from __future__ import annotations
from typing import Optional
import uuid
from sqlalchemy import String, Boolean, ForeignKey, Text, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, TimestampMixin


class LoginAudit(Base, TimestampMixin):
    """
    Immutable log of every authentication attempt.
    NEVER log raw passwords or tokens.
    """
    __tablename__ = "login_audit"
    __table_args__ = (
        Index("ix_login_audit_org_created", "organization_id", "created_at"),
        Index("ix_login_audit_user", "user_id"),
        Index("ix_login_audit_success", "success"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("organizations.id", ondelete="SET NULL"), index=True)
    user_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("users.id", ondelete="SET NULL"))

    # The identifier used during login (employee_code or email) — never a password
    identifier: Mapped[str] = mapped_column(String(255), nullable=False)
    success: Mapped[bool] = mapped_column(Boolean, nullable=False)
    failure_reason: Mapped[Optional[str]] = mapped_column(String(100))

    ip_address: Mapped[Optional[str]] = mapped_column(String(45))
    user_agent: Mapped[Optional[str]] = mapped_column(Text)
