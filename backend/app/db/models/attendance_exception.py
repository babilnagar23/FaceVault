from __future__ import annotations
from typing import Optional
import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, ForeignKey, Text, JSON, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class AttendanceException(Base, TimestampMixin):
    """
    Exception review queue — created when attendance needs admin review.
    Statuses: NEEDS_REVIEW, PENDING_EXPLANATION, APPROVED, REJECTED
    """
    __tablename__ = "attendance_exceptions"
    __table_args__ = (
        Index("ix_att_exception_org_status", "organization_id", "status"),
        Index("ix_att_exception_user", "user_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    attendance_attempt_id: Mapped[str] = mapped_column(String(36), ForeignKey("attendance_attempts.id", ondelete="CASCADE"), nullable=False)
    attendance_record_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("attendance_records.id", ondelete="SET NULL"))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=False, index=True)

    # Status: NEEDS_REVIEW, PENDING_EXPLANATION, APPROVED, REJECTED
    status: Mapped[str] = mapped_column(String(30), default="NEEDS_REVIEW", nullable=False, index=True)
    reason: Mapped[Optional[str]] = mapped_column(Text)   # Why it's in review
    notes: Mapped[Optional[str]] = mapped_column(Text)    # Admin notes

    reviewed_by_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("users.id", ondelete="SET NULL"))
    reviewed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    metadata_: Mapped[Optional[dict]] = mapped_column("metadata", JSON)
