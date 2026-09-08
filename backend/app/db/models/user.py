import uuid
from datetime import datetime
from sqlalchemy import String, Boolean, DateTime, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class User(Base, TimestampMixin):
    __tablename__ = "users"
    __table_args__ = (
        Index("ix_users_org_employee_code", "organization_id", "employee_code"),
        Index("ix_users_org_email", "organization_id", "email"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False, index=True)
    role_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("roles.id"))
    department_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("departments.id"))

    employee_code: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    last_name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    phone: Mapped[str | None] = mapped_column(String(30))
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)

    status: Mapped[str] = mapped_column(String(20), default="ACTIVE", nullable=False, index=True)
    face_enrolled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    device_registered: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    avatar_url: Mapped[str | None] = mapped_column(String(500))
    manager_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))
    join_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Relationships
    organization: Mapped["Organization"] = relationship(back_populates="users")
    role: Mapped["Role"] = relationship(back_populates="users")
    department: Mapped["Department"] = relationship(back_populates="users")
    devices: Mapped[list["Device"]] = relationship(back_populates="user")
    sessions: Mapped[list["UserSession"]] = relationship(back_populates="user")
    face_enrollment: Mapped["FaceEnrollment"] = relationship(back_populates="user", uselist=False)
    assignments: Mapped[list["Assignment"]] = relationship(back_populates="user")
    attendance_attempts: Mapped[list["AttendanceAttempt"]] = relationship(back_populates="user")
    attendance_records: Mapped[list["AttendanceRecord"]] = relationship(back_populates="user")

    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"
