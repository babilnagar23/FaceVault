from __future__ import annotations
from typing import Optional
"""Announcement, Notification, HelpDesk, Device, Location, Shift, Assignment schemas."""

from datetime import datetime, date
from pydantic import BaseModel, Field
from app.schemas.common import OrmModel


# ─── Device ──────────────────────────────────────────────────────────────────

class DeviceRegisterRequest(BaseModel):
    device_uuid: str
    platform: str = Field(..., pattern="^(android|ios)$")
    manufacturer: Optional[str] = None
    model: Optional[str] = None
    os_version: Optional[str] = None
    app_version: Optional[str] = None
    public_key: Optional[str] = None


class DeviceOut(OrmModel):
    """Matches Flutter DeviceMetadata model."""
    id: str
    device_uuid: str
    platform: str
    model: Optional[str]
    os_version: Optional[str]
    app_version: Optional[str]
    status: str
    registered_at: datetime
    last_seen_at: Optional[datetime]


class DeviceHeartbeatRequest(BaseModel):
    app_version: Optional[str] = None
    battery_level: Optional[int] = None


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
    published_at: Optional[datetime]
    publisher: Optional[str] = None  # creator name snapshot
    status: str


class AnnouncementCreate(BaseModel):
    title: str
    category: str
    body: str
    pinned: bool = False
    urgent: bool = False
    target_type: str = "all"
    target_ids: list[str] | None = None
    scheduled_for: Optional[datetime] = None


class AnnouncementUpdate(BaseModel):
    title: Optional[str] = None
    category: Optional[str] = None
    body: Optional[str] = None
    pinned: Optional[bool] = None
    urgent: Optional[bool] = None


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
    device_terminal: Optional[str] = None


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
    employee_id: Optional[str] = None
    employee_name: Optional[str] = None
    device_terminal: Optional[str] = None


class HelpCommentOut(OrmModel):
    id: str
    body: str
    is_system: bool
    is_internal: bool
    created_at: datetime
    author_name: Optional[str] = None


# ─── Location ─────────────────────────────────────────────────────────────────

class LocationOut(OrmModel):
    """Matches admin LocationSite type."""
    id: str
    name: str
    project: Optional[str] = None
    address: Optional[str] = None
    latitude: float
    longitude: float
    radius_meters: int
    active: bool
    assigned_employees: int = 0
    site_code: Optional[str] = None


class LocationCreate(BaseModel):
    name: str
    project_id: Optional[str] = None
    address: Optional[str] = None
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    radius_meters: int = Field(default=150, ge=10)
    site_code: Optional[str] = None


class LocationUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_meters: Optional[int] = None
    active: Optional[bool] = None


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
    effective_to: Optional[date]
    is_active: bool


class AssignmentCreate(BaseModel):
    user_id: str
    project_id: str
    location_id: str
    shift_id: str
    effective_from: date
    effective_to: Optional[date] = None


# ─── Project ──────────────────────────────────────────────────────────────────

class ProjectOut(OrmModel):
    id: str
    name: str
    code: Optional[str]
    description: Optional[str]
    active: bool


class ProjectCreate(BaseModel):
    name: str
    code: Optional[str] = None
    description: Optional[str] = None


# ─── Onboarding / Bootstrap ───────────────────────────────────────────────────

class BootstrapResponse(BaseModel):
    """Everything the mobile app needs for offline operation."""
    employee: dict
    assignment: Optional[dict] = None
    project: Optional[dict] = None
    location: Optional[dict] = None
    shift: Optional[dict] = None
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
    employee_role: Optional[str] = None
    employee_dept: Optional[str] = None
    scan_time: str
    assigned_site: str
    current_coordinates: str
    distance: str
    gps_accuracy: str
    face_score: float
    liveness_score: float
    status: str
    reason: Optional[str] = None


class VerificationDecision(BaseModel):
    decision: str  # approve, reject, request_explanation
    notes: Optional[str] = None


# ─── Biometrics ───────────────────────────────────────────────────────────────

class BiometricStatusOut(BaseModel):
    """Matches Flutter FaceEnrollmentApi.isEnrolled()."""
    enrolled: bool
    status: str
    model_version: Optional[str] = None
    quality_score: Optional[float] = None
    enrolled_at: Optional[datetime] = None


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
    actor: Optional[str] = None
    target: Optional[str] = None
    timestamp: datetime
    details: Optional[str] = None


# ─── Settings ────────────────────────────────────────────────────────────────

class AttendanceSettingsUpdate(BaseModel):
    default_geofence_radius_meters: Optional[int] = None
    grace_period_minutes: Optional[int] = None
    late_threshold_minutes: Optional[int] = None
    checkin_window_hours: Optional[int] = None


class BiometricSettingsUpdate(BaseModel):
    face_match_threshold: Optional[float] = None
    liveness_threshold: Optional[float] = None
    minimum_face_quality: Optional[float] = None


class OfflineSettingsUpdate(BaseModel):
    offline_enabled: Optional[bool] = None
    max_offline_days: Optional[int] = None
