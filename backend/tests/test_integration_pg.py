"""
PostgreSQL integration tests for FaceVault.

These tests require a live PostgreSQL+PostGIS database.
Set POSTGRES_TEST_URL env var or use the default (matches docker-compose).

Run: pytest -m integration
"""
import uuid
from datetime import UTC, datetime, date
import pytest

pytestmark = pytest.mark.integration


@pytest.mark.integration
async def test_pg_extensions_enabled(pg_session):
    """PostGIS and uuid-ossp extensions must be installed."""
    from sqlalchemy import text
    result = await pg_session.execute(
        text("SELECT extname FROM pg_extension WHERE extname IN ('postgis', 'uuid-ossp') ORDER BY extname")
    )
    extensions = [row[0] for row in result]
    assert "postgis" in extensions, "PostGIS extension must be enabled"


@pytest.mark.integration
async def test_org_unique_code_constraint(pg_session):
    """organization.code must be globally unique."""
    from sqlalchemy.exc import IntegrityError
    from app.db.models.organization import Organization

    org1 = Organization(name="Org One", code="DUPE-CODE", active=True, timezone="UTC")
    org2 = Organization(name="Org Two", code="DUPE-CODE", active=True, timezone="UTC")
    pg_session.add(org1)
    await pg_session.flush()
    pg_session.add(org2)
    with pytest.raises(IntegrityError):
        await pg_session.flush()


@pytest.mark.integration
async def test_user_org_email_unique_constraint(pg_seeded_org, pg_session):
    """(organization_id, email) must be unique within an org."""
    from sqlalchemy.exc import IntegrityError
    from app.db.models.user import User
    from app.core.security import hash_password

    duplicate = User(
        organization_id=pg_seeded_org["org_id"],
        employee_code="PG-DUP",
        first_name="Dup",
        last_name="User",
        email="pgtest@test.com",  # same as seeded user
        password_hash=hash_password("Test@1234"),
        status="ACTIVE",
    )
    pg_session.add(duplicate)
    with pytest.raises(IntegrityError):
        await pg_session.flush()


@pytest.mark.integration
async def test_user_org_employee_code_unique_constraint(pg_seeded_org, pg_session):
    """(organization_id, employee_code) must be unique within an org."""
    from sqlalchemy.exc import IntegrityError
    from app.db.models.user import User
    from app.core.security import hash_password

    duplicate = User(
        organization_id=pg_seeded_org["org_id"],
        employee_code="PG-001",   # same as seeded user
        first_name="Dup",
        last_name="User",
        email="unique-dup@test.com",
        password_hash=hash_password("Test@1234"),
        status="ACTIVE",
    )
    pg_session.add(duplicate)
    with pytest.raises(IntegrityError):
        await pg_session.flush()


@pytest.mark.integration
async def test_attendance_attempt_idempotency_constraint(pg_seeded_org, pg_session):
    """client_event_id must be unique across attendance_attempts."""
    from sqlalchemy.exc import IntegrityError
    from app.db.models.attendance_attempt import AttendanceAttempt

    event_id = f"test-event-{uuid.uuid4()}"
    attempt1 = AttendanceAttempt(
        client_event_id=event_id,
        organization_id=pg_seeded_org["org_id"],
        user_id=pg_seeded_org["user_id"],
        event_type="CHECK_IN",
        server_received_at=datetime.now(UTC),
        status="VERIFIED",
    )
    attempt2 = AttendanceAttempt(
        client_event_id=event_id,  # duplicate
        organization_id=pg_seeded_org["org_id"],
        user_id=pg_seeded_org["user_id"],
        event_type="CHECK_IN",
        server_received_at=datetime.now(UTC),
        status="VERIFIED",
    )
    pg_session.add(attempt1)
    await pg_session.flush()
    pg_session.add(attempt2)
    with pytest.raises(IntegrityError):
        await pg_session.flush()


@pytest.mark.integration
async def test_attendance_record_daily_unique_constraint(pg_seeded_org, pg_session):
    """(user_id, attendance_date, shift_id) must be unique in attendance_records."""
    from sqlalchemy.exc import IntegrityError
    from app.db.models.attendance_attempt import AttendanceAttempt
    from app.db.models.attendance_record import AttendanceRecord

    check_in = AttendanceAttempt(
        client_event_id=f"ci-{uuid.uuid4()}",
        organization_id=pg_seeded_org["org_id"],
        user_id=pg_seeded_org["user_id"],
        event_type="CHECK_IN",
        server_received_at=datetime.now(UTC),
        status="VERIFIED",
    )
    pg_session.add(check_in)
    await pg_session.flush()

    today = date.today()
    shift_placeholder = str(uuid.uuid4())  # shift_id can be NULL for this test

    record1 = AttendanceRecord(
        organization_id=pg_seeded_org["org_id"],
        user_id=pg_seeded_org["user_id"],
        attendance_date=today,
        shift_id=None,
        status="PRESENT",
    )
    record2 = AttendanceRecord(
        organization_id=pg_seeded_org["org_id"],
        user_id=pg_seeded_org["user_id"],
        attendance_date=today,
        shift_id=None,
        status="LATE",
    )
    pg_session.add(record1)
    await pg_session.flush()
    pg_session.add(record2)
    with pytest.raises(IntegrityError):
        await pg_session.flush()


