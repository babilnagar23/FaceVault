# FaceVault Phase 1-3 Implementation Checklist

## Overview

Implementing Phase 1 (Reliable Database), Phase 2 (Backend Service/Repository Architecture),
and Phase 3 (Real Authentication) for the FaceVault repository.

---

## Current Problems Found (Pre-Implementation Audit)

### PHASE 1 — Database Issues

| # | Problem | Severity | File |
|---|---------|----------|------|
| 1.1 | CORS_ORIGINS: str but validator returns list[str] — type mismatch | HIGH | app/config.py |
| 1.2 | session.id used in JWT before INSERT is committed — not yet materialized | CRITICAL | app/api/v1/auth.py:61 |
| 1.3 | user_id SET NULL + nullable=False on attendance_attempts | HIGH | attendance_attempt.py:32 |
| 1.4 | user_id SET NULL + nullable=False on attendance_records | HIGH | attendance_record.py:27 |
| 1.5 | user_id SET NULL + nullable=False on attendance_exceptions | HIGH | attendance_exception.py:23 |
| 1.6 | permissions.code has unique=True + explicit unique index redundant | MEDIUM | 001_initial_schema.py |
| 1.7 | devices.device_uuid has unique=True + ix_devices_uuid index redundant | MEDIUM | device.py |
| 1.9 | face_enrollments.user_id has unique=True + index=True redundant | MEDIUM | face_enrollment.py |
| 1.10 | attendance_attempts.client_event_id triple redundant uniqueness | HIGH | attendance_attempt.py |
| 1.11 | sync_events.client_event_id triple redundant uniqueness | HIGH | sync_event.py |
| 1.12 | RolePermission UniqueConstraint is unnamed | MEDIUM | permission.py |
| 1.13 | attendance_records daily uniqueness broken when shift_id is NULL | CRITICAL | attendance_record.py |
| 1.14 | employee_code is not globally unique — ambiguous mobile login | CRITICAL | user.py |
| 1.15 | No timezone validation for organization.timezone | MEDIUM | organization.py |
| 1.16 | No coordinate CHECK constraints (latitude, longitude, radius) | HIGH | migration |
| 1.17 | No biometric score CHECK constraints (0-1 range) | MEDIUM | migration |
| 1.19 | No overlapping assignment exclusion constraint (btree_gist) | HIGH | migration |
| 1.20 | Seed creates FaceEnrollment(status="ENROLLED") with no real template | CRITICAL | scripts/seed.py |
| 1.21 | Seed not fully transactional | HIGH | scripts/seed.py |
| 1.22 | Integration tests use Base.metadata.create_all() not Alembic | HIGH | tests/conftest.py |
| 1.25 | btree_gist extension not enabled in migration | HIGH | migration |

### PHASE 2 — Architecture Issues

| # | Problem | Severity |
|---|---------|----------|
| 2.1 | All business logic in routers — no services/ or repositories/ | CRITICAL |
| 2.2 | require_permission() reads static ROLE_DEFAULT_PERMISSIONS — not DB-driven | CRITICAL |
| 2.3 | Two incompatible permission vocabularies | HIGH |
| 2.4 | Refresh endpoint looks up session by user_id not sid | CRITICAL |
| 2.5 | Refresh doesn't rotate token — returns same refresh token | CRITICAL |
| 2.6 | Logout revokes ALL user sessions, not just current | HIGH |
| 2.7 | No LoginAudit records written in auth flow | HIGH |
| 2.8 | session.id used in JWT before flush | CRITICAL |
| 2.9 | /sync/push marks ACCEPTED without processing attendance | CRITICAL |
| 2.10 | No AssignmentService.get_effective_assignment() | HIGH |
| 2.11 | No timezone-aware attendance date calculation | HIGH |

### PHASE 3 — Authentication Issues

| # | Problem | Severity |
|---|---------|----------|
| 3.1 | authApiProvider uses MockAuthApi() in production | CRITICAL |
| 3.2 | RemoteAuthApi stores tokens in Dio headers only — not secure storage | CRITICAL |
| 3.3 | currentEmployeeIdProvider hardcodes 'EMP-1042' | CRITICAL |
| 3.4 | Dio baseUrl hardcoded to production example URL | HIGH |
| 3.5 | No auth interceptor for automatic token refresh | HIGH |
| 3.6 | No offline session restore logic | HIGH |
| 3.7 | Admin session in sessionStorage via Zustand | HIGH |
| 3.8 | No Next.js BFF route handlers for httpOnly cookies | HIGH |
| 3.9 | create_access_token missing sid claim | HIGH |

---

## Implementation Status

### Phase 1
- [x] 1.1 Fix CORS_ORIGINS type
- [x] 1.2/2.8 Fix session.id UUID materialization (explicit UUID before JWT)
- [x] 1.3-1.5 Fix SET NULL + NOT NULL contradictions (use RESTRICT for history)
- [x] 1.6-1.11 Remove redundant unique indexes
- [x] 1.12 Name all constraints
- [x] 1.13 Fix attendance daily uniqueness (shift_id NOT NULL)
- [x] 1.14 Make employee_code globally unique
- [x] 1.15 Add timezone validation
- [x] 1.16-1.17 Add coordinate and score CHECK constraints
- [x] 1.19 Add overlapping assignment exclusion (btree_gist)
- [x] 1.20 Fix seed biometric state (NOT_ENROLLED)
- [x] 1.21 Make seed fully transactional
- [x] 1.22 Fix integration tests to use Alembic
- [x] Create 002_harden_schema migration
- [x] Create verify_database.py script

### Phase 2
- [x] Unify permission vocabulary (dotted codes)
- [x] Create repositories/
- [x] Create services/
- [x] Implement DB-driven RBAC
- [x] Fix auth flow (session ID, token rotation, sid-based logout)
- [x] Write LoginAudit records
- [x] Add sid to access token
- [x] Implement SyncService that actually dispatches to AttendanceService
- [x] Implement AssignmentService with effective-date logic
- [x] Implement timezone-aware attendance dates
- [x] Thin routers

### Phase 3
- [x] Create AuthSessionManager (secure storage)
- [x] Create Dio auth interceptor with refresh
- [x] Wire RemoteAuthApi in production provider
- [x] Remove hardcoded EMP-1042
- [x] Configure API base URL via dart-define
- [x] Implement offline session restore
- [x] Create Next.js BFF auth routes
- [x] Admin httpOnly cookie sessions
- [x] Admin logout

---

## Tests Executed

_(Updated as tests are run)_

---

## Known Remaining Work (Phase 4+)

- Camera wiring and real face detection integration
- Real GPS attendance with live location  
- Offline attendance outbox sync
- FCM push notifications
- Full admin business modules
- Complete biometric enrollment flow
- Production deployment configuration
