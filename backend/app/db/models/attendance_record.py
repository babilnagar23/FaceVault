import uuid
from datetime import date, datetime
from sqlalchemy import String, Float, Date, DateTime, ForeignKey, Text, UniqueConstraint, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class AttendanceRecord(Base, TimestampMixin):
    """
    Official, authoritative attendance record per employee per shift per date.
    This is what the admin dashboard shows. Attempt failures do NOT appear here.
    """
    __tablename__ = "attendance_records"
    __table_args__ = (
        UniqueConstraint("user_id", "attendance_date", "shift_id", name="uq_attendance_record_daily"),
        Index("ix_att_record_user_date", "user_id", "attendance_date"),
        Index("ix_att_record_status", "status"),
        Index("ix_att_record_org_date", "organization_id", "attendance_date"),
        Index("ix_att_record_location", "location_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    assignment_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("assignments.id"))
    project_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("projects.id"))
    location_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("locations.id"))
    shift_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("shifts.id"))

    attendance_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)

    # Linked attempts
    check_in_attempt_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("attendance_attempts.id"))
    check_out_attempt_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("attendance_attempts.id"))

    check_in_time: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    check_out_time: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Official status: PRESENT, ABSENT, LATE, LEAVE, PENDING_REVIEW, APPROVED_EXCEPTION, REJECTED
    status: Mapped[str] = mapped_column(String(30), nullable=False, index=True)

    source: Mapped[str] = mapped_column(String(20), default="MOBILE")  # MOBILE, ADMIN, SYSTEM
    work_duration_minutes: Mapped[float | None] = mapped_column(Float)

    # Scores from the verified check-in attempt
    face_score: Mapped[float | None] = mapped_column(Float)
    liveness_score: Mapped[float | None] = mapped_column(Float)
    location_distance_meters: Mapped[float | None] = mapped_column(Float)

    # Admin review
    approved_by_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    remarks: Mapped[str | None] = mapped_column(Text)

    # Relationships
    user: Mapped["User"] = relationship(back_populates="attendance_records", foreign_keys=[user_id])
    assignment: Mapped["Assignment"] = relationship(back_populates="attendance_records")