@pytest.mark.integration
async def test_device_uuid_unique_constraint(pg_seeded_org, pg_session):
    """device_uuid must be globally unique."""
    from sqlalchemy.exc import IntegrityError
    from app.db.models.device import Device

    dev_uuid = f"dev-{uuid.uuid4()}"
    d1 = Device(
        user_id=pg_seeded_org["user_id"],
        organization_id=pg_seeded_org["org_id"],
        device_uuid=dev_uuid,
        platform="android",
        status="REGISTERED",
        registered_at=datetime.now(UTC),
    )
    d2 = Device(
        user_id=pg_seeded_org["user_id"],
        organization_id=pg_seeded_org["org_id"],
        device_uuid=dev_uuid,  # duplicate
        platform="ios",
        status="REGISTERED",
        registered_at=datetime.now(UTC),
    )
    pg_session.add(d1)
    await pg_session.flush()
    pg_session.add(d2)
    with pytest.raises(IntegrityError):
        await pg_session.flush()


@pytest.mark.integration
async def test_consent_user_type_unique_constraint(pg_seeded_org, pg_session):
    """A user can only have one consent record per type."""
    from sqlalchemy.exc import IntegrityError
    from app.db.models.consent import Consent

    c1 = Consent(user_id=pg_seeded_org["user_id"], type="BIOMETRIC", version="1.0", accepted=True,
                 accepted_at=datetime.now(UTC))
    c2 = Consent(user_id=pg_seeded_org["user_id"], type="BIOMETRIC", version="1.0", accepted=True,
                 accepted_at=datetime.now(UTC))
    pg_session.add(c1)
    await pg_session.flush()
    pg_session.add(c2)
    with pytest.raises(IntegrityError):
        await pg_session.flush()


@pytest.mark.integration
async def test_org_settings_one_to_one_constraint(pg_seeded_org, pg_session):
    """Only one settings record is allowed per organization."""
    from sqlalchemy.exc import IntegrityError
    from app.db.models.organization_settings import OrganizationSettings

    # pg_seeded_org already creates settings — try to add another
    duplicate_settings = OrganizationSettings(organization_id=pg_seeded_org["org_id"])
    pg_session.add(duplicate_settings)
    with pytest.raises(IntegrityError):
        await pg_session.flush()


@pytest.mark.integration
async def test_sync_event_idempotency_constraint(pg_seeded_org, pg_session):
    """client_event_id must be unique in sync_events."""
    from sqlalchemy.exc import IntegrityError
    from app.db.models.sync_event import SyncEvent

    event_id = f"sync-{uuid.uuid4()}"
    s1 = SyncEvent(
        client_event_id=event_id,
        organization_id=pg_seeded_org["org_id"],
        user_id=pg_seeded_org["user_id"],
        entity_type="attendance_attempt",
        operation="create",
        server_received_at=datetime.now(UTC),
        status="PENDING",
    )
    s2 = SyncEvent(
        client_event_id=event_id,  # duplicate
        organization_id=pg_seeded_org["org_id"],
        user_id=pg_seeded_org["user_id"],
        entity_type="attendance_attempt",
        operation="create",
        server_received_at=datetime.now(UTC),
        status="PENDING",
    )
    pg_session.add(s1)
    await pg_session.flush()
    pg_session.add(s2)
    with pytest.raises(IntegrityError):
        await pg_session.flush()


@pytest.mark.integration
async def test_role_unique_per_org(pg_seeded_org, pg_session):
    """(organization_id, name) must be unique for roles."""
    from sqlalchemy.exc import IntegrityError
    from app.db.models.role import Role

    # pg_seeded_org already creates ADMIN role
    duplicate_role = Role(
        organization_id=pg_seeded_org["org_id"],
        name="ADMIN",   # duplicate
        display_name="Another Admin",
    )
    pg_session.add(duplicate_role)
    with pytest.raises(IntegrityError):
        await pg_session.flush()


@pytest.mark.integration
async def test_location_geo_point_generated_column(pg_seeded_org, pg_session):
    """geo_point generated column must be populated from lat/lon."""
    from sqlalchemy import text
    from app.db.models.location import Location

    # Create a project first
    from app.db.models.project import Project
    proj = Project(organization_id=pg_seeded_org["org_id"], name="GeoTest Project", active=True)
    pg_session.add(proj)
    await pg_session.flush()

    loc = Location(
        organization_id=pg_seeded_org["org_id"],
        project_id=proj.id,
        name="Geo Test Site",
        latitude=28.5901,
        longitude=77.0479,
        radius_meters=150,
        active=True,
    )
    pg_session.add(loc)
    await pg_session.flush()

    result = await pg_session.execute(
        text("SELECT ST_AsText(geo_point) FROM locations WHERE id = :loc_id"),
        {"loc_id": loc.id}
    )
    geo_text = result.scalar()
    assert geo_text is not None, "geo_point should be auto-populated"
    assert "77.0479" in geo_text or "28.5901" in geo_text, f"Unexpected geo_point value: {geo_text}"


@pytest.mark.integration
async def test_face_enrollment_one_per_user(pg_seeded_org, pg_session):
    """Only one face enrollment per user."""
    from sqlalchemy.exc import IntegrityError
    from app.db.models.face_enrollment import FaceEnrollment

    e1 = FaceEnrollment(
        user_id=pg_seeded_org["user_id"],
        organization_id=pg_seeded_org["org_id"],
        status="ENROLLED",
        enrolled_at=datetime.now(UTC),
    )
    e2 = FaceEnrollment(
        user_id=pg_seeded_org["user_id"],  # duplicate
        organization_id=pg_seeded_org["org_id"],
        status="ENROLLED",
        enrolled_at=datetime.now(UTC),
    )
    pg_session.add(e1)
    await pg_session.flush()
    pg_session.add(e2)
    with pytest.raises(IntegrityError):
        await pg_session.flush()
