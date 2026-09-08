import uuid
from sqlalchemy import String, Boolean, Integer, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class Shift(Base, TimestampMixin):
    __tablename__ = "shifts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    start_time: Mapped[str] = mapped_column(String(5), nullable=False)  # "09:00"
    end_time: Mapped[str] = mapped_column(String(5), nullable=False)    # "18:00"
    grace_period_minutes: Mapped[int] = mapped_column(Integer, default=15)
    late_threshold_minutes: Mapped[int] = mapped_column(Integer, default=30)
    # JSON array of working day names: ["Mon", "Tue", "Wed", "Thu", "Fri"]
    working_days: Mapped[list | None] = mapped_column(JSON)
    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    assignments: Mapped[list["Assignment"]] = relationship(back_populates="shift")
