import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, ForeignKey, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, TimestampMixin


class AttendanceException(Base, TimestampMixin):
    """Verification queue entry — created when attendance needs admin review."""
    __tablename__ = "attendance_exceptions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False, index=True)
    attendance_attempt_id: Mapped[str] = mapped_column(String(36), ForeignKey("attendance_attempts.id"), nullable=False)
    attendance_record_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("attendance_records.id"))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)

    # Status: NEEDS_REVIEW, APPROVED, REJECTED, PENDING_EXPLANATION
    status: Mapped[str] = mapped_column(String(30), default="NEEDS_REVIEW", nullable=False, index=True)
    reason: Mapped[str | None] = mapped_column(Text)  # Why it's in review
    notes: Mapped[str | None] = mapped_column(Text)   # Admin notes

    reviewed_by_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    metadata_: Mapped[dict | None] = mapped_column("metadata", JSON)
