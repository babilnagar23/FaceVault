"""Time utilities — always UTC-aware."""
from datetime import UTC, datetime, timedelta


def utcnow() -> datetime:
    return datetime.now(UTC)


def clock_drift_seconds(client_ts: datetime, server_ts: datetime | None = None) -> float:
    """Return signed drift in seconds. Positive = client is ahead."""
    server_ts = server_ts or utcnow()
    # Ensure both are timezone-aware
    if client_ts.tzinfo is None:
        client_ts = client_ts.replace(tzinfo=UTC)
    if server_ts.tzinfo is None:
        server_ts = server_ts.replace(tzinfo=UTC)
    return (client_ts - server_ts).total_seconds()


def is_future_timestamp(ts: datetime, tolerance_seconds: int = 30) -> bool:
    return clock_drift_seconds(ts) > tolerance_seconds


def attendance_date(ts: datetime) -> str:
    """Return ISO date string for the date in UTC."""
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=UTC)
    return ts.date().isoformat()
