import uuid
from sqlalchemy import String, Boolean, Float, ForeignKey, Text, JSON, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class HelpCategory(Base, TimestampMixin):
    __tablename__ = "help_categories"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    requests: Mapped[list["HelpRequest"]] = relationship(back_populates="category")


class HelpRequest(Base, TimestampMixin):
    __tablename__ = "help_requests"
    __table_args__ = (
        Index("ix_help_request_org_status", "organization_id", "status"),
        Index("ix_help_request_user", "user_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=False, index=True)
    category_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("help_categories.id", ondelete="SET NULL"))
    assigned_to_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id", ondelete="SET NULL"))

    subject: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)

    # Status: OPEN, IN_PROGRESS, PENDING_USER, RESOLVED, CLOSED
    status: Mapped[str] = mapped_column(String(20), default="OPEN", nullable=False, index=True)
    priority: Mapped[str] = mapped_column(String(20), default="NORMAL", nullable=False)

    # Linked attendance attempt (optional context)
    attendance_attempt_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("attendance_attempts.id", ondelete="SET NULL"))

    # Device context at time of ticket
    device_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("devices.id", ondelete="SET NULL"))
    app_version: Mapped[str | None] = mapped_column(String(30))

    # User location at time of submission
    latitude: Mapped[float | None] = mapped_column(Float)
    longitude: Mapped[float | None] = mapped_column(Float)

    resolution: Mapped[str | None] = mapped_column(Text)

    category: Mapped["HelpCategory"] = relationship(back_populates="requests")
    comments: Mapped[list["HelpComment"]] = relationship(back_populates="request", cascade="all, delete-orphan")
    attachments: Mapped[list["HelpAttachment"]] = relationship(back_populates="request", cascade="all, delete-orphan")
