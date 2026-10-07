from __future__ import annotations
#!/usr/bin/env python3
"""
Create a superadmin user from the command line.

Usage:
  cd backend
  python scripts/create_admin.py --org FVOPS --email admin@example.com --password MyP@ss123 \\
      [--first-name Admin] [--last-name User] [--employee-code ADMIN-002]

Pre-requisites:
  1. PostgreSQL running and reachable via DATABASE_URL
  2. alembic upgrade head already run (tables must exist)
  3. The target organization must exist (run seed.py first, or create it manually)
"""
import argparse
import asyncio
import sys
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))


async def create_admin(
    org_code: str,
    email: str,
    password: str,
    first_name: str = "Admin",
    last_name: str = "User",
    employee_code: str | None = None,
):
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
    from sqlalchemy import select

    from app.config import settings
    from app.core.security import hash_password
    from app.db.models.organization import Organization
    from app.db.models.permission import Permission, RolePermission
    from app.db.models.role import Role
    from app.db.models.user import User

    engine = create_async_engine(settings.DATABASE_URL)
    Session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with Session() as session:
        # ── Locate organization ────────────────────────────────────────────────
        org_result = await session.execute(
            select(Organization).where(Organization.code == org_code.upper())
        )
        org = org_result.scalar_one_or_none()
        if not org:
            print(f"❌ Organization '{org_code}' not found.")
            print("   Run `python scripts/seed.py` first, or create the organization manually.")
            await engine.dispose()
            sys.exit(1)

        # ── Locate or create ADMIN role ────────────────────────────────────────
        role_result = await session.execute(
            select(Role).where(Role.organization_id == org.id, Role.name == "ADMIN")
        )
        role = role_result.scalar_one_or_none()
        if not role:
            print("  ⚠  ADMIN role not found — creating it now...")
            role = Role(
                id=str(uuid.uuid4()),
                organization_id=org.id,
                name="ADMIN",
                display_name="Administrator",
            )
            session.add(role)
            await session.flush()

            # Grant all existing permissions to the new ADMIN role
            perms_result = await session.execute(select(Permission))
            all_perms = perms_result.scalars().all()
            for perm in all_perms:
                session.add(RolePermission(role_id=role.id, permission_id=perm.id))
            await session.flush()
            print(f"  ✓ ADMIN role created with {len(all_perms)} permissions")

        # ── Check email uniqueness within org ──────────────────────────────────
        existing = await session.execute(
            select(User).where(User.organization_id == org.id, User.email == email)
        )
        if existing.scalar_one_or_none():
            print(f"❌ A user with email '{email}' already exists in organization '{org.name}'.")
            await engine.dispose()
            sys.exit(1)

        # ── Derive employee code ────────────────────────────────────────────────
        if not employee_code:
            employee_code = f"ADMIN-{str(uuid.uuid4())[:4].upper()}"

        # ── Create admin user ──────────────────────────────────────────────────
        user = User(
            id=str(uuid.uuid4()),
            organization_id=org.id,
            role_id=role.id,
            employee_code=employee_code,
            first_name=first_name,
            last_name=last_name,
            email=email,
            password_hash=hash_password(password),
            status="ACTIVE",
            face_enrolled=False,
            device_registered=False,
        )
        session.add(user)
        await session.commit()

        print(f"\n✅ Admin user created successfully")
        print(f"   Organization  : {org.name} ({org.code})")
        print(f"   Email         : {email}")
        print(f"   Employee code : {employee_code}")
        print(f"   Role          : ADMIN")

    await engine.dispose()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create a FaceVault admin user")
    parser.add_argument("--org", required=True, help="Organization code (e.g. FVOPS)")
    parser.add_argument("--email", required=True, help="Admin email address")
    parser.add_argument("--password", required=True, help="Admin password")
    parser.add_argument("--first-name", default="Admin", help="First name (default: Admin)")
    parser.add_argument("--last-name", default="User", help="Last name (default: User)")
    parser.add_argument("--employee-code", default=None, help="Employee code (auto-generated if not set)")
    args = parser.parse_args()

    asyncio.run(create_admin(
        org_code=args.org,
        email=args.email,
        password=args.password,
        first_name=args.first_name,
        last_name=args.last_name,
        employee_code=args.employee_code,
    ))
