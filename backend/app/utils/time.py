from __future__ import annotations
from typing import Optional
"""Time utilities — always UTC-aware."""

from datetime import timezone, datetime, timedelta


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def clock_drift_seconds(client_ts: datetime, server_ts: Optional[datetime] = None) -> float:
    """Return signed drift in seconds. Positive = client is ahead."""
    server_ts = server_ts or utcnow()
    # Ensure both are timezone-aware
    if client_ts.tzinfo is None:
        client_ts = client_ts.replace(tzinfo=timezone.utc)
    if server_ts.tzinfo is None:
        server_ts = server_ts.replace(tzinfo=timezone.utc)
    return (client_ts - server_ts).total_seconds()


def is_future_timestamp(ts: datetime, tolerance_seconds: int = 30) -> bool:
    return clock_drift_seconds(ts) > tolerance_seconds


def attendance_date(ts: datetime) -> str:
    """Return ISO date string for the date in UTC."""
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    return ts.date().isoformat()
