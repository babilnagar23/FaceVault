import uuid
from datetime import date
from sqlalchemy import String, Boolean, Date, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class Assignment(Base, TimestampMixin):
    """Links an employee to a project, location, and shift for a date range."""
    __tablename__ = "assignments"
    __table_args__ = (
        Index("ix_assignments_user_active", "user_id", "is_active"),
        Index("ix_assignments_location", "location_id"),
        Index("ix_assignments_dates", "effective_from", "effective_to"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    project_id: Mapped[str] = mapped_column(String(36), ForeignKey("projects.id"), nullable=False)
    location_id: Mapped[str] = mapped_column(String(36), ForeignKey("locations.id"), nullable=False)
    shift_id: Mapped[str] = mapped_column(String(36), ForeignKey("shifts.id"), nullable=False)

    effective_from: Mapped[date] = mapped_column(Date, nullable=False)
    effective_to: Mapped[date | None] = mapped_column(Date)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    user: Mapped["User"] = relationship(back_populates="assignments")
    project: Mapped["Project"] = relationship(back_populates="assignments")
    location: Mapped["Location"] = relationship(back_populates="assignments")
    shift: Mapped["Shift"] = relationship(back_populates="assignments")
    attendance_attempts: Mapped[list["AttendanceAttempt"]] = relationship(back_populates="assignment")
    attendance_records: Mapped[list["AttendanceRecord"]] = relationship(back_populates="assignment")
