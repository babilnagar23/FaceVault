"""
FaceVault API tests — conftest and test fixtures.

Unit tests use SQLite in-memory (fast, no infrastructure).
Integration tests use PostgreSQL (requires POSTGRES_TEST_URL env var or docker-compose).

Run unit tests only:    pytest -m unit
Run API tests (SQLite): pytest -m api
Run integration tests:  pytest -m integration
Run all:                pytest
"""
import asyncio
import os
import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import settings
from app.db.base import Base
from app.db.session import get_db
from app.main import app

# ─── SQLite (unit / api tests) ────────────────────────────────────────────────
TEST_DB_URL = "sqlite+aiosqlite:///:memory:"

# ─── PostgreSQL (integration tests) ──────────────────────────────────────────
# Override via environment: POSTGRES_TEST_URL=postgresql+asyncpg://...
POSTGRES_TEST_URL = os.getenv(
    "POSTGRES_TEST_URL",
    "postgresql+asyncpg://facevault:facevault_dev@localhost:5432/facevault_test",
)


# ─────────────────────────────────────────────────────────────────────────────
# Event loop (session-scoped so async fixtures work across tests)
# ─────────────────────────────────────────────────────────────────────────────
@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


# ─────────────────────────────────────────────────────────────────────────────
# SQLite engine + session (for unit and API tests)
# ─────────────────────────────────────────────────────────────────────────────
@pytest.fixture(scope="session")
async def test_engine():
    engine = create_async_engine(
        TEST_DB_URL,
        echo=False,
        connect_args={"check_same_thread": False},
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest.fixture
async def db_session(test_engine):
    Session = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as session:
        yield session
        await session.rollback()


@pytest.fixture
async def client(db_session):
    """Async test client with injected DB session."""
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


# ─────────────────────────────────────────────────────────────────────────────
# Seeded org fixture (SQLite — for API tests)
# ─────────────────────────────────────────────────────────────────────────────
@pytest.fixture
async def seeded_org(db_session) -> dict:
    """Create a minimal org + admin user for tests."""
    from app.db.models.organization import Organization
    from app.db.models.role import Role
    from app.db.models.user import User
    from app.core.security import hash_password

    org = Organization(id="test-org", name="Test Org", code="TESTORG", active=True, timezone="UTC")
    db_session.add(org)
    role = Role(organization_id="test-org", name="ADMIN", display_name="Admin")
    db_session.add(role)
    await db_session.flush()

    user = User(
        organization_id="test-org",
        role_id=role.id,
        employee_code="TEST-001",
        first_name="Test",
        last_name="Admin",
        email="test@test.com",
        password_hash=hash_password("Test@1234"),
        status="ACTIVE",
    )
    db_session.add(user)
    await db_session.commit()
    return {"org_id": org.id, "user_id": user.id, "employee_code": "TEST-001", "password": "Test@1234"}


# ─────────────────────────────────────────────────────────────────────────────
# PostgreSQL engine + session (integration tests only)
# ─────────────────────────────────────────────────────────────────────────────
@pytest.fixture(scope="session")
async def pg_engine():
    """Session-scoped PostgreSQL engine for integration tests."""
    engine = create_async_engine(POSTGRES_TEST_URL, echo=False)
    # Run migrations via Alembic instead of create_all, but for integration
    # test setup we use run_sync to ensure a clean state.
    async with engine.begin() as conn:
        # Enable PostGIS before creating tables
        await conn.execute(
            __import__("sqlalchemy", fromlist=["text"]).text(
                "CREATE EXTENSION IF NOT EXISTS postgis"
            )
        )
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    # Cleanup after all integration tests complete
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest.fixture
async def pg_session(pg_engine):
    """Transaction-isolated PostgreSQL session per test."""
    Session = async_sessionmaker(pg_engine, class_=AsyncSession, expire_on_commit=False)
    async with Session() as session:
        async with session.begin():
            yield session
            await session.rollback()


@pytest.fixture
async def pg_seeded_org(pg_session) -> dict:
    """Create a minimal org + admin user in PostgreSQL for integration tests."""
    from app.db.models.organization import Organization
    from app.db.models.organization_settings import OrganizationSettings
    from app.db.models.role import Role
    from app.db.models.user import User
    from app.core.security import hash_password

    org = Organization(id="pg-test-org", name="PG Test Org", code="PGTESTORG", active=True, timezone="UTC")
    pg_session.add(org)
    pg_session.add(OrganizationSettings(organization_id="pg-test-org"))
    role = Role(organization_id="pg-test-org", name="ADMIN", display_name="Admin")
    pg_session.add(role)
    await pg_session.flush()

    user = User(
        organization_id="pg-test-org",
        role_id=role.id,
        employee_code="PG-001",
        first_name="PG",
        last_name="Admin",
        email="pgtest@test.com",
        password_hash=hash_password("Test@1234"),
        status="ACTIVE",
    )
    pg_session.add(user)
    await pg_session.flush()
    return {"org_id": org.id, "user_id": user.id, "employee_code": "PG-001", "password": "Test@1234"}
