import uuid
from sqlalchemy import String, Boolean, Float, Integer, Text, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin

# GeoAlchemy2 is used for PostGIS types when available
try:
    from geoalchemy2 import Geometry
    HAS_POSTGIS = True
except ImportError:
    HAS_POSTGIS = False


class Location(Base, TimestampMixin):
    __tablename__ = "locations"
    __table_args__ = (
        Index("ix_locations_org_active", "organization_id", "active"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False, index=True)
    project_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("projects.id"))
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    site_code: Mapped[str | None] = mapped_column(String(50))
    address: Mapped[str | None] = mapped_column(Text)
    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # GPS coordinates stored as plain floats (always available)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    # Geofence radius in meters
    radius_meters: Mapped[int] = mapped_column(Integer, default=150, nullable=False)

    # Working hours (optional — used for shift validation)
    working_hours_start: Mapped[str | None] = mapped_column(String(5))  # "08:00"
    working_hours_end: Mapped[str | None] = mapped_column(String(5))    # "18:00"

    organization: Mapped["Organization"] = relationship(back_populates="locations")
    project: Mapped["Project"] = relationship(back_populates="locations")
    assignments: Mapped[list["Assignment"]] = relationship(back_populates="location")
