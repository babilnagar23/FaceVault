"""Initial complete FaceVault schema.

Revision ID: 001
Revises: (none)
Create Date: 2026-09-29

This migration creates the ENTIRE production schema from scratch.
Run against an empty PostgreSQL database with PostGIS extension available.

Extensions enabled:
  - uuid-ossp  (UUID generation)
  - postgis     (geospatial)

Order: enums and extensions → core tables → dependent tables → indexes.
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic
revision: str = "001_initial_schema"
down_revision: str | None = None
branch_labels: str | tuple[str, ...] | None = None
depends_on: str | tuple[str, ...] | None = None


def upgrade() -> None:
    # ─────────────────────────────────────────────────────────────────────────
    # Extensions
    # ─────────────────────────────────────────────────────────────────────────
    op.execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")

    # ─────────────────────────────────────────────────────────────────────────
    # organizations
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "organizations",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("code", sa.String(50), nullable=False),
        sa.Column("domain", sa.String(255), nullable=True),
        sa.Column("logo_url", sa.Text, nullable=True),
        sa.Column("active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("timezone", sa.String(64), nullable=False, server_default="timezone.utc"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_organizations_code", "organizations", ["code"], unique=True)

    # ─────────────────────────────────────────────────────────────────────────
    # organization_settings
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "organization_settings",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, unique=True),
        # Geofence / GPS
        sa.Column("default_geofence_radius_meters", sa.Integer, nullable=False, server_default="150"),
        sa.Column("gps_accuracy_threshold_meters", sa.Integer, nullable=False, server_default="50"),
        # Attendance rules
        sa.Column("grace_period_minutes", sa.Integer, nullable=False, server_default="15"),
        sa.Column("late_threshold_minutes", sa.Integer, nullable=False, server_default="30"),
        sa.Column("checkin_window_hours", sa.Integer, nullable=False, server_default="2"),
        # Biometric thresholds
        sa.Column("face_match_threshold", sa.Float, nullable=False, server_default="0.85"),
        sa.Column("liveness_threshold", sa.Float, nullable=False, server_default="0.80"),
        sa.Column("minimum_face_quality", sa.Float, nullable=False, server_default="0.70"),
        # Offline
        sa.Column("offline_enabled", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("max_offline_days", sa.Integer, nullable=False, server_default="7"),
        # Retention
        sa.Column("biometric_retention_days", sa.Integer, nullable=False, server_default="0"),
        sa.Column("attendance_retention_days", sa.Integer, nullable=False, server_default="730"),
        # Notifications
        sa.Column("notify_on_late", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("notify_on_absent", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("notify_on_verification", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("notification_config", sa.JSON, nullable=True),
        sa.Column("extra", sa.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # ─────────────────────────────────────────────────────────────────────────
    # roles
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "roles",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(50), nullable=False),
        sa.Column("display_name", sa.String(100), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_roles_org", "roles", ["organization_id"])
    op.create_index("ix_roles_org_name", "roles", ["organization_id", "name"], unique=True)

    # ─────────────────────────────────────────────────────────────────────────
    # permissions
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "permissions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("code", sa.String(100), nullable=False, unique=True),
        sa.Column("description", sa.String(255), nullable=True),
    )
    op.create_index("ix_permissions_code", "permissions", ["code"], unique=True)

    # ─────────────────────────────────────────────────────────────────────────
    # departments
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "departments",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("code", sa.String(30), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_departments_org", "departments", ["organization_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # users
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("role_id", sa.String(36), sa.ForeignKey("roles.id", ondelete="SET NULL"), nullable=True),
        sa.Column("department_id", sa.String(36), sa.ForeignKey("departments.id", ondelete="SET NULL"), nullable=True),
        sa.Column("employee_code", sa.String(50), nullable=False),
        sa.Column("first_name", sa.String(100), nullable=False),
        sa.Column("last_name", sa.String(100), nullable=False),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("phone", sa.String(30), nullable=True),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="ACTIVE"),
        sa.Column("face_enrolled", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("device_registered", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("avatar_url", sa.String(500), nullable=True),
        sa.Column("manager_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("join_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_users_org", "users", ["organization_id"])
    op.create_index("ix_users_employee_code", "users", ["employee_code"])
    op.create_index("ix_users_email", "users", ["email"])
    op.create_index("ix_users_status", "users", ["status"])
    op.create_index("ix_users_org_employee_code", "users", ["organization_id", "employee_code"], unique=True)
    op.create_index("ix_users_org_email", "users", ["organization_id", "email"], unique=True)

    # ─────────────────────────────────────────────────────────────────────────
    # role_permissions
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "role_permissions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("role_id", sa.String(36), sa.ForeignKey("roles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("permission_id", sa.String(36), sa.ForeignKey("permissions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("role_id", "permission_id", name="uq_role_permission"),
    )
    op.create_index("ix_role_permissions_role", "role_permissions", ["role_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # consents
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "consents",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("type", sa.String(50), nullable=False),
        sa.Column("version", sa.String(20), nullable=False),
        sa.Column("accepted", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("accepted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("user_id", "type", name="uq_consent_user_type"),
    )
    op.create_index("ix_consents_user", "consents", ["user_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # projects
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "projects",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("code", sa.String(50), nullable=True),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_projects_org", "projects", ["organization_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # locations
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "locations",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("project_id", sa.String(36), sa.ForeignKey("projects.id", ondelete="SET NULL"), nullable=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("site_code", sa.String(50), nullable=True),
        sa.Column("address", sa.Text, nullable=True),
        sa.Column("active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("latitude", sa.Float, nullable=False),
        sa.Column("longitude", sa.Float, nullable=False),
        sa.Column("radius_meters", sa.Integer, nullable=False, server_default="150"),
        sa.Column("working_hours_start", sa.String(5), nullable=True),
        sa.Column("working_hours_end", sa.String(5), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_locations_org", "locations", ["organization_id"])
    op.create_index("ix_locations_org_active", "locations", ["organization_id", "active"])

    # PostGIS geography point column for spatial queries
    op.execute("""
        ALTER TABLE locations
        ADD COLUMN geo_point geography(Point, 4326)
        GENERATED ALWAYS AS (
            ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
        ) STORED
    """)
    op.execute("CREATE INDEX ix_locations_geo ON locations USING GIST (geo_point)")

    # ─────────────────────────────────────────────────────────────────────────
    # shifts
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "shifts",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("start_time", sa.String(5), nullable=False),
        sa.Column("end_time", sa.String(5), nullable=False),
        sa.Column("grace_period_minutes", sa.Integer, nullable=False, server_default="15"),
        sa.Column("late_threshold_minutes", sa.Integer, nullable=False, server_default="30"),
        sa.Column("working_days", sa.JSON, nullable=True),
        sa.Column("active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_shifts_org", "shifts", ["organization_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # assignments
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "assignments",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("project_id", sa.String(36), sa.ForeignKey("projects.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("location_id", sa.String(36), sa.ForeignKey("locations.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("shift_id", sa.String(36), sa.ForeignKey("shifts.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("effective_from", sa.Date, nullable=False),
        sa.Column("effective_to", sa.Date, nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_assignments_org", "assignments", ["organization_id"])
    op.create_index("ix_assignments_user", "assignments", ["user_id"])
    op.create_index("ix_assignments_user_active", "assignments", ["user_id", "is_active"])
    op.create_index("ix_assignments_location", "assignments", ["location_id"])
    op.create_index("ix_assignments_project", "assignments", ["project_id"])
    op.create_index("ix_assignments_shift", "assignments", ["shift_id"])
    op.create_index("ix_assignments_dates", "assignments", ["effective_from", "effective_to"])

    # ─────────────────────────────────────────────────────────────────────────
    # devices
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "devices",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("device_uuid", sa.String(100), nullable=False, unique=True),
        sa.Column("platform", sa.String(20), nullable=False),
        sa.Column("manufacturer", sa.String(100), nullable=True),
        sa.Column("model", sa.String(100), nullable=True),
        sa.Column("os_version", sa.String(50), nullable=True),
        sa.Column("app_version", sa.String(20), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="REGISTERED"),
        sa.Column("public_key", sa.Text, nullable=True),
        sa.Column("registered_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_sync_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_devices_uuid", "devices", ["device_uuid"], unique=True)
    op.create_index("ix_devices_user", "devices", ["user_id"])
    op.create_index("ix_devices_status", "devices", ["status"])

    # ─────────────────────────────────────────────────────────────────────────
    # user_sessions
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "user_sessions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("device_id", sa.String(36), sa.ForeignKey("devices.id", ondelete="SET NULL"), nullable=True),
        sa.Column("refresh_token_hash", sa.String(128), nullable=False, unique=True),
        sa.Column("is_revoked", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_session_user", "user_sessions", ["user_id"])
    op.create_index("ix_session_user_revoked", "user_sessions", ["user_id", "is_revoked"])
    op.create_index("ix_session_expires", "user_sessions", ["expires_at"])
    op.create_index("ix_session_token_hash", "user_sessions", ["refresh_token_hash"], unique=True)

    # ─────────────────────────────────────────────────────────────────────────
    # face_enrollments
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "face_enrollments",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("status", sa.String(30), nullable=False, server_default="NOT_ENROLLED"),
        sa.Column("model_version", sa.String(30), nullable=True),
        sa.Column("quality_score", sa.Float, nullable=True),
        sa.Column("liveness_score", sa.Float, nullable=True),
        sa.Column("enrolled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_face_enrollments_user", "face_enrollments", ["user_id"], unique=True)
    op.create_index("ix_face_enrollments_org", "face_enrollments", ["organization_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # face_templates
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "face_templates",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("enrollment_id", sa.String(36), sa.ForeignKey("face_enrollments.id", ondelete="CASCADE"), nullable=False),
        sa.Column("model_version", sa.String(30), nullable=False),
        sa.Column("quality_score", sa.Float, nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("created_at_device", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_face_templates_enrollment", "face_templates", ["enrollment_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # attendance_attempts
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "attendance_attempts",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("client_event_id", sa.String(100), nullable=False, unique=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=False),
        sa.Column("device_id", sa.String(36), sa.ForeignKey("devices.id", ondelete="SET NULL"), nullable=True),
        sa.Column("assignment_id", sa.String(36), sa.ForeignKey("assignments.id", ondelete="SET NULL"), nullable=True),
        sa.Column("project_id", sa.String(36), sa.ForeignKey("projects.id", ondelete="SET NULL"), nullable=True),
        sa.Column("location_id", sa.String(36), sa.ForeignKey("locations.id", ondelete="SET NULL"), nullable=True),
        sa.Column("shift_id", sa.String(36), sa.ForeignKey("shifts.id", ondelete="SET NULL"), nullable=True),
        sa.Column("event_type", sa.String(20), nullable=False, server_default="CHECK_IN"),
        sa.Column("attempt_number", sa.Integer, nullable=False, server_default="1"),
        sa.Column("client_timestamp", sa.DateTime(timezone=True), nullable=True),
        sa.Column("server_received_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("device_clock_offset_seconds", sa.Float, nullable=True),
        sa.Column("latitude", sa.Float, nullable=True),
        sa.Column("longitude", sa.Float, nullable=True),
        sa.Column("gps_accuracy_meters", sa.Float, nullable=True),
        sa.Column("distance_from_site_meters", sa.Float, nullable=True),
        sa.Column("face_verified", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("face_score", sa.Float, nullable=True),
        sa.Column("liveness_verified", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("liveness_score", sa.Float, nullable=True),
        sa.Column("location_verified", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("offline_created", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("network_type", sa.String(20), nullable=True),
        sa.Column("battery_level", sa.Integer, nullable=True),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("failure_reason", sa.Text, nullable=True),
        sa.Column("risk_flags", sa.JSON, nullable=True),
        sa.Column("event_signature", sa.Text, nullable=True),
        sa.Column("signature_algorithm", sa.String(30), nullable=True),
        sa.Column("metadata", sa.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("client_event_id", name="uq_attendance_attempt_event_id"),
    )
    op.create_index("ix_att_attempt_event_id", "attendance_attempts", ["client_event_id"], unique=True)
    op.create_index("ix_att_attempt_user_date", "attendance_attempts", ["user_id", "server_received_at"])
    op.create_index("ix_att_attempt_status", "attendance_attempts", ["status"])
    op.create_index("ix_att_attempt_org_date", "attendance_attempts", ["organization_id", "server_received_at"])
    op.create_index("ix_att_attempt_location", "attendance_attempts", ["location_id"])
    op.create_index("ix_att_attempt_device", "attendance_attempts", ["device_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # attendance_records
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "attendance_records",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=False),
        sa.Column("assignment_id", sa.String(36), sa.ForeignKey("assignments.id", ondelete="SET NULL"), nullable=True),
        sa.Column("project_id", sa.String(36), sa.ForeignKey("projects.id", ondelete="SET NULL"), nullable=True),
        sa.Column("location_id", sa.String(36), sa.ForeignKey("locations.id", ondelete="SET NULL"), nullable=True),
        sa.Column("shift_id", sa.String(36), sa.ForeignKey("shifts.id", ondelete="SET NULL"), nullable=True),
        sa.Column("attendance_date", sa.Date, nullable=False),
        sa.Column("check_in_attempt_id", sa.String(36), sa.ForeignKey("attendance_attempts.id", ondelete="SET NULL"), nullable=True),
        sa.Column("check_out_attempt_id", sa.String(36), sa.ForeignKey("attendance_attempts.id", ondelete="SET NULL"), nullable=True),
        sa.Column("check_in_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("check_out_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("source", sa.String(20), nullable=False, server_default="MOBILE"),
        sa.Column("work_duration_minutes", sa.Float, nullable=True),
        sa.Column("face_score", sa.Float, nullable=True),
        sa.Column("liveness_score", sa.Float, nullable=True),
        sa.Column("location_distance_meters", sa.Float, nullable=True),
        sa.Column("approved_by_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("approved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("remarks", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("user_id", "attendance_date", "shift_id", name="uq_attendance_record_daily"),
    )
    op.create_index("ix_att_record_user_date", "attendance_records", ["user_id", "attendance_date"])
    op.create_index("ix_att_record_status", "attendance_records", ["status"])
    op.create_index("ix_att_record_org_date", "attendance_records", ["organization_id", "attendance_date"])
    op.create_index("ix_att_record_location", "attendance_records", ["location_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # attendance_exceptions
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "attendance_exceptions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("attendance_attempt_id", sa.String(36), sa.ForeignKey("attendance_attempts.id", ondelete="CASCADE"), nullable=False),
        sa.Column("attendance_record_id", sa.String(36), sa.ForeignKey("attendance_records.id", ondelete="SET NULL"), nullable=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=False),
        sa.Column("status", sa.String(30), nullable=False, server_default="NEEDS_REVIEW"),
        sa.Column("reason", sa.Text, nullable=True),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column("reviewed_by_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("metadata", sa.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_att_exception_org_status", "attendance_exceptions", ["organization_id", "status"])
    op.create_index("ix_att_exception_user", "attendance_exceptions", ["user_id"])
    op.create_index("ix_att_exception_status", "attendance_exceptions", ["status"])

    # ─────────────────────────────────────────────────────────────────────────
    # announcements
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "announcements",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_by_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=False),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("category", sa.String(50), nullable=False),
        sa.Column("body", sa.Text, nullable=False),
        sa.Column("pinned", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("urgent", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("status", sa.String(20), nullable=False, server_default="DRAFT"),
        sa.Column("target_type", sa.String(20), nullable=False, server_default="all"),
        sa.Column("target_ids", sa.JSON, nullable=True),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("scheduled_for", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_announcements_org", "announcements", ["organization_id"])
    op.create_index("ix_announcements_status", "announcements", ["status"])
    op.create_index("ix_announcements_org_published", "announcements", ["organization_id", "published_at"])

    # ─────────────────────────────────────────────────────────────────────────
    # announcement_reads
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "announcement_reads",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("announcement_id", sa.String(36), sa.ForeignKey("announcements.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("read", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("acknowledged", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("acknowledged_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("announcement_id", "user_id", name="uq_announcement_read"),
    )
    op.create_index("ix_announcement_reads_ann", "announcement_reads", ["announcement_id"])
    op.create_index("ix_announcement_reads_user", "announcement_reads", ["user_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # notifications
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "notifications",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("type", sa.String(30), nullable=False),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("body", sa.Text, nullable=False),
        sa.Column("read", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("entity_type", sa.String(50), nullable=True),
        sa.Column("entity_id", sa.String(36), nullable=True),
        sa.Column("payload", sa.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_notification_user_read", "notifications", ["user_id", "read"])
    op.create_index("ix_notification_org", "notifications", ["organization_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # notification_reads
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "notification_reads",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("notification_id", sa.String(36), sa.ForeignKey("notifications.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("notification_id", "user_id", name="uq_notification_read"),
    )
    op.create_index("ix_notification_reads_notif", "notification_reads", ["notification_id"])
    op.create_index("ix_notification_read_user", "notification_reads", ["user_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # help_categories
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "help_categories",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_help_categories_org", "help_categories", ["organization_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # help_requests
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "help_requests",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=False),
        sa.Column("category_id", sa.String(36), sa.ForeignKey("help_categories.id", ondelete="SET NULL"), nullable=True),
        sa.Column("assigned_to_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("subject", sa.String(255), nullable=False),
        sa.Column("description", sa.Text, nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="OPEN"),
        sa.Column("priority", sa.String(20), nullable=False, server_default="NORMAL"),
        sa.Column("attendance_attempt_id", sa.String(36), sa.ForeignKey("attendance_attempts.id", ondelete="SET NULL"), nullable=True),
        sa.Column("device_id", sa.String(36), sa.ForeignKey("devices.id", ondelete="SET NULL"), nullable=True),
        sa.Column("app_version", sa.String(30), nullable=True),
        sa.Column("latitude", sa.Float, nullable=True),
        sa.Column("longitude", sa.Float, nullable=True),
        sa.Column("resolution", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_help_request_org_status", "help_requests", ["organization_id", "status"])
    op.create_index("ix_help_request_user", "help_requests", ["user_id"])
    op.create_index("ix_help_request_status", "help_requests", ["status"])

    # ─────────────────────────────────────────────────────────────────────────
    # help_comments
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "help_comments",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("request_id", sa.String(36), sa.ForeignKey("help_requests.id", ondelete="CASCADE"), nullable=False),
        sa.Column("author_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=False),
        sa.Column("body", sa.Text, nullable=False),
        sa.Column("is_system", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("is_internal", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_help_comments_request", "help_comments", ["request_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # help_attachments
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "help_attachments",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("request_id", sa.String(36), sa.ForeignKey("help_requests.id", ondelete="CASCADE"), nullable=False),
        sa.Column("uploaded_by_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=False),
        sa.Column("storage_key", sa.String(500), nullable=False),
        sa.Column("original_filename", sa.String(255), nullable=False),
        sa.Column("content_type", sa.String(100), nullable=False),
        sa.Column("size_bytes", sa.Integer, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_help_attachments_request", "help_attachments", ["request_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # sync_events
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "sync_events",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("client_event_id", sa.String(100), nullable=False, unique=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=False),
        sa.Column("device_id", sa.String(36), sa.ForeignKey("devices.id", ondelete="SET NULL"), nullable=True),
        sa.Column("entity_type", sa.String(50), nullable=False),
        sa.Column("operation", sa.String(20), nullable=False),
        sa.Column("client_created_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("server_received_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("server_processed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(30), nullable=False, server_default="PENDING"),
        sa.Column("rejection_reason", sa.Text, nullable=True),
        sa.Column("payload", sa.JSON, nullable=True),
        sa.Column("result_entity_id", sa.String(36), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("client_event_id", name="uq_sync_event_id"),
    )
    op.create_index("ix_sync_event_client_id", "sync_events", ["client_event_id"], unique=True)
    op.create_index("ix_sync_event_device_status", "sync_events", ["device_id", "status"])
    op.create_index("ix_sync_event_org_status", "sync_events", ["organization_id", "status"])

    # ─────────────────────────────────────────────────────────────────────────
    # sync_conflicts
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "sync_conflicts",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("sync_event_id", sa.String(36), sa.ForeignKey("sync_events.id", ondelete="CASCADE"), nullable=False),
        sa.Column("client_event_id", sa.String(100), nullable=False),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("reason", sa.Text, nullable=False),
        sa.Column("server_record_id", sa.String(36), nullable=True),
        sa.Column("server_state", sa.JSON, nullable=True),
        sa.Column("resolution", sa.String(30), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_sync_conflict_event_id", "sync_conflicts", ["client_event_id"])

    # ─────────────────────────────────────────────────────────────────────────
    # audit_logs
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "audit_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="SET NULL"), nullable=False),
        sa.Column("actor_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("actor_label", sa.String(255), nullable=True),
        sa.Column("action", sa.String(100), nullable=False),
        sa.Column("entity_type", sa.String(50), nullable=True),
        sa.Column("entity_id", sa.String(36), nullable=True),
        sa.Column("before_data", sa.JSON, nullable=True),
        sa.Column("after_data", sa.JSON, nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.Text, nullable=True),
        sa.Column("device_id", sa.String(36), nullable=True),
        sa.Column("details", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_audit_org_created", "audit_logs", ["organization_id", "created_at"])
    op.create_index("ix_audit_actor", "audit_logs", ["actor_id"])
    op.create_index("ix_audit_entity", "audit_logs", ["entity_type", "entity_id"])
    op.create_index("ix_audit_action", "audit_logs", ["action"])

    # ─────────────────────────────────────────────────────────────────────────
    # login_audit
    # ─────────────────────────────────────────────────────────────────────────
    op.create_table(
        "login_audit",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("organization_id", sa.String(36), sa.ForeignKey("organizations.id", ondelete="SET NULL"), nullable=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("identifier", sa.String(255), nullable=False),
        sa.Column("success", sa.Boolean, nullable=False),
        sa.Column("failure_reason", sa.String(100), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_login_audit_org_created", "login_audit", ["organization_id", "created_at"])
    op.create_index("ix_login_audit_user", "login_audit", ["user_id"])
    op.create_index("ix_login_audit_success", "login_audit", ["success"])


def downgrade() -> None:
    # Drop in reverse dependency order
    op.drop_table("login_audit")
    op.drop_table("audit_logs")
    op.drop_table("sync_conflicts")
    op.drop_table("sync_events")
    op.drop_table("help_attachments")
    op.drop_table("help_comments")
    op.drop_table("help_requests")
    op.drop_table("help_categories")
    op.drop_table("notification_reads")
    op.drop_table("notifications")
    op.drop_table("announcement_reads")
    op.drop_table("announcements")
    op.drop_table("attendance_exceptions")
    op.drop_table("attendance_records")
    op.drop_table("attendance_attempts")
    op.drop_table("face_templates")
    op.drop_table("face_enrollments")
    op.drop_table("user_sessions")
    op.drop_table("devices")
    op.drop_table("assignments")
    op.drop_table("shifts")
    op.drop_table("locations")
    op.drop_table("projects")
    op.drop_table("consents")
    op.drop_table("role_permissions")
    op.drop_table("users")
    op.drop_table("departments")
    op.drop_table("permissions")
    op.drop_table("roles")
    op.drop_table("organization_settings")
    op.drop_table("organizations")
    op.execute("DROP EXTENSION IF EXISTS postgis")
    op.execute("DROP EXTENSION IF EXISTS \"uuid-ossp\"")
