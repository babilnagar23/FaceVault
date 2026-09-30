# FaceVault — Database Schema Contracts

> **Technology stack**: PostgreSQL 16 + PostGIS 3.4 · SQLAlchemy 2.x async · asyncpg · Alembic
>
> **Migration**: `alembic upgrade head` from an empty database creates the entire schema.
>
> **Extensions enabled**: `uuid-ossp`, `postgis`

---

## Table Index

| Table | Purpose |
|---|---|
| [organizations](#organizations) | Tenant root |
| [organization_settings](#organization_settings) | Per-org configuration |
| [roles](#roles) | RBAC role definitions |
| [permissions](#permissions) | Permission code registry |
| [role_permissions](#role_permissions) | Role ↔ Permission many-to-many |
| [departments](#departments) | Org subdivisions |
| [users](#users) | All personnel |
| [consents](#consents) | User consent records |
| [user_sessions](#user_sessions) | Auth session + refresh token hashes |
| [projects](#projects) | Work projects |
| [locations](#locations) | Physical work sites (with PostGIS) |
| [shifts](#shifts) | Shift schedules |
| [assignments](#assignments) | User ↔ Project/Location/Shift mapping |
| [devices](#devices) | Registered mobile devices |
| [face_enrollments](#face_enrollments) | Biometric enrollment status |
| [face_templates](#face_templates) | Per-enrollment model metadata |
| [attendance_attempts](#attendance_attempts) | Raw event log (every attempt) |
| [attendance_records](#attendance_records) | Official attendance (one per shift/day) |
| [attendance_exceptions](#attendance_exceptions) | Exception review queue |
| [announcements](#announcements) | Org-wide announcements |
| [announcement_reads](#announcement_reads) | Read/acknowledge tracking |
| [notifications](#notifications) | Per-user push notifications |
| [notification_reads](#notification_reads) | FCM delivery tracking |
| [help_categories](#help_categories) | Help desk categories |
| [help_requests](#help_requests) | Support tickets |
| [help_comments](#help_comments) | Thread comments on tickets |
| [help_attachments](#help_attachments) | Metadata refs to S3/MinIO |
| [sync_events](#sync_events) | Offline sync queue |
| [sync_conflicts](#sync_conflicts) | Conflict resolution records |
| [audit_logs](#audit_logs) | Immutable audit trail |
| [login_audit](#login_audit) | Authentication attempt log |

---

## organizations

Root tenant table. Every other record belongs to an organization.

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK, UUID |
| name | varchar(255) | NOT NULL |
| code | varchar(50) | UNIQUE NOT NULL — e.g. `FVOPS` |
| domain | varchar(255) | nullable |
| logo_url | text | nullable |
| active | boolean | default TRUE |
| timezone | varchar(64) | default `UTC` — used for shift/date interpretation |
| created_at | timestamptz | server default now() |
| updated_at | timestamptz | server default now() |

**Indexes**: `ix_organizations_code` (UNIQUE)

---

## organization_settings

One-to-one with organizations. Created automatically with each org.

| Column | Type | Default | Notes |
|---|---|---|---|
| id | varchar(36) | PK | |
| organization_id | varchar(36) | FK → organizations | UNIQUE, CASCADE |
| default_geofence_radius_meters | integer | 150 | |
| gps_accuracy_threshold_meters | integer | 50 | |
| grace_period_minutes | integer | 15 | |
| late_threshold_minutes | integer | 30 | |
| checkin_window_hours | integer | 2 | |
| face_match_threshold | float | 0.85 | |
| liveness_threshold | float | 0.80 | |
| minimum_face_quality | float | 0.70 | |
| offline_enabled | boolean | true | |
| max_offline_days | integer | 7 | |
| biometric_retention_days | integer | 0 | 0 = keep forever |
| attendance_retention_days | integer | 730 | 2 years |
| notify_on_late | boolean | true | |
| notify_on_absent | boolean | true | |
| notify_on_verification | boolean | true | |
| notification_config | jsonb | null | |
| extra | jsonb | null | |

---

## roles

RBAC roles. Seeded roles: `OWNER`, `ADMIN`, `HR`, `MANAGER`, `SUPERVISOR`, `EMPLOYEE`.

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| name | varchar(50) | e.g. `ADMIN`, `EMPLOYEE` |
| display_name | varchar(100) | Human-readable |

**Constraints**: `ix_roles_org_name` UNIQUE `(organization_id, name)`

---

## permissions

Global permission code registry. Codes follow `resource.action` format.

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| code | varchar(100) | UNIQUE — e.g. `attendance.approve` |
| description | varchar(255) | Human description |

**Seeded permissions** (26): `attendance.view_own`, `attendance.view_team`, `attendance.view_org`, `attendance.approve`, `attendance.override`, `employees.view`, `employees.create`, `employees.edit`, `employees.deactivate`, `projects.manage`, `locations.manage`, `shifts.manage`, `assignments.manage`, `biometrics.enroll`, `biometrics.view_status`, `reports.view`, `reports.export`, `announcements.create`, `announcements.manage`, `helpdesk.view`, `helpdesk.manage`, `settings.view`, `settings.manage`, `devices.manage`, `audit.view`

---

## role_permissions

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| role_id | varchar(36) | FK → roles (CASCADE) |
| permission_id | varchar(36) | FK → permissions (CASCADE) |

**Constraints**: `uq_role_permission` UNIQUE `(role_id, permission_id)`

---

## departments

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| name | varchar(100) | NOT NULL |
| code | varchar(30) | nullable |

---

## users

Core personnel table. Passwords stored as Argon2id hashes.

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| role_id | varchar(36) | FK → roles (SET NULL) |
| department_id | varchar(36) | FK → departments (SET NULL) |
| employee_code | varchar(50) | NOT NULL |
| first_name | varchar(100) | NOT NULL |
| last_name | varchar(100) | NOT NULL |
| email | varchar(255) | NOT NULL |
| phone | varchar(30) | nullable |
| password_hash | varchar(255) | Argon2id hash — NEVER plain text |
| status | varchar(20) | `ACTIVE`, `INACTIVE`, `SUSPENDED` |
| face_enrolled | boolean | True only if `face_enrollments` record exists |
| device_registered | boolean | True only if `devices` record exists |
| avatar_url | varchar(500) | S3/MinIO URL |
| manager_id | varchar(36) | FK → users (SET NULL) — self-referential |
| join_date | timestamptz | nullable |
| last_login_at | timestamptz | nullable |

**Constraints**:
- `ix_users_org_employee_code` UNIQUE `(organization_id, employee_code)`
- `ix_users_org_email` UNIQUE `(organization_id, email)`

> ⚠️ **Never set `face_enrolled=True` or `device_registered=True` without a corresponding record.**

---

## consents

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| user_id | varchar(36) | FK → users (CASCADE) |
| type | varchar(50) | `BIOMETRIC`, `LOCATION`, `NOTIFICATION` |
| version | varchar(20) | Policy version string |
| accepted | boolean | |
| accepted_at | timestamptz | nullable |
| ip_address | varchar(45) | nullable |

**Constraints**: `uq_consent_user_type` UNIQUE `(user_id, type)`

---

## user_sessions

Auth sessions. Only refresh token **hashes** are stored.

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| user_id | varchar(36) | FK → users (CASCADE) |
| device_id | varchar(36) | FK → devices (SET NULL) |
| refresh_token_hash | varchar(128) | SHA-256 hex of raw token — NEVER raw token |
| is_revoked | boolean | default FALSE |
| expires_at | timestamptz | NOT NULL |
| last_used_at | timestamptz | nullable |
| ip_address | varchar(45) | nullable |
| user_agent | text | nullable |

---

## projects

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| name | varchar(255) | NOT NULL |
| code | varchar(50) | nullable |
| description | text | nullable |
| active | boolean | default TRUE |

---

## locations

Work sites with geospatial support.

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| project_id | varchar(36) | FK → projects (SET NULL), nullable |
| name | varchar(255) | NOT NULL |
| site_code | varchar(50) | nullable |
| address | text | nullable |
| active | boolean | default TRUE |
| latitude | float | NOT NULL — for frontend response |
| longitude | float | NOT NULL — for frontend response |
| radius_meters | integer | default 150 |
| working_hours_start | varchar(5) | e.g. `08:00` |
| working_hours_end | varchar(5) | e.g. `18:00` |
| **geo_point** | **geography(Point,4326)** | **GENERATED STORED** from lat/lon — for PostGIS spatial queries |

**Indexes**: `ix_locations_org_active`, `ix_locations_geo` (GIST on geo_point)

---

## shifts

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| name | varchar(100) | NOT NULL |
| start_time | varchar(5) | `HH:MM` format |
| end_time | varchar(5) | `HH:MM` format |
| grace_period_minutes | integer | default 15 |
| late_threshold_minutes | integer | default 30 |
| working_days | jsonb | `["Mon","Tue","Wed","Thu","Fri"]` |
| active | boolean | default TRUE |

---

## assignments

Links an employee to a project/location/shift for a date range.

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| user_id | varchar(36) | FK → users (CASCADE) |
| project_id | varchar(36) | FK → projects (RESTRICT) |
| location_id | varchar(36) | FK → locations (RESTRICT) |
| shift_id | varchar(36) | FK → shifts (RESTRICT) |
| effective_from | date | NOT NULL |
| effective_to | date | nullable — NULL means open-ended |
| is_active | boolean | default TRUE |

---

## devices

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| user_id | varchar(36) | FK → users (CASCADE) |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| device_uuid | varchar(100) | UNIQUE — app-generated |
| platform | varchar(20) | `android`, `ios` |
| manufacturer | varchar(100) | nullable |
| model | varchar(100) | nullable |
| os_version | varchar(50) | nullable |
| app_version | varchar(20) | nullable |
| status | varchar(20) | `REGISTERED`, `REVOKED`, `PENDING` |
| public_key | text | For future cryptographic signing |
| registered_at | timestamptz | NOT NULL |
| last_seen_at | timestamptz | nullable |
| last_sync_at | timestamptz | nullable |

---

## face_enrollments

Biometric enrollment **metadata only**. Embeddings never exposed via API.

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| user_id | varchar(36) | FK → users (CASCADE), UNIQUE |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| status | varchar(30) | `NOT_ENROLLED`, `ENROLLED`, `FAILED`, `REVOKED` |
| model_version | varchar(30) | nullable |
| quality_score | float | nullable |
| liveness_score | float | nullable |
| enrolled_at | timestamptz | nullable |
| last_updated_at | timestamptz | nullable |

---

## face_templates

Stores template metadata (not raw embeddings).

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| enrollment_id | varchar(36) | FK → face_enrollments (CASCADE) |
| model_version | varchar(30) | NOT NULL |
| quality_score | float | nullable |
| is_active | boolean | default TRUE |
| created_at_device | timestamptz | nullable |

---

## attendance_attempts

Raw event log — every biometric scan attempt stored here.

**Attempt statuses**: `VERIFIED`, `FACE_FAILED`, `LIVENESS_FAILED`, `LOCATION_FAILED`, `GPS_FAILED`, `DEVICE_INVALID`, `PENDING_REVIEW`

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| client_event_id | varchar(100) | UNIQUE — idempotency key from mobile |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| user_id | varchar(36) | FK → users (SET NULL) |
| device_id | varchar(36) | FK → devices (SET NULL), nullable |
| assignment_id | varchar(36) | FK → assignments (SET NULL), nullable |
| project_id | varchar(36) | FK → projects (SET NULL), nullable |
| location_id | varchar(36) | FK → locations (SET NULL), nullable |
| shift_id | varchar(36) | FK → shifts (SET NULL), nullable |
| event_type | varchar(20) | `CHECK_IN` or `CHECK_OUT` |
| attempt_number | integer | default 1 |
| client_timestamp | timestamptz | nullable — device-reported |
| server_received_at | timestamptz | NOT NULL — server UTC |
| device_clock_offset_seconds | float | nullable |
| latitude | float | nullable |
| longitude | float | nullable |
| gps_accuracy_meters | float | nullable |
| distance_from_site_meters | float | server-calculated |
| face_verified | boolean | default FALSE |
| face_score | float | nullable |
| liveness_verified | boolean | default FALSE |
| liveness_score | float | nullable |
| location_verified | boolean | server-calculated |
| offline_created | boolean | default FALSE |
| network_type | varchar(20) | nullable |
| battery_level | integer | nullable |
| status | varchar(30) | NOT NULL (see statuses above) |
| failure_reason | text | nullable |
| risk_flags | jsonb | nullable — list of flag strings |
| event_signature | text | nullable — future crypto signing |
| signature_algorithm | varchar(30) | nullable |
| metadata | jsonb | nullable |

---

## attendance_records

Official attendance — one record per user per shift per day.

**Official statuses**: `PRESENT`, `ABSENT`, `LATE`, `LEAVE`, `PENDING_REVIEW`, `APPROVED_EXCEPTION`, `REJECTED`

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| user_id | varchar(36) | FK → users (SET NULL) |
| assignment_id | varchar(36) | FK → assignments (SET NULL), nullable |
| project_id | varchar(36) | FK → projects (SET NULL), nullable |
| location_id | varchar(36) | FK → locations (SET NULL), nullable |
| shift_id | varchar(36) | FK → shifts (SET NULL), nullable |
| attendance_date | date | NOT NULL |
| check_in_attempt_id | varchar(36) | FK → attendance_attempts (SET NULL) |
| check_out_attempt_id | varchar(36) | FK → attendance_attempts (SET NULL) |
| check_in_time | timestamptz | nullable |
| check_out_time | timestamptz | nullable |
| status | varchar(30) | NOT NULL (see statuses above) |
| source | varchar(20) | `MOBILE`, `ADMIN`, `SYSTEM` |
| work_duration_minutes | float | nullable |
| face_score | float | nullable |
| liveness_score | float | nullable |
| location_distance_meters | float | nullable |
| approved_by_id | varchar(36) | FK → users (SET NULL) |
| approved_at | timestamptz | nullable |
| remarks | text | nullable |

**Constraints**: `uq_attendance_record_daily` UNIQUE `(user_id, attendance_date, shift_id)`

---

## attendance_exceptions

Exception review queue.

**Statuses**: `NEEDS_REVIEW`, `PENDING_EXPLANATION`, `APPROVED`, `REJECTED`

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| attendance_attempt_id | varchar(36) | FK → attendance_attempts (CASCADE) |
| attendance_record_id | varchar(36) | FK → attendance_records (SET NULL), nullable |
| user_id | varchar(36) | FK → users (SET NULL) |
| status | varchar(30) | default `NEEDS_REVIEW` |
| reason | text | nullable |
| notes | text | nullable |
| reviewed_by_id | varchar(36) | FK → users (SET NULL) |
| reviewed_at | timestamptz | nullable |
| metadata | jsonb | nullable |

**Indexes**: `ix_att_exception_org_status` `(organization_id, status)`

---

## announcements

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| created_by_id | varchar(36) | FK → users (SET NULL) |
| title | varchar(255) | NOT NULL |
| category | varchar(50) | NOT NULL |
| body | text | NOT NULL |
| pinned | boolean | default FALSE |
| urgent | boolean | default FALSE |
| status | varchar(20) | `DRAFT`, `SCHEDULED`, `PUBLISHED`, `ARCHIVED` |
| target_type | varchar(20) | `all`, `department`, `project`, `location`, `selected` |
| target_ids | jsonb | nullable — IDs of targeted entities |
| published_at | timestamptz | nullable |
| scheduled_for | timestamptz | nullable |

---

## announcement_reads

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| announcement_id | varchar(36) | FK → announcements (CASCADE) |
| user_id | varchar(36) | FK → users (CASCADE) |
| read | boolean | default TRUE |
| acknowledged | boolean | default FALSE |
| read_at | timestamptz | nullable |
| acknowledged_at | timestamptz | nullable |

**Constraints**: `uq_announcement_read` UNIQUE `(announcement_id, user_id)`

---

## notifications

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| user_id | varchar(36) | FK → users (CASCADE) |
| type | varchar(30) | `attendance`, `announcement`, `help`, `shift`, `system`, `verification` |
| title | varchar(255) | NOT NULL |
| body | text | NOT NULL |
| read | boolean | default FALSE |
| entity_type | varchar(50) | nullable |
| entity_id | varchar(36) | nullable |
| payload | jsonb | nullable — FCM push data |

---

## notification_reads

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| notification_id | varchar(36) | FK → notifications (CASCADE) |
| user_id | varchar(36) | FK → users (CASCADE) |
| read_at | timestamptz | nullable |

**Constraints**: `uq_notification_read` UNIQUE `(notification_id, user_id)`

---

## help_categories

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| name | varchar(100) | NOT NULL |
| active | boolean | default TRUE |

---

## help_requests

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| user_id | varchar(36) | FK → users (SET NULL) |
| category_id | varchar(36) | FK → help_categories (SET NULL), nullable |
| assigned_to_id | varchar(36) | FK → users (SET NULL), nullable |
| subject | varchar(255) | NOT NULL |
| description | text | NOT NULL |
| status | varchar(20) | `OPEN`, `IN_PROGRESS`, `PENDING_USER`, `RESOLVED`, `CLOSED` |
| priority | varchar(20) | `LOW`, `NORMAL`, `HIGH`, `URGENT` |
| attendance_attempt_id | varchar(36) | FK → attendance_attempts (SET NULL), nullable |
| device_id | varchar(36) | FK → devices (SET NULL), nullable |
| app_version | varchar(30) | nullable |
| latitude | float | nullable — user location at submission |
| longitude | float | nullable |
| resolution | text | nullable |

**Indexes**: `ix_help_request_org_status` `(organization_id, status)`

---

## help_comments

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| request_id | varchar(36) | FK → help_requests (CASCADE) |
| author_id | varchar(36) | FK → users (SET NULL) |
| body | text | NOT NULL |
| is_system | boolean | Auto-generated system messages |
| is_internal | boolean | Admin-only notes |

---

## help_attachments

Binary files stored in S3/MinIO; only metadata in PostgreSQL.

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| request_id | varchar(36) | FK → help_requests (CASCADE) |
| uploaded_by_id | varchar(36) | FK → users (SET NULL) |
| storage_key | varchar(500) | S3/MinIO object key |
| original_filename | varchar(255) | NOT NULL |
| content_type | varchar(100) | NOT NULL |
| size_bytes | integer | nullable |

---

## sync_events

Offline event queue. `client_event_id` provides idempotency.

**Statuses**: `PENDING`, `PROCESSING`, `ACCEPTED`, `REJECTED`, `CONFLICT`

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| client_event_id | varchar(100) | UNIQUE — idempotency key |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| user_id | varchar(36) | FK → users (SET NULL) |
| device_id | varchar(36) | FK → devices (SET NULL), nullable |
| entity_type | varchar(50) | e.g. `attendance_attempt` |
| operation | varchar(20) | `create`, `update`, `delete` |
| client_created_at | timestamptz | nullable |
| server_received_at | timestamptz | NOT NULL |
| server_processed_at | timestamptz | nullable |
| status | varchar(30) | default `PENDING` |
| rejection_reason | text | nullable |
| payload | jsonb | nullable |
| result_entity_id | varchar(36) | Created entity ID if accepted |

---

## sync_conflicts

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| sync_event_id | varchar(36) | FK → sync_events (CASCADE) |
| client_event_id | varchar(100) | NOT NULL |
| organization_id | varchar(36) | FK → organizations (CASCADE) |
| reason | text | NOT NULL |
| server_record_id | varchar(36) | nullable |
| server_state | jsonb | nullable — snapshot at conflict |
| resolution | varchar(30) | `SERVER_WINS`, `CLIENT_WINS`, `MANUAL` |

---

## audit_logs

Immutable audit trail. Records are never deleted. Passwords/tokens are never logged.

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (SET NULL) |
| actor_id | varchar(36) | FK → users (SET NULL), nullable |
| actor_label | varchar(255) | Display name snapshot |
| action | varchar(100) | NOT NULL |
| entity_type | varchar(50) | nullable |
| entity_id | varchar(36) | nullable |
| before_data | jsonb | nullable |
| after_data | jsonb | nullable |
| ip_address | varchar(45) | nullable |
| user_agent | text | nullable |
| device_id | varchar(36) | nullable |
| details | text | nullable |

**Indexes**: `ix_audit_org_created` `(organization_id, created_at)`, `ix_audit_actor`

---

## login_audit

High-volume authentication attempt log.

| Column | Type | Notes |
|---|---|---|
| id | varchar(36) | PK |
| organization_id | varchar(36) | FK → organizations (SET NULL), nullable |
| user_id | varchar(36) | FK → users (SET NULL), nullable |
| identifier | varchar(255) | Employee code or email used — never a password |
| success | boolean | NOT NULL |
| failure_reason | varchar(100) | nullable |
| ip_address | varchar(45) | nullable |
| user_agent | text | nullable |

---

## FK ondelete behavior summary

| Pattern | Used for |
|---|---|
| `CASCADE` | Child records are meaningless without parent (org → settings, user → sessions/consents) |
| `SET NULL` | Child records retain historical value (attendance records after user deactivation) |
| `RESTRICT` | Prevents deletion if children exist (assignment → project/location/shift) |

> **Never cascade-delete attendance history or audit logs.** Employees should be deactivated (status=INACTIVE), not deleted.

---

## Deployment checklist

```bash
# 1. Start infrastructure
docker compose up -d postgres redis minio

# 2. Apply migrations to empty DB
cd backend
alembic upgrade head

# 3. Seed demo data
python scripts/seed.py

# 4. (Optional) Create additional admin
python scripts/create_admin.py --org FVOPS --email admin@example.com --password MyP@ss123

# 5. Run tests
pytest -m "unit or api"          # Fast tests (SQLite)
pytest -m integration            # PostgreSQL constraint tests

# 6. Start API
uvicorn app.main:app --reload

# 7. Verify
curl http://localhost:8000/health
curl http://localhost:8000/ready
```
