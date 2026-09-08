import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, ForeignKey, JSON, Text, UniqueConstraint, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, TimestampMixin


class SyncEvent(Base, TimestampMixin):
    """
    Represents a single offline-created event received from the mobile app.
    UNIQUE(client_event_id) provides idempotency — duplicate pushes are safe.
    """
    __tablename__ = "sync_events"
    __table_args__ = (
        UniqueConstraint("client_event_id", name="uq_sync_event_id"),
        Index("ix_sync_event_device_status", "device_id", "status"),
        Index("ix_sync_event_org_status", "organization_id", "status"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    client_event_id: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    device_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("devices.id"))

    entity_type: Mapped[str] = mapped_column(String(50), nullable=False)  # attendance_attempt, help_request, etc.
    operation: Mapped[str] = mapped_column(String(20), nullable=False)     # create, update, delete

    client_created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    server_received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    server_processed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # outcome: ACCEPTED, REJECTED, CONFLICT, ALREADY_PROCESSED
    status: Mapped[str] = mapped_column(String(30), default="PENDING", nullable=False, index=True)
    rejection_reason: Mapped[str | None] = mapped_column(Text)

    payload: Mapped[dict | None] = mapped_column(JSON)
    result_entity_id: Mapped[str | None] = mapped_column(String(36))  # Created entity if accepted
