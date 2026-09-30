#!/usr/bin/env python3
"""
FaceVault — Database Seeder
Seeds the database with demo data matching the existing mock data
so the frontend works immediately after backend setup.

Usage:
  cd backend
  python scripts/seed.py

What this script creates:
  - 1 organization (FaceVault Operations / FVOPS)
  - Organization settings
  - 6 roles (OWNER, ADMIN, HR, MANAGER, SUPERVISOR, EMPLOYEE) with permissions
  - 4 departments
  - 2 projects
  - 3 locations
  - 4 shifts
  - 1 admin user
  - 5 demo employee users (with Device + FaceEnrollment records)
  - 5 assignments
  - 12 help categories
"""
import asyncio
import sys
import uuid
from datetime import date, datetime, UTC
from pathlib import Path

# Add backend root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import settings
from app.core.security import hash_password
from app.db.models.assignment import Assignment
from app.db.models.department import Department
from app.db.models.device import Device
from app.db.models.face_enrollment import FaceEnrollment
from app.db.models.help_category import HelpCategory
from app.db.models.location import Location
from app.db.models.organization import Organization
from app.db.models.organization_settings import OrganizationSettings
from app.db.models.permission import Permission, RolePermission
from app.db.models.project import Project
from app.db.models.role import Role
from app.db.models.shift import Shift
from app.db.models.user import User


# ─── Permission definitions ────────────────────────────────────────────────────
PERMISSIONS = [
    # Attendance
    ("attendance.view_own", "View own attendance records"),
    ("attendance.view_team", "View team attendance records"),
    ("attendance.view_org", "View all organization attendance"),
    ("attendance.approve", "Approve attendance exceptions"),
    ("attendance.override", "Manually override attendance status"),
    # Employees
    ("employees.view", "View employee list"),
    ("employees.create", "Create new employees"),
    ("employees.edit", "Edit employee details"),
    ("employees.deactivate", "Deactivate employees"),
    # Projects / Locations
    ("projects.manage", "Create and edit projects"),
    ("locations.manage", "Create and edit locations"),
    ("shifts.manage", "Create and edit shifts"),
    ("assignments.manage", "Manage user assignments"),
    # Biometrics
    ("biometrics.enroll", "Enroll employee biometrics"),
    ("biometrics.view_status", "View enrollment status"),
    # Reports
    ("reports.view", "View reports"),
    ("reports.export", "Export reports"),
    # Announcements
    ("announcements.create", "Create announcements"),
    ("announcements.manage", "Manage all announcements"),
    # Help desk
    ("helpdesk.view", "View help requests"),
    ("helpdesk.manage", "Manage help requests"),
    # Settings
    ("settings.view", "View organization settings"),
    ("settings.manage", "Manage organization settings"),
    # Devices
    ("devices.manage", "Manage registered devices"),
    # Audit
    ("audit.view", "View audit logs"),
]

# Role → permission codes mapping
ROLE_PERMISSIONS: dict[str, list[str]] = {
    "OWNER": [p[0] for p in PERMISSIONS],  # all
    "ADMIN": [p[0] for p in PERMISSIONS],  # all
    "HR": [
        "attendance.view_org", "attendance.approve",
        "employees.view", "employees.create", "employees.edit", "employees.deactivate",
        "biometrics.enroll", "biometrics.view_status",
        "reports.view", "reports.export",
        "announcements.create", "announcements.manage",
        "helpdesk.view", "helpdesk.manage",
        "shifts.manage", "assignments.manage",
        "settings.view",
    ],
    "MANAGER": [
        "attendance.view_team", "attendance.approve",
        "employees.view",
        "biometrics.view_status",
        "reports.view",
        "announcements.create",
        "helpdesk.view",
        "assignments.manage",
        "settings.view",
    ],
    "SUPERVISOR": [
        "attendance.view_team",
        "employees.view",
        "biometrics.view_status",
        "reports.view",
        "announcements.create",
        "helpdesk.view",
    ],
    "EMPLOYEE": [
        "attendance.view_own",
        "helpdesk.view",
    ],
}


