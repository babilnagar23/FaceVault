"""
FaceVault — Location fraud signal detection.
These are RISK FLAGS, not guaranteed anti-spoofing.
Suspicious cases are sent to the verification queue, not auto-rejected.
"""
from datetime import datetime
from typing import TYPE_CHECKING

from app.config import settings
from app.core.constants import RiskFlag
from app.utils.time import clock_drift_seconds, is_future_timestamp


def detect_risk_flags(
    *,
    gps_accuracy_meters: float | None,
    client_timestamp: datetime | None,
    server_timestamp: datetime,
    battery_level: int | None = None,
    previous_lat: float | None = None,
    previous_lon: float | None = None,
    previous_timestamp: datetime | None = None,
    current_lat: float | None = None,
    current_lon: float | None = None,
) -> list[str]:
    """
    Returns a list of RiskFlag strings found for this attempt.
    An empty list means no signals detected.
    """
    flags: list[str] = []

    # Poor GPS accuracy
    if gps_accuracy_meters is not None:
        if gps_accuracy_meters > settings.GPS_ACCURACY_THRESHOLD_METERS:
            flags.append(RiskFlag.POOR_GPS_ACCURACY)

    # Future timestamp
    if client_timestamp and is_future_timestamp(client_timestamp, tolerance_seconds=30):
        flags.append(RiskFlag.FUTURE_TIMESTAMP)

    # Large clock drift
    if client_timestamp:
        drift = abs(clock_drift_seconds(client_timestamp, server_timestamp))
        if drift > settings.MAX_CLOCK_DRIFT_SECONDS:
            flags.append(RiskFlag.LARGE_CLOCK_DRIFT)

    # Impossible movement (simple velocity check)
    if (
        previous_lat is not None
        and previous_lon is not None
        and previous_timestamp is not None
        and current_lat is not None
        and current_lon is not None
        and client_timestamp is not None
    ):
        from app.geo.distance import haversine_distance

        dist_m = haversine_distance(previous_lat, previous_lon, current_lat, current_lon)
        elapsed_s = abs((client_timestamp - previous_timestamp).total_seconds())
        if elapsed_s > 0:
            speed_ms = dist_m / elapsed_s
            # > 100 m/s (~360 km/h) is physically suspicious
            if speed_ms > 100:
                flags.append(RiskFlag.IMPOSSIBLE_MOVEMENT)

    return flags
