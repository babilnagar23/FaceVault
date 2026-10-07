from __future__ import annotations
from typing import Optional
import uuid
from sqlalchemy import String, ForeignKey, JSON, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, TimestampMixin


class SyncConflict(Base, TimestampMixin):
    __tablename__ = "sync_conflicts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    sync_event_id: Mapped[str] = mapped_column(String(36), ForeignKey("sync_events.id"), nullable=False)
    client_event_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False)

    reason: Mapped[str] = mapped_column(Text, nullable=False)
    server_record_id: Mapped[Optional[str]] = mapped_column(String(36))
    server_state: Mapped[Optional[dict]] = mapped_column(JSON)
    resolution: Mapped[Optional[str]] = mapped_column(String(30))  # SERVER_WINS, CLIENT_WINS, MANUAL
