import uuid
from sqlalchemy import String, Boolean, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class HelpCategory(Base):
    __tablename__ = "help_categories"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True)

    requests: Mapped[list["HelpRequest"]] = relationship(back_populates="category")


class HelpRequest(Base, TimestampMixin):
    __tablename__ = "help_requests"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False, index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    category_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("help_categories.id"))
    assigned_to_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))

    issue_type: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="OPEN", nullable=False, index=True)
    priority: Mapped[str] = mapped_column(String(20), default="NORMAL")

    # Device context at time of ticket
    device_terminal: Mapped[str | None] = mapped_column(String(100))

    category: Mapped["HelpCategory"] = relationship(back_populates="requests")
    comments: Mapped[list["HelpComment"]] = relationship(back_populates="request", cascade="all, delete-orphan")
    attachments: Mapped[list["HelpAttachment"]] = relationship(back_populates="request", cascade="all, delete-orphan")
