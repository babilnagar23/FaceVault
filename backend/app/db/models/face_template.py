import uuid
from datetime import datetime
from sqlalchemy import String, Float, DateTime, Boolean, ForeignKey, LargeBinary
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class FaceTemplate(Base, TimestampMixin):
    """
    Stores encrypted face embedding metadata.
    IMPORTANT: The raw embedding bytes (if stored server-side) must be
    encrypted at rest. This field is NEVER returned through any API.
    """
    __tablename__ = "face_templates"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    enrollment_id: Mapped[str] = mapped_column(String(36), ForeignKey("face_enrollments.id"), nullable=False, index=True)
    model_version: Mapped[str] = mapped_column(String(30), nullable=False)
    quality_score: Mapped[float | None] = mapped_column(Float)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at_device: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Encrypted embedding storage — optional, for server-side re-verification
    # encrypted_embedding: Mapped[bytes | None] = mapped_column(LargeBinary)

    enrollment: Mapped["FaceEnrollment"] = relationship(back_populates="templates")
