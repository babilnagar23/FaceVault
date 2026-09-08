#!/usr/bin/env python3
"""
Create a superadmin user from the command line.

Usage:
  cd backend
  python scripts/create_admin.py --org FVOPS --email admin@example.com --password MyP@ss123
"""
import argparse
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))


async def create_admin(org_code: str, email: str, password: str):
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
    from sqlalchemy import select
    from app.config import settings
    from app.core.security import hash_password
    from app.db.models.organization import Organization
    from app.db.models.role import Role
    from app.db.models.user import User

    engine = create_async_engine(settings.DATABASE_URL)
    Session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with Session() as session:
        org_result = await session.execute(select(Organization).where(Organization.code == org_code.upper()))
        org = org_result.scalar_one_or_none()
        if not org:
            print(f"❌ Organization '{org_code}' not found.")
            return

        role_result = await session.execute(select(Role).where(Role.organization_id == org.id, Role.name == "ADMIN"))
        role = role_result.scalar_one_or_none()

        import uuid
        user = User(
            id=str(uuid.uuid4()),
            organization_id=org.id,
            role_id=role.id if role else None,
            employee_code=f"ADMIN-{str(uuid.uuid4())[:4].upper()}",
            first_name="Admin",
            last_name="User",
            email=email,
            password_hash=hash_password(password),
            status="ACTIVE",
        )
        session.add(user)
        await session.commit()
        print(f"✅ Admin created: {email} for organization {org.name}")

    await engine.dispose()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create FaceVault admin user")
    parser.add_argument("--org", required=True, help="Organization code (e.g. FVOPS)")
    parser.add_argument("--email", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()
    asyncio.run(create_admin(args.org, args.email, args.password))
