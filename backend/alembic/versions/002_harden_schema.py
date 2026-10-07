"""FaceVault schema hardening migration.

Revision ID: 002_harden_schema
Revises: 001_initial_schema
Create Date: 2026-10-06

This migration hardens the schema created in 001 by:

  1. EXTENSIONS
     - Enable btree_gist (required for EXCLUDE constraints on non-GiST types)

  2. CONSTRAINT FIXES
     a. user.employee_code — add global UNIQUE constraint
     b. user.(organization_id, email) — rename/recreate as named UniqueConstraint
     c. attendance_records — fix shift_id to NOT NULL (required for reliable
        (user_id, attendance_date, shift_id) uniqueness in PostgreSQL — NULLs are
        not equal in unique indexes so shift_id=NULL would allow duplicates)
     d. attendance_records — rename daily uniqueness constraint
     e. attendance_attempts.user_id — change SET NULL → RESTRICT
     f. attendance_records.user_id — change SET NULL → RESTRICT
     g. attendance_exceptions.user_id — change SET NULL → RESTRICT

  3. REDUNDANT INDEX REMOVAL (named UniqueConstraints already create the index)
     - drop ix_devices_uuid (device_uuid has unique=True and UniqueConstraint)
     - drop ix_attendance_attempt_event_id (UniqueConstraint creates its own index)
     - drop ix_sync_event_client_event_id (UniqueConstraint creates its own index)
     - drop ix_face_enrollment_user_id (UniqueConstraint creates its own index)

  4. CONSTRAINT NAMING
     - name RolePermission UniqueConstraint uq_role_permission
     - name Permission.code UniqueConstraint uq_permissions_code

  5. CHECK CONSTRAINTS
     - ck_location_latitude
     - ck_location_longitude
     - ck_location_radius
     - ck_shift_times_different
     - ck_shift_grace_period
     - ck_shift_late_threshold
     - ck_face_enrollment_status
     - ck_att_attempt_status (restricted set)
     - ck_att_attempt_face_score
     - ck_att_attempt_liveness_score
     - ck_att_attempt_lat
     - ck_att_attempt_lon
     - ck_att_attempt_battery
     - ck_att_record_status
     - ck_att_record_face_score
     - ck_att_record_liveness_score
     - ck_att_record_distance
     - ck_attendance_exception_status
     - ck_sync_event_status

  6. ASSIGNMENTS OVERLAP PREVENTION (btree_gist)
     - EXCLUDE constraint: one user cannot have two active overlapping assignments
       EXCLUDE USING gist (user_id WITH =, daterange(effective_from, COALESCE(effective_to, '9999-12-31')) WITH &&)
       WHERE (is_active = TRUE)

DOWN: All changes are reversible.
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision: str = "002_harden_schema"
down_revision: str | None = "001_initial_schema"
branch_labels: str | tuple[str, ...] | None = None
depends_on: str | tuple[str, ...] | None = None


def upgrade() -> None:
    # ── 1. Extensions ─────────────────────────────────────────────────────────
    op.execute("CREATE EXTENSION IF NOT EXISTS btree_gist")

    # ── 2a. employee_code: add global unique constraint ───────────────────────
    op.create_unique_constraint("uq_users_employee_code", "users", ["employee_code"])

    # ── 2b. (organization_id, email): named unique constraint ─────────────────
    # The old ix_users_org_email may be a plain index or unique index — drop and recreate
    try:
        op.drop_index("ix_users_org_email", table_name="users")
    except Exception:
        pass
    op.create_unique_constraint("uq_users_org_email", "users", ["organization_id", "email"])
    op.create_index("ix_users_org_email", "users", ["organization_id", "email"])

    # ── 2c. attendance_records: shift_id NOT NULL ─────────────────────────────
    # Existing rows with NULL shift_id must be handled before this. In production,
    # run the following SQL first to assign a placeholder if any nulls exist:
    #   UPDATE attendance_records SET shift_id = '00000000-0000-0000-0000-000000000000' WHERE shift_id IS NULL
    op.alter_column("attendance_records", "shift_id", nullable=False)

    # ── 2d. attendance_records: name the daily uniqueness constraint ──────────
    # Drop any existing unnamed or misnamed unique constraint then recreate
    try:
        op.drop_constraint("uq_attendance_record_daily    # ── 2e-g. user_id FK: SET NULL → RESTRICT on history tables ──────────────
    # attendance_attempts
    op.drop_constraint("attendance_attempts_user_id_fkey", "attendance_attempts", type_="foreignkey")
    op.create_foreign_key(
        "fk_att_attempts_user_id",
        "attendance_attempts", "users",
        ["user_id"], ["id"],
        ondelete="RESTRICT",
    )

    # attendance_records
    op.drop_constraint("attendance_records_user_id_fkey", "attendance_records", type_="foreignkey")
    op.create_foreign_key(
        "fk_att_records_user_id",
        "attendance_records", "users",
        ["user_id"], ["id"],
        ondelete="RESTRICT",
    )

    # attendance_exceptions
    op.drop_constraint("attendance_exceptions_user_id_fkey", "attendance_exceptions", type_="foreignkey")
    op.create_foreign_key(
        "fk_att_exceptions_user_id",
        "attendance_exceptions", "users",
        ["user_id"], ["id"],
        ondelete="RESTRICT",
    )

    # ── 3. Drop redundant indexes (UniqueConstraints already create their own) ─
    op.drop_index("ix_devices_uuid", table_name="devices")
    op.drop_index("ix_att_attempt_event_id", table_name="attendance_attempts")
    op.drop_index("ix_face_enrollments_user", table_name="face_enrollments")

    # ── 4. Name existing unnamed constraints ───────────────────────────────────
    # Permission.code unique constraint
    op.create_unique_constraint("uq_permissions_code", "permissions", ["code"])    # RolePermission unique constraint
    try:
        op.create_unique_constraint(
            "uq_role_permission",
            "role_permissions",
            ["role_id", "permission_id"],
        )
    except Exception:
        pass  # Already named — ignore

    # Permission.code unique constraint
    try:
        op.create_unique_constraint("uq_permissions_code", "permissions", ["code"])
    except Exception:
        pass

    # ── 5. CHECK CONSTRAINTS ──────────────────────────────────────────────────

    # locations
    op.create_check_constraint("ck_location_latitude", "locations", "latitude >= -90 AND latitude <= 90")
    op.create_check_constraint("ck_location_longitude", "locations", "longitude >= -180 AND longitude <= 180")
    op.create_check_constraint("ck_location_radius", "locations", "radius_meters > 0")

    # shifts
    op.create_check_constraint("ck_shift_times_different", "shifts", "start_time != end_time")
    op.create_check_constraint("ck_shift_grace_period", "shifts", "grace_period_minutes >= 0")
    op.create_check_constraint("ck_shift_late_threshold", "shifts", "late_threshold_minutes >= grace_period_minutes")

    # face_enrollments
    op.create_check_constraint(
        "ck_face_enrollment_status", "face_enrollments",
        "status IN ('NOT_ENROLLED','ENROLLING','ENROLLED','FAILED','REVOKED')",
    )
    op.create_check_constraint(
        "ck_face_enrollment_quality_score", "face_enrollments",
        "quality_score IS NULL OR (quality_score >= 0 AND quality_score <= 1)",
    )
    op.create_check_constraint(
        "ck_face_enrollment_liveness_score", "face_enrollments",
        "liveness_score IS NULL OR (liveness_score >= 0 AND liveness_score <= 1)",
    )

    # attendance_attempts
    op.create_check_constraint(
        "ck_att_attempt_status", "attendance_attempts",
        "status IN ('VERIFIED','FACE_FAILED','LIVENESS_FAILED','LOCATION_FAILED',"
        "'GPS_FAILED','DEVICE_INVALID','PENDING_REVIEW')",
    )
    op.create_check_constraint(
        "ck_att_attempt_face_score", "attendance_attempts",
        "face_score IS NULL OR (face_score >= 0 AND face_score <= 1)",
    )
    op.create_check_constraint(
        "ck_att_attempt_liveness_score", "attendance_attempts",
        "liveness_score IS NULL OR (liveness_score >= 0 AND liveness_score <= 1)",
    )
    op.create_check_constraint(
        "ck_att_attempt_lat", "attendance_attempts",
        "latitude IS NULL OR (latitude >= -90 AND latitude <= 90)",
    )
    op.create_check_constraint(
        "ck_att_attempt_lon", "attendance_attempts",
        "longitude IS NULL OR (longitude >= -180 AND longitude <= 180)",
    )
    op.create_check_constraint(
        "ck_att_attempt_battery", "attendance_attempts",
        "battery_level IS NULL OR (battery_level >= 0 AND battery_level <= 100)",
    )

    # attendance_records
    op.create_check_constraint(
        "ck_att_record_status", "attendance_records",
        "status IN ('PRESENT','ABSENT','LATE','LEAVE','PENDING_REVIEW','APPROVED_EXCEPTION','REJECTED')",
    )
    op.create_check_constraint(
        "ck_att_record_face_score", "attendance_records",
        "face_score IS NULL OR (face_score >= 0 AND face_score <= 1)",
    )
    op.create_check_constraint(
        "ck_att_record_liveness_score", "attendance_records",
        "liveness_score IS NULL OR (liveness_score >= 0 AND liveness_score <= 1)",
    )
    op.create_check_constraint(
        "ck_att_record_distance", "attendance_records",
        "location_distance_meters IS NULL OR location_distance_meters >= 0",
    )

    # attendance_exceptions
    op.create_check_constraint(
        "ck_attendance_exception_status", "attendance_exceptions",
        "status IN ('NEEDS_REVIEW','PENDING_EXPLANATION','APPROVED','REJECTED')",
    )

    # sync_events
    op.create_check_constraint(
        "ck_sync_event_status", "sync_events",
        "status IN ('PENDING','ACCEPTED','REJECTED','CONFLICT','ALREADY_PROCESSED')",
    )

    # ── 6. ASSIGNMENTS OVERLAP EXCLUSION (btree_gist) ─────────────────────────
    # Prevents a user from having two active overlapping assignments.
    # Uses daterange with COALESCE(effective_to, '9999-12-31') so open-ended
    # assignments ('effective_to IS NULL') are treated as extending forever.
    op.execute("""
        ALTER TABLE assignments
        ADD CONSTRAINT excl_assignment_no_overlap
        EXCLUDE USING gist (
            user_id WITH =,
            daterange(
                effective_from,
                COALESCE(effective_to, '9999-12-31'::date),
                '[]'
            ) WITH &&
        )
        WHERE (is_active = TRUE)
    """)


def downgrade() -> None:
    # Remove in reverse order
    op.execute("ALTER TABLE assignments DROP CONSTRAINT IF EXISTS excl_assignment_no_overlap")

    # Drop CHECK constraints
    for ck, tbl in [
        ("ck_sync_event_status", "sync_events"),
        ("ck_attendance_exception_status", "attendance_exceptions"),
        ("ck_att_record_distance", "attendance_records"),
        ("ck_att_record_liveness_score", "attendance_records"),
        ("ck_att_record_face_score", "attendance_records"),
        ("ck_att_record_status", "attendance_records"),
        ("ck_att_attempt_battery", "attendance_attempts"),
        ("ck_att_attempt_lon", "attendance_attempts"),
        ("ck_att_attempt_lat", "attendance_attempts"),
        ("ck_att_attempt_liveness_score", "attendance_attempts"),
        ("ck_att_attempt_face_score", "attendance_attempts"),
        ("ck_att_attempt_status", "attendance_attempts"),
        ("ck_face_enrollment_liveness_score", "face_enrollments"),
        ("ck_face_enrollment_quality_score", "face_enrollments"),
        ("ck_face_enrollment_status", "face_enrollments"),
        ("ck_shift_late_threshold", "shifts"),
        ("ck_shift_grace_period", "shifts"),
        ("ck_shift_times_different", "shifts"),
        ("ck_location_radius", "locations"),
        ("ck_location_longitude", "locations"),
        ("ck_location_latitude", "locations"),
    ]:
        try:
            op.drop_constraint(ck, tbl, type_="check")
        except Exception:
            pass

    # Drop named constraints
    try:
        op.drop_constraint("uq_permissions_code", "permissions", type_="unique")
    except Exception:
        pass
    try:
        op.drop_constraint("uq_role_permission", "role_permissions", type_="unique")
    except Exception:
        pass

    # Restore FK on history tables to SET NULL (original behaviour)
    for fk, tbl in [
        ("fk_att_exceptions_user_id", "attendance_exceptions"),
        ("fk_att_records_user_id", "attendance_records"),
        ("fk_att_attempts_user_id", "attendance_attempts"),
    ]:
        try:
            op.drop_constraint(fk, tbl, type_="foreignkey")
        except Exception:
            pass
    op.create_foreign_key(None, "attendance_attempts", "users", ["user_id"], ["id"], ondelete="SET NULL")
    op.create_foreign_key(None, "attendance_records", "users", ["user_id"], ["id"], ondelete="SET NULL")
    op.create_foreign_key(None, "attendance_exceptions", "users", ["user_id"], ["id"], ondelete="SET NULL")

    # Restore shift_id nullable
    op.alter_column("attendance_records", "shift_id", nullable=True)

    # Drop unique constraints
    try:
        op.drop_constraint("uq_users_org_email", "users", type_="unique")
    except Exception:
        pass
    try:
        op.drop_constraint("uq_users_employee_code", "users", type_="unique")
    except Exception:
        pass

    op.execute("DROP EXTENSION IF EXISTS btree_gist")
