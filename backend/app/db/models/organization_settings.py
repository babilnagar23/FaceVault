from __future__ import annotations
from typing import Optional
import uuid
from sqlalchemy import String, Integer, Float, Boolean, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class OrganizationSettings(Base, TimestampMixin):
    __tablename__ = "organization_settings"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id", ondelete="CASCADE"), unique=True, nullable=False)

    # ── Geofence / GPS ───────────────────────────────────────────────────────
    default_geofence_radius_meters: Mapped[int] = mapped_column(Integer, default=150, nullable=False)
    gps_accuracy_threshold_meters: Mapped[int] = mapped_column(Integer, default=50, nullable=False)

    # ── Attendance rules ─────────────────────────────────────────────────────
    grace_period_minutes: Mapped[int] = mapped_column(Integer, default=15, nullable=False)
    late_threshold_minutes: Mapped[int] = mapped_column(Integer, default=30, nullable=False)
    checkin_window_hours: Mapped[int] = mapped_column(Integer, default=2, nullable=False)

    # ── Biometric thresholds ─────────────────────────────────────────────────
    face_match_threshold: Mapped[float] = mapped_column(Float, default=0.85, nullable=False)
    liveness_threshold: Mapped[float] = mapped_column(Float, default=0.80, nullable=False)
    minimum_face_quality: Mapped[float] = mapped_column(Float, default=0.70, nullable=False)

    # ── Offline ──────────────────────────────────────────────────────────────
    offline_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    max_offline_days: Mapped[int] = mapped_column(Integer, default=7, nullable=False)

    # ── Retention (days; 0 = keep forever) ──────────────────────────────────
    biometric_retention_days: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    attendance_retention_days: Mapped[int] = mapped_column(Integer, default=730, nullable=False)  # 2 years

    # ── Notifications ────────────────────────────────────────────────────────
    notify_on_late: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    notify_on_absent: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    notify_on_verification: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    notification_config: Mapped[Optional[dict]] = mapped_column(JSON)

    # ── Extra JSON config ────────────────────────────────────────────────────
    extra: Mapped[Optional[dict]] = mapped_column(JSON)

    organization: Mapped["Organization"] = relationship(back_populates="settings")
