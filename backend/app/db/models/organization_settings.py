import uuid
from sqlalchemy import String, Integer, Float, Boolean, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class OrganizationSettings(Base, TimestampMixin):
    __tablename__ = "organization_settings"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), unique=True, nullable=False)

    # Attendance rules
    default_geofence_radius_meters: Mapped[int] = mapped_column(Integer, default=150)
    grace_period_minutes: Mapped[int] = mapped_column(Integer, default=15)
    late_threshold_minutes: Mapped[int] = mapped_column(Integer, default=30)
    checkin_window_hours: Mapped[int] = mapped_column(Integer, default=2)

    # Biometric thresholds
    face_match_threshold: Mapped[float] = mapped_column(Float, default=0.85)
    liveness_threshold: Mapped[float] = mapped_column(Float, default=0.80)
    minimum_face_quality: Mapped[float] = mapped_column(Float, default=0.70)

    # Offline
    offline_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    max_offline_days: Mapped[int] = mapped_column(Integer, default=7)

    # Notifications
    notify_on_late: Mapped[bool] = mapped_column(Boolean, default=True)
    notify_on_absent: Mapped[bool] = mapped_column(Boolean, default=True)
    notify_on_verification: Mapped[bool] = mapped_column(Boolean, default=True)

    # Extra JSON config
    extra: Mapped[dict | None] = mapped_column(JSON)

    organization: Mapped["Organization"] = relationship(back_populates="settings")
