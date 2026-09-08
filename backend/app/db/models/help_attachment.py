import uuid
from sqlalchemy import String, Integer, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class HelpAttachment(Base, TimestampMixin):
    __tablename__ = "help_attachments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    request_id: Mapped[str] = mapped_column(String(36), ForeignKey("help_requests.id"), nullable=False, index=True)
    uploaded_by_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)

    # Stored in S3/MinIO — never store raw files in DB
    storage_key: Mapped[str] = mapped_column(String(500), nullable=False)
    original_filename: Mapped[str] = mapped_column(String(255), nullable=False)
    content_type: Mapped[str] = mapped_column(String(100), nullable=False)
    size_bytes: Mapped[int | None] = mapped_column(Integer)

    request: Mapped["HelpRequest"] = relationship(back_populates="attachments")
