"""
Mandatory test cases per the implementation plan:
1. Valid attendance attempt
2. Location exception (outside geofence)
3. Duplicate event (idempotency)
4. Cross-org access rejection
"""
import pytest
from httpx import AsyncClient


@pytest.mark.api
async def test_health(client: AsyncClient):
    res = await client.get("/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ok"


@pytest.mark.api
async def test_employee_login_success(client: AsyncClient, seeded_org: dict):
    res = await client.post("/api/v1/auth/login", json={
        "employee_id": seeded_org["employee_code"],
        "password": seeded_org["password"],
    })
    assert res.status_code == 200
    data = res.json()
    assert "tokens" in data
    assert data["tokens"]["access_token"]
    assert data["user"]["employee_code"] == seeded_org["employee_code"]


@pytest.mark.api
async def test_employee_login_wrong_password(client: AsyncClient, seeded_org: dict):
    res = await client.post("/api/v1/auth/login", json={
        "employee_id": seeded_org["employee_code"],
        "password": "wrong",
    })
    assert res.status_code == 401


@pytest.mark.unit
def test_haversine_distance():
    """Test GPS distance calculation."""
    from app.geo.distance import haversine_distance

    # Delhi to Gurugram — approximately 28 km
    dist = haversine_distance(28.6139, 77.2090, 28.4595, 77.0266)
    assert 25_000 < dist < 35_000, f"Expected ~28km, got {dist/1000:.1f}km"

    # Same point — must be 0
    dist_zero = haversine_distance(28.5901, 77.0479, 28.5901, 77.0479)
    assert dist_zero < 0.01


@pytest.mark.unit
def test_geofence_inside():
    from app.geo.geofence import validate_geofence

    result = validate_geofence(
        user_lat=28.5901, user_lon=77.0479,
        site_lat=28.5901, site_lon=77.0479,
        radius_meters=150,
    )
    assert result.inside is True
    assert result.distance_meters < 1


@pytest.mark.unit
def test_geofence_outside():
    from app.geo.geofence import validate_geofence

    # 1.5 km away from site
    result = validate_geofence(
        user_lat=28.6039, user_lon=77.0479,  # ~1.5 km north
        site_lat=28.5901, site_lon=77.0479,
        radius_meters=150,
    )
    assert result.inside is False
    assert result.distance_meters > 150


@pytest.mark.unit
def test_risk_flags_future_timestamp():
    from datetime import UTC, datetime, timedelta
    from app.geo.anti_spoof import detect_risk_flags

    future_ts = datetime.now(UTC) + timedelta(minutes=10)
    flags = detect_risk_flags(
        gps_accuracy_meters=5.0,
        client_timestamp=future_ts,
        server_timestamp=datetime.now(UTC),
    )
    assert "FUTURE_TIMESTAMP" in flags


@pytest.mark.unit
def test_risk_flags_poor_gps():
    from datetime import UTC, datetime
    from app.geo.anti_spoof import detect_risk_flags

    flags = detect_risk_flags(
        gps_accuracy_meters=200.0,  # Very poor GPS
        client_timestamp=datetime.now(UTC),
        server_timestamp=datetime.now(UTC),
    )
    assert "POOR_GPS_ACCURACY" in flags


@pytest.mark.unit
def test_hash_password():
    from app.core.security import hash_password, verify_password

    hashed = hash_password("Test@1234")
    assert hashed != "Test@1234"
    assert verify_password("Test@1234", hashed) is True
    assert verify_password("wrong", hashed) is False


@pytest.mark.unit
def test_jwt_roundtrip():
    from app.core.security import create_access_token, decode_access_token

    token = create_access_token(
        subject="user-123",
        organization_id="org-456",
        role="ADMIN",
    )
    payload = decode_access_token(token)
    assert payload["sub"] == "user-123"
    assert payload["org"] == "org-456"
    assert payload["role"] == "ADMIN"
    assert payload["type"] == "access"


@pytest.mark.api
async def test_duplicate_attendance_attempt_idempotent(client: AsyncClient, seeded_org: dict):
    """
    Submitting the same client_event_id twice must return the same result.
    This is the critical idempotency test.
    """
    # Login first
    login_res = await client.post("/api/v1/auth/login", json={
        "employee_id": seeded_org["employee_code"],
        "password": seeded_org["password"],
    })
    token = login_res.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    event_id = "test-idempotency-event-001"
    payload = {
        "client_event_id": event_id,
        "event_type": "CHECK_IN",
        "face_verified": True,
        "face_score": 0.99,
        "liveness_verified": True,
        "liveness_score": 0.97,
    }

    res1 = await client.post("/api/v1/attendance/attempt", json=payload, headers=headers)
    res2 = await client.post("/api/v1/attendance/attempt", json=payload, headers=headers)

    assert res1.status_code == 200
    assert res2.status_code == 200
    # Same record should be returned
    assert res1.json()["client_event_id"] == res2.json()["client_event_id"]
    assert res1.json()["id"] == res2.json()["id"]
