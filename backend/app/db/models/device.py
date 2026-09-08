import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, ForeignKey, Text, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class Device(Base, TimestampMixin):
    __tablename__ = "devices"
    __table_args__ = (
        Index("ix_devices_uuid", "device_uuid"),
        Index("ix_devices_user", "user_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False)

    device_uuid: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    platform: Mapped[str] = mapped_column(String(20), nullable=False)        # android, ios
    manufacturer: Mapped[str | None] = mapped_column(String(100))
    model: Mapped[str | None] = mapped_column(String(100))
    os_version: Mapped[str | None] = mapped_column(String(50))
    app_version: Mapped[str | None] = mapped_column(String(20))
    status: Mapped[str] = mapped_column(String(20), default="REGISTERED", nullable=False, index=True)

    # For future cryptographic offline-event signing
    public_key: Mapped[str | None] = mapped_column(Text)

    registered_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_sync_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped["User"] = relationship(back_populates="devices")