async def seed():
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        print("🌱 Seeding FaceVault database...")

        # ── Check if already seeded ───────────────────────────────────────────
        existing = await session.execute(
            select(Organization).where(Organization.code == "FVOPS")
        )
        if existing.scalar_one_or_none():
            print("⚠️  Organization 'FVOPS' already exists — skipping seed.")
            return

        # ── Organization ──────────────────────────────────────────────────────
        org = Organization(
            id="org-facevault-demo",
            name="FaceVault Operations",
            code="FVOPS",
            domain="facevault.io",
            active=True,
            timezone="Asia/Kolkata",
        )
        session.add(org)
        await session.flush()
        print("  ✓ Organization created")

        # ── Org Settings ──────────────────────────────────────────────────────
        session.add(OrganizationSettings(organization_id=org.id))
        await session.flush()
        print("  ✓ Organization settings created")

        # ── Permissions ───────────────────────────────────────────────────────
        perm_map: dict[str, Permission] = {}
        for code, description in PERMISSIONS:
            perm = Permission(id=str(uuid.uuid4()), code=code, description=description)
            session.add(perm)
            perm_map[code] = perm
        await session.flush()
        print(f"  ✓ {len(perm_map)} permissions created")

        # ── Roles ─────────────────────────────────────────────────────────────
        role_names = [
            ("OWNER", "Owner"),
            ("ADMIN", "Administrator"),
            ("HR", "HR Manager"),
            ("MANAGER", "Manager"),
            ("SUPERVISOR", "Supervisor"),
            ("EMPLOYEE", "Employee"),
        ]
        role_map: dict[str, Role] = {}
        for name, display in role_names:
            role = Role(organization_id=org.id, name=name, display_name=display)
            session.add(role)
            role_map[name] = role
        await session.flush()
        print(f"  ✓ {len(role_map)} roles created")

        # ── Role Permissions ──────────────────────────────────────────────────
        rp_count = 0
        for role_name, perm_codes in ROLE_PERMISSIONS.items():
            role = role_map[role_name]
            for code in perm_codes:
                if code in perm_map:
                    session.add(RolePermission(role_id=role.id, permission_id=perm_map[code].id))
                    rp_count += 1
        await session.flush()
        print(f"  ✓ {rp_count} role-permission links created")

        # ── Departments ───────────────────────────────────────────────────────
        ops_dept = Department(organization_id=org.id, name="Operations", code="OPS")
        safety_dept = Department(organization_id=org.id, name="Safety", code="SAF")
        logistics_dept = Department(organization_id=org.id, name="Logistics", code="LOG")
        eng_dept = Department(organization_id=org.id, name="Engineering", code="ENG")
        session.add_all([ops_dept, safety_dept, logistics_dept, eng_dept])
        await session.flush()
        print("  ✓ Departments created")

        # ── Projects ──────────────────────────────────────────────────────────
        metro = Project(organization_id=org.id, name="Metro Expansion", code="METRO", active=True)
        depot = Project(organization_id=org.id, name="Depot Upgrade", code="DEPOT", active=True)
        session.add_all([metro, depot])
        await session.flush()
        print("  ✓ Projects created")

        # ── Locations ─────────────────────────────────────────────────────────
        sector17 = Location(
            organization_id=org.id, project_id=metro.id,
            name="Sector 17", site_code="DEL-MR-02",
            address="Sector 17 work site, Delhi NCR",
            latitude=28.5901, longitude=77.0479, radius_meters=150, active=True,
        )
        depot4 = Location(
            organization_id=org.id, project_id=depot.id,
            name="Depot 4", site_code="DEL-DP-04",
            address="Depot 4 maintenance yard, Delhi NCR",
            latitude=28.6129, longitude=77.0831, radius_meters=120, active=True,
        )
        hq = Location(
            organization_id=org.id,
            name="HQ Office", site_code="GGN-HQ-01",
            address="Corporate headquarters, Gurugram",
            latitude=28.4595, longitude=77.0266, radius_meters=200, active=True,
        )
        session.add_all([sector17, depot4, hq])
        await session.flush()
        print("  ✓ Locations created")

        # ── Shifts ────────────────────────────────────────────────────────────
        shift_9_18 = Shift(organization_id=org.id, name="Morning Shift", start_time="09:00", end_time="18:00",
                           grace_period_minutes=15, late_threshold_minutes=30,
                           working_days=["Mon", "Tue", "Wed", "Thu", "Fri"])
        shift_8_17 = Shift(organization_id=org.id, name="Early Shift", start_time="08:00", end_time="17:00",
                           grace_period_minutes=15, late_threshold_minutes=30,
                           working_days=["Mon", "Tue", "Wed", "Thu", "Fri"])
        shift_7_16 = Shift(organization_id=org.id, name="Dawn Shift", start_time="07:00", end_time="16:00",
                           grace_period_minutes=10, late_threshold_minutes=20,
                           working_days=["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
        shift_10_19 = Shift(organization_id=org.id, name="Late Shift", start_time="10:00", end_time="19:00",
                            grace_period_minutes=15, late_threshold_minutes=30,
                            working_days=["Mon", "Tue", "Wed", "Thu", "Fri"])
        session.add_all([shift_9_18, shift_8_17, shift_7_16, shift_10_19])
        await session.flush()
        print("  ✓ Shifts created")

        # ── Admin user ────────────────────────────────────────────────────────
        admin_user = User(
            id="user-admin-001",
            organization_id=org.id,
            role_id=role_map["ADMIN"].id,
            employee_code="ADMIN-001",
            first_name="FaceVault",
            last_name="Admin",
            email="admin@facevault.io",
            password_hash=hash_password("Admin@1234"),
            status="ACTIVE",
            face_enrolled=False,
            device_registered=False,
        )
        session.add(admin_user)
        await session.flush()
        print("  ✓ Admin user created")

        # ── Demo employees ────────────────────────────────────────────────────
        employees_data = [
            dict(id="emp-1042", code="EMP-1042", first="Aarav", last="Mehta",
                 email="aarav.mehta@facevault.io", dept=ops_dept, shift=shift_9_18,
                 location=sector17, project=metro, join="2024-03-01"),
            dict(id="emp-1177", code="EMP-1177", first="Nisha", last="Rao",
                 email="nisha.rao@facevault.io", dept=safety_dept, shift=shift_9_18,
                 location=sector17, project=metro, join="2023-08-15"),
            dict(id="emp-1320", code="EMP-1320", first="Kabir", last="Shah",
                 email="kabir.shah@facevault.io", dept=logistics_dept, shift=shift_10_19,
                 location=depot4, project=depot, join="2022-11-20"),
            dict(id="emp-1401", code="EMP-1401", first="Priya", last="Kumar",
                 email="priya.kumar@facevault.io", dept=eng_dept, shift=shift_8_17,
                 location=sector17, project=metro, join="2025-01-10"),
            dict(id="emp-1528", code="EMP-1528", first="Rohan", last="Gupta",
                 email="rohan.gupta@facevault.io", dept=logistics_dept, shift=shift_7_16,
                 location=depot4, project=depot, join="2025-04-22"),
        ]

        for d in employees_data:
            # Create user (face_enrolled & device_registered will be set after records)
            user = User(
                id=d["id"],
                organization_id=org.id,
                role_id=role_map["EMPLOYEE"].id,
                department_id=d["dept"].id,
                employee_code=d["code"],
                first_name=d["first"],
                last_name=d["last"],
                email=d["email"],
                password_hash=hash_password("Employee@1234"),
                status="ACTIVE",
                face_enrolled=False,   # will be updated below after enrollment record
                device_registered=False,
                join_date=datetime.strptime(d["join"], "%Y-%m-%d").replace(tzinfo=UTC),
            )
            session.add(user)
            await session.flush()

            # ── Device record (required before setting device_registered=True) ──
            device = Device(
                id=str(uuid.uuid4()),
                user_id=user.id,
                organization_id=org.id,
                device_uuid=f"dev-seed-{d['id']}",
                platform="android",
                manufacturer="Samsung",
                model="Galaxy A54",
                os_version="14",
                app_version="1.0.0",
                status="REGISTERED",
                registered_at=datetime.now(UTC),
                last_seen_at=datetime.now(UTC),
            )
            session.add(device)
            await session.flush()

            # ── Face enrollment record (required before setting face_enrolled=True) ──
            enrollment = FaceEnrollment(
                user_id=user.id,
                organization_id=org.id,
                status="ENROLLED",
                model_version="facenet-v1",
                quality_score=0.92,
                liveness_score=0.95,
                enrolled_at=datetime.now(UTC),
                last_updated_at=datetime.now(UTC),
            )
            session.add(enrollment)
            await session.flush()

            # ── Now update user flags to reflect actual records ────────────────
            user.face_enrolled = True
            user.device_registered = True
            await session.flush()

            # ── Active assignment ──────────────────────────────────────────────
            assignment = Assignment(
                organization_id=org.id,
                user_id=user.id,
                project_id=d["project"].id,
                location_id=d["location"].id,
                shift_id=d["shift"].id,
                effective_from=date(2024, 1, 1),
                is_active=True,
            )
            session.add(assignment)

        print(f"  ✓ {len(employees_data)} employees with devices + enrollments created")

        # ── Help categories ───────────────────────────────────────────────────
        categories = [
            "Location Error", "Face Recognition Failed", "GPS Problem", "Camera Problem",
            "App Error", "Internet / Sync Issue", "Wrong Assigned Location",
            "Permission Problem", "Attendance Missing", "Shift Timing Issue",
            "Device Changed", "Other",
        ]
        for cat in categories:
            session.add(HelpCategory(organization_id=org.id, name=cat, active=True))

        await session.commit()

    print("\n✅ Seed complete!")
    print("   Organization : FaceVault Operations (code: FVOPS)")
    print("   Admin login  : admin@facevault.io / Admin@1234")
    print("   Employee     : EMP-1042 / Employee@1234  (and EMP-1177, EMP-1320, EMP-1401, EMP-1528)")
    print("   Locations    : Sector 17, Depot 4, HQ Office")
    print("   Note         : All employees have Device + FaceEnrollment records (status=ENROLLED)")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(seed())
