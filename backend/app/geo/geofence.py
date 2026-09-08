"""
FaceVault — Server-side geofence validation.
The server ALWAYS recalculates distance independently.
It NEVER trusts location_verified: true from the mobile app.
"""
from app.geo.distance import haversine_distance


class GeofenceResult:
    def __init__(
        self,
        inside: bool,
        distance_meters: float,
        assigned_radius_meters: int,
        location_name: str,
    ) -> None:
        self.inside = inside
        self.distance_meters = distance_meters
        self.assigned_radius_meters = assigned_radius_meters
        self.location_name = location_name


def validate_geofence(
    user_lat: float,
    user_lon: float,
    site_lat: float,
    site_lon: float,
    radius_meters: int,
    location_name: str = "",
) -> GeofenceResult:
    """
    Server-side geofence check.
    Returns a GeofenceResult with inside=True only if distance <= radius.
    """
    distance = haversine_distance(user_lat, user_lon, site_lat, site_lon)
    inside = distance <= radius_meters
    return GeofenceResult(
        inside=inside,
        distance_meters=round(distance, 1),
        assigned_radius_meters=radius_meters,
        location_name=location_name,
    )
