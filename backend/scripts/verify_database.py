from __future__ import annotations
#!/usr/bin/env python3
"""
FaceVault — Database Verification Script

Verifies that the PostgreSQL database is correctly configured:
  - Required extensions (postgis, uuid-ossp, btree_gist)
  - All expected tables exist
  - Critical constraints exist
  - PostGIS geo_point generated column on locations

Usage:
  cd backend
  python scripts/verify_database.py

Exit code 0 = all checks passed.
Exit code 1 = one or more checks failed.
"""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

from app.config import settings


EXPECTED_TABLES = [
    "organizations", "organization_settings",
    "roles", "permissions", "role_permissions",
    "users", "departments", "projects",
    "locations", "shifts", "assignments",
    "devices", "user_sessions", "login_audit",
    "attendance_attempts", "attendance_records", "attendance_exceptions",
    "face_enrollments", "face_templates",
    "sync_events", "announcements", "audit_logs",
    "help_categories", "help_tickets",
    "consents", "notifications",
]

EXPECTED_EXTENSIONS = ["postgis", "uuid-ossp", "btree_gist"]

EXPECTED_CONSTRAINTS = [
    # (constraint_name, table_name)
    ("uq_users_employee_code", "users"),
    ("uq_users_org_email", "users"),
    ("uq_attendance_record_daily", "attendance_records"),
    ("uq_attendance_attempt_event_id", "attendance_attempts"),
    ("uq_sync_event_id", "sync_events"),
    ("uq_face_enrollment_user", "face_enrollments"),
    ("uq_device_uuid", "devices"),
    ("uq_role_permission", "role_permissions"),
    ("uq_permissions_code", "permissions"),
    ("ck_location_latitude", "locations"),
    ("ck_location_longitude", "locations"),
    ("ck_location_radius", "locations"),
    ("ck_shift_times_different", "shifts"),
    ("ck_att_attempt_status", "attendance_attempts"),
    ("ck_att_record_status", "attendance_records"),
    ("ck_face_enrollment_status", "face_enrollments"),
    ("excl_assignment_no_overlap", "assignments"),
]


async def verify() -> bool:
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    ok = True
    failures: list[str] = []

    async with engine.connect() as conn:
        # ── Extensions ────────────────────────────────────────────────────────
        print("Checking extensions...")
        result = await conn.execute(text("SELECT extname FROM pg_extension"))
        installed = {row[0] for row in result}
        for ext in EXPECTED_EXTENSIONS:
            if ext in installed:
                print(f"  ✓ {ext}")
            else:
                print(f"  ✗ MISSING: {ext}")
                failures.append(f"Extension '{ext}' not installed")
                ok = False

        # ── Tables ────────────────────────────────────────────────────────────
        print("\nChecking tables...")
        result = await conn.execute(
            text("SELECT tablename FROM pg_tables WHERE schemaname = 'public'")
        )
        existing_tables = {row[0] for row in result}
        missing_tables = [t for t in EXPECTED_TABLES if t not in existing_tables]
        if missing_tables:
            for t in missing_tables:
                print(f"  ✗ MISSING table: {t}")
                failures.append(f"Table '{t}' not found")
            ok = False
        else:
            print(f"  ✓ All {len(EXPECTED_TABLES)} expected tables present")

        # ── Constraints ───────────────────────────────────────────────────────
        print("\nChecking constraints...")
        result = await conn.execute(
            text("""
                SELECT c.conname, t.relname
                FROM pg_constraint c
                JOIN pg_class t ON t.oid = c.conrelid
                WHERE t.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
            """)
        )
        existing_constraints = {(row[0], row[1]) for row in result}
        for name, table in EXPECTED_CONSTRAINTS:
            if (name, table) in existing_constraints:
                print(f"  ✓ {name} on {table}")
            else:
                print(f"  ✗ MISSING constraint: {name} on {table}")
                failures.append(f"Constraint '{name}' on '{table}' not found")
                ok = False

        # ── PostGIS geo_point column (generated column in locations) ──────────
        print("\nChecking PostGIS geo_point generated column...")
        try:
            result = await conn.execute(
                text("SELECT column_name FROM information_schema.columns WHERE table_name='locations' AND column_name='geo_point'")
            )
            geo_col = result.fetchone()
            if geo_col:
                print("  ✓ locations.geo_point column exists")
            else:
                print("  ⚠  locations.geo_point column not found (may need PostGIS generated column migration)")
        except Exception as exc:
            print(f"  ⚠  Could not check geo_point: {exc}")

        # ── Seeded data check ─────────────────────────────────────────────────
        print("\nChecking seed data...")
        try:
            result = await conn.execute(
                text("SELECT code FROM organizations WHERE code='FVOPS'")
            )
            org = result.fetchone()
            if org:
                print("  ✓ Demo organization 'FVOPS' seeded")
            else:
                print("  ⚠  Demo organization 'FVOPS' not found — run: python scripts/seed.py")
        except Exception as exc:
            print(f"  ⚠  Could not check seed data: {exc}")

    await engine.dispose()

    print()
    if ok:
        print("✅ All critical database checks PASSED")
    else:
        print(f"❌ {len(failures)} database check(s) FAILED:")
        for f in failures:
            print(f"   - {f}")

    return ok


if __name__ == "__main__":
    result = asyncio.run(verify())
    sys.exit(0 if result else 1)
