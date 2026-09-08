"""
FaceVault API tests — conftest and test fixtures.
"""
import asyncio
import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import settings
from app.db.base import Base
from app.db.session import get_db
from app.main import app

# ─── Test database (SQLite in-memory for speed) ────────────────────────────────
TEST_DB_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
async def test_engine():
    engine = create_async_engine(TEST_DB_URL, echo=False)
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
