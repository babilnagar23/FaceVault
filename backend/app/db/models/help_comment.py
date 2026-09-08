import uuid
from sqlalchemy import String, Boolean, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class HelpComment(Base, TimestampMixin):
    __tablename__ = "help_comments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    request_id: Mapped[str] = mapped_column(String(36), ForeignKey("help_requests.id"), nullable=False, index=True)
    author_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)

    body: Mapped[str] = mapped_column(Text, nullable=False)
    is_system: Mapped[bool] = mapped_column(Boolean, default=False)  # Auto-generated system messages
    is_internal: Mapped[bool] = mapped_column(Boolean, default=False)  # Admin-only notes

    request: Mapped["HelpRequest"] = relationship(back_populates="comments")
