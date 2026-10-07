"""Import all models so Alembic can discover them."""
from __future__ import annotations
# ── Core ─────────────────────────────────────────────────────────────────────
from app.db.models.organization import Organization  # noqa: F401
from app.db.models.organization_settings import OrganizationSettings  # noqa: F401
from app.db.models.role import Role  # noqa: F401
from app.db.models.permission import Permission, RolePermission  # noqa: F401

# ── People ────────────────────────────────────────────────────────────────────
from app.db.models.department import Department  # noqa: F401
from app.db.models.user import User  # noqa: F401
from app.db.models.consent import Consent  # noqa: F401
from app.db.models.session import UserSession  # noqa: F401

# ── Master data ───────────────────────────────────────────────────────────────
from app.db.models.project import Project  # noqa: F401
from app.db.models.location import Location  # noqa: F401
from app.db.models.shift import Shift  # noqa: F401
from app.db.models.assignment import Assignment  # noqa: F401

# ── Devices ───────────────────────────────────────────────────────────────────
from app.db.models.device import Device  # noqa: F401

# ── Biometrics ────────────────────────────────────────────────────────────────
from app.db.models.face_enrollment import FaceEnrollment  # noqa: F401
from app.db.models.face_template import FaceTemplate  # noqa: F401

# ── Attendance ────────────────────────────────────────────────────────────────
from app.db.models.attendance_attempt import AttendanceAttempt  # noqa: F401
from app.db.models.attendance_record import AttendanceRecord  # noqa: F401
from app.db.models.attendance_exception import AttendanceException  # noqa: F401

# ── Announcements ─────────────────────────────────────────────────────────────
from app.db.models.announcement import Announcement  # noqa: F401
from app.db.models.announcement_read import AnnouncementRead  # noqa: F401

# ── Notifications ─────────────────────────────────────────────────────────────
from app.db.models.notification import Notification  # noqa: F401
from app.db.models.notification_read import NotificationRead  # noqa: F401

# ── Help desk ─────────────────────────────────────────────────────────────────
from app.db.models.help_category import HelpCategory, HelpRequest  # noqa: F401
from app.db.models.help_comment import HelpComment  # noqa: F401
from app.db.models.help_attachment import HelpAttachment  # noqa: F401

# ── Offline sync ──────────────────────────────────────────────────────────────
from app.db.models.sync_event import SyncEvent  # noqa: F401
from app.db.models.sync_conflict import SyncConflict  # noqa: F401

# ── Audit ─────────────────────────────────────────────────────────────────────
from app.db.models.audit_log import AuditLog  # noqa: F401
from app.db.models.login_audit import LoginAudit  # noqa: F401
