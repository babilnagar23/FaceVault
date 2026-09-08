import uuid
from datetime import datetime
from sqlalchemy import String, Boolean, DateTime, ForeignKey, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class Announcement(Base, TimestampMixin):
    __tablename__ = "announcements"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False, index=True)
    created_by_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    category: Mapped[str] = mapped_column(String(50), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    pinned: Mapped[bool] = mapped_column(Boolean, default=False)
    urgent: Mapped[bool] = mapped_column(Boolean, default=False)

    # Status: DRAFT, SCHEDULED, PUBLISHED, ARCHIVED
    status: Mapped[str] = mapped_column(String(20), default="DRAFT", nullable=False, index=True)

    # Targeting: all, department, project, location, selected
    target_type: Mapped[str] = mapped_column(String(20), default="all")
    target_ids: Mapped[list | None] = mapped_column(JSON)  # dept/project/loc IDs

    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), index=True)
    scheduled_for: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    reads: Mapped[list["AnnouncementRead"]] = relationship(back_populates="announcement")
