"""Main API router — includes all v1 sub-routers."""
from fastapi import APIRouter

from app.api.v1 import (
    announcements,
    assignments,
    attendance,
    audit,
    auth,
    biometrics,
    dashboard,
    devices,
    employees,
    helpdesk,
    locations,
    notifications,
    onboarding,
    projects,
    reports,
    settings,
    shifts,
    sync,
    verification,
)

api_router = APIRouter()

# ─── Auth ──────────────────────────────────────────────────────────────────────
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# ─── Onboarding ────────────────────────────────────────────────────────────────
api_router.include_router(onboarding.router, prefix="/onboarding", tags=["Onboarding"])

# ─── Devices ───────────────────────────────────────────────────────────────────
api_router.include_router(devices.router, prefix="/devices", tags=["Devices"])

# ─── Employees ─────────────────────────────────────────────────────────────────
api_router.include_router(employees.router, prefix="", tags=["Employees"])

# ─── Projects ──────────────────────────────────────────────────────────────────
api_router.include_router(projects.router, prefix="", tags=["Projects"])

# ─── Locations ─────────────────────────────────────────────────────────────────
api_router.include_router(locations.router, prefix="", tags=["Locations"])

# ─── Shifts ────────────────────────────────────────────────────────────────────
api_router.include_router(shifts.router, prefix="", tags=["Shifts"])

# ─── Assignments ───────────────────────────────────────────────────────────────
api_router.include_router(assignments.router, prefix="", tags=["Assignments"])

# ─── Biometrics ────────────────────────────────────────────────────────────────
api_router.include_router(biometrics.router, prefix="/biometrics", tags=["Biometrics"])

# ─── Attendance ────────────────────────────────────────────────────────────────
api_router.include_router(attendance.router, prefix="", tags=["Attendance"])

# ─── Sync ──────────────────────────────────────────────────────────────────────
api_router.include_router(sync.router, prefix="/sync", tags=["Sync"])

# ─── Verification ──────────────────────────────────────────────────────────────
api_router.include_router(verification.router, prefix="/admin/verification", tags=["Verification"])

# ─── Announcements ─────────────────────────────────────────────────────────────
api_router.include_router(announcements.router, prefix="", tags=["Announcements"])

# ─── Notifications ─────────────────────────────────────────────────────────────
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])

# ─── Help Desk ─────────────────────────────────────────────────────────────────
api_router.include_router(helpdesk.router, prefix="", tags=["Help Desk"])

# ─── Reports ───────────────────────────────────────────────────────────────────
api_router.include_router(reports.router, prefix="/admin/reports", tags=["Reports"])

# ─── Audit ─────────────────────────────────────────────────────────────────────
api_router.include_router(audit.router, prefix="/admin/audit-logs", tags=["Audit"])

# ─── Settings ──────────────────────────────────────────────────────────────────
api_router.include_router(settings.router, prefix="/admin/settings", tags=["Settings"])

# ─── Dashboard ─────────────────────────────────────────────────────────────────
api_router.include_router(dashboard.router, prefix="/admin/dashboard", tags=["Dashboard"])
