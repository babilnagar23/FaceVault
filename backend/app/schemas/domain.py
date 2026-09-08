"""Announcement, Notification, HelpDesk, Device, Location, Shift, Assignment schemas."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from app.schemas.common import OrmModel


# ─── Device ──────────────────────────────────────────────────────────────────

class DeviceRegisterRequest(BaseModel):
    device_uuid: str
    platform: str = Field(..., pattern="^(android|ios)$")
    manufacturer: str | None = None
    model: str | None = None
    os_version: str | None = None
    app_version: str | None = None
    public_key: str | None = None


class DeviceOut(OrmModel):
    """Matches Flutter DeviceMetadata model."""
    id: str
    device_uuid: str
    platform: str
    model: str | None
    os_version: str | None
    app_version: str | None
    status: str
    registered_at: datetime
    last_seen_at: datetime | None


class DeviceHeartbeatRequest(BaseModel):
    app_version: str | None = None
    battery_level: int | None = None


# ─── Announcement ─────────────────────────────────────────────────────────────

class AnnouncementOut(OrmModel):
    """Matches Flutter Announcement model."""
    id: str
    title: str
    category: str
    body: str
    pinned: bool
    urgent: bool
    read: bool = False
    acknowledged: bool = False
    published_at: datetime | None
    publisher: str | None = None  # creator name snapshot
    status: str


class AnnouncementCreate(BaseModel):
    title: str
    category: str
    body: str
    pinned: bool = False
    urgent: bool = False
    target_type: str = "all"
    target_ids: list[str] | None = None
    scheduled_for: datetime | None = None


class AnnouncementUpdate(BaseModel):
    title: str | None = None
    category: str | None = None
    body: str | None = None
    pinned: bool | None = None
    urgent: bool | None = None


# ─── Notification ─────────────────────────────────────────────────────────────

class NotificationOut(OrmModel):
    """Matches Flutter AppNotification model."""
    id: str
    type: str
    title: str
    body: str
    read: bool
    created_at: datetime


# ─── Help Desk ────────────────────────────────────────────────────────────────

class HelpTicketCreate(BaseModel):
    issue_type: str
    description: str
    device_terminal: str | None = None


class HelpCommentCreate(BaseModel):
    body: str
    is_internal: bool = False


class HelpTicketOut(OrmModel):
    """Matches Flutter HelpTicket model."""
    id: str
    issue_type: str
    description: str
    status: str
    priority: str
    created_at: datetime
    employee_id: str | None = None
    employee_name: str | None = None
    device_terminal: str | None = None


class HelpCommentOut(OrmModel):
    id: str
    body: str
    is_system: bool
    is_internal: bool
    created_at: datetime
    author_name: str | None = None


# ─── Location ─────────────────────────────────────────────────────────────────

class LocationOut(OrmModel):
    """Matches admin LocationSite type."""
    id: str
    name: str
    project: str | None = None
    address: str | None = None
    latitude: float
    longitude: float
    radius_meters: int
    active: bool
    assigned_employees: int = 0
    site_code: str | None = None


class LocationCreate(BaseModel):
    name: str
    project_id: str | None = None
    address: str | None = None
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    radius_meters: int = Field(default=150, ge=10)
    site_code: str | None = None


class LocationUpdate(BaseModel):
    name: str | None = None
    address: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    radius_meters: int | None = None
    active: bool | None = None


# ─── Shift ────────────────────────────────────────────────────────────────────

class ShiftOut(OrmModel):
    id: str
    name: str
    start_time: str
    end_time: str
    grace_period_minutes: int
    late_threshold_minutes: int
    working_days: list[str] | None
    active: bool


class ShiftCreate(BaseModel):
    name: str
    start_time: str  # "09:00"
    end_time: str    # "18:00"
    grace_period_minutes: int = 15
    late_threshold_minutes: int = 30
    working_days: list[str] = ["Mon", "Tue", "Wed", "Thu", "Fri"]


# ─── Assignment ───────────────────────────────────────────────────────────────

class AssignmentOut(OrmModel):
    id: str
    user_id: str
    project_id: str
    location_id: str
    shift_id: str
    effective_from: date
    effective_to: date | None
    is_active: bool


class AssignmentCreate(BaseModel):
    user_id: str
    project_id: str
    location_id: str
    shift_id: str
    effective_from: date
    effective_to: date | None = None


# ─── Project ──────────────────────────────────────────────────────────────────

class ProjectOut(OrmModel):
    id: str
    name: str
    code: str | None
    description: str | None
    active: bool


class ProjectCreate(BaseModel):
    name: str
    code: str | None = None
    description: str | None = None


# ─── Onboarding / Bootstrap ───────────────────────────────────────────────────

class BootstrapResponse(BaseModel):
    """Everything the mobile app needs for offline operation."""
    employee: dict
    assignment: dict | None = None
    project: dict | None = None
    location: dict | None = None
    shift: dict | None = None
    attendance_rules: dict = {}
    biometric_config: dict = {}
    announcements: list = []
    notifications: list = []


class OnboardingStatus(BaseModel):
    device_registered: bool
    face_enrolled: bool
    permissions_granted: bool
    offline_data_synced: bool
    onboarding_complete: bool


# ─── Verification Queue ───────────────────────────────────────────────────────

class VerificationCaseOut(BaseModel):
    """Matches admin VerificationCase type."""
    id: str
    employee: str
    employee_role: str | None = None
    employee_dept: str | None = None
    scan_time: str
    assigned_site: str
    current_coordinates: str
    distance: str
    gps_accuracy: str
    face_score: float
    liveness_score: float
    status: str
    reason: str | None = None


class VerificationDecision(BaseModel):
    decision: str  # approve, reject, request_explanation
    notes: str | None = None


# ─── Biometrics ───────────────────────────────────────────────────────────────

class BiometricStatusOut(BaseModel):
    """Matches Flutter FaceEnrollmentApi.isEnrolled()."""
    enrolled: bool
    status: str
    model_version: str | None = None
    quality_score: float | None = None
    enrolled_at: datetime | None = None


class EnrollmentCompleteRequest(BaseModel):
    model_version: str
    quality_score: float
    liveness_score: float


# ─── Dashboard ───────────────────────────────────────────────────────────────

class DashboardKPIs(BaseModel):
    total_employees: int
    present_today: int
    present_trend: str
    absent_today: int
    late: int
    pending_verification: int
    active_locations: int
    open_help_requests: int = 0


# ─── Audit ───────────────────────────────────────────────────────────────────

class AuditLogOut(OrmModel):
    id: str
    event: str
    actor: str | None = None
    target: str | None = None
    timestamp: datetime
    details: str | None = None


# ─── Settings ────────────────────────────────────────────────────────────────

class AttendanceSettingsUpdate(BaseModel):
    default_geofence_radius_meters: int | None = None
    grace_period_minutes: int | None = None
    late_threshold_minutes: int | None = None
    checkin_window_hours: int | None = None


class BiometricSettingsUpdate(BaseModel):
    face_match_threshold: float | None = None
    liveness_threshold: float | None = None
    minimum_face_quality: float | None = None


class OfflineSettingsUpdate(BaseModel):
    offline_enabled: bool | None = None
    max_offline_days: int | None = None
