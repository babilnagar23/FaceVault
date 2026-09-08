import uuid
from datetime import datetime
from sqlalchemy import String, Float, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class FaceEnrollment(Base, TimestampMixin):
    __tablename__ = "face_enrollments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), unique=True, nullable=False, index=True)
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False)

    status: Mapped[str] = mapped_column(String(30), default="NOT_ENROLLED", nullable=False)
    model_version: Mapped[str | None] = mapped_column(String(30))
    quality_score: Mapped[float | None] = mapped_column(Float)
    liveness_score: Mapped[float | None] = mapped_column(Float)
    enrolled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped["User"] = relationship(back_populates="face_enrollment")
    templates: Mapped[list["FaceTemplate"]] = relationship(back_populates="enrollment", cascade="all, delete-orphan")
