from __future__ import annotations
from typing import Optional
"""
LocationService — server-side location and geofence validation.

The server is the authoritative source for geofence distance.
Client-provided distance is never trusted.
"""

import math

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.location import Location


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate great-circle distance in metres between two GPS coordinates.
    Uses Haversine formula.
    """
    R = 6_371_000  # Earth radius in metres
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1 - a))


class LocationService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def get_active_location(
        self, location_id: str, organization_id: str
    ) -> Optional[Location]:
        """Load an active location scoped to an organization."""
        result = await self._db.execute(
            select(Location).where(
                Location.id == location_id,
                Location.organization_id == organization_id,
                Location.active == True,
            )
        )
        return result.scalar_one_or_none()

    def calculate_distance(
        self,
        user_lat: float,
        user_lon: float,
        location: Location,
    ) -> float:
        """
        Calculate server-side distance from the user's GPS to the location.
        Always use this — never trust client-reported distance.
        """
        return haversine_distance(user_lat, user_lon, location.latitude, location.longitude)

    def is_within_geofence(
        self,
        user_lat: float,
        user_lon: float,
        location: Location,
        override_radius_m: Optional[int] = None,
    ) -> tuple[bool, float]:
        """
        Verify whether the user is within the location's geofence.

        Returns:
            (is_inside, distance_metres)
        """
        distance = self.calculate_distance(user_lat, user_lon, location)
        radius = override_radius_m if override_radius_m is not None else location.radius_meters
        return distance <= radius, distance
