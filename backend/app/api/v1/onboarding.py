"""Onboarding bootstrap — everything the mobile app needs for offline operation."""
from fastapi import APIRouter
from sqlalchemy import desc, select

from app.config import settings
from app.db.models.announcement import Announcement
from app.db.models.assignment import Assignment
from app.db.models.location import Location
from app.db.models.notification import Notification
from app.db.models.project import Project
from app.db.models.shift import Shift
from app.db.models.user import User
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import BootstrapResponse, OnboardingStatus

router = APIRouter()


@router.get("/bootstrap", response_model=BootstrapResponse, summary="Bootstrap mobile app data")
async def bootstrap(user: CurrentUser, db: DbSession) -> BootstrapResponse:
    """
    Called after login — provides all data needed for offline operation.
    Equivalent of Flutter's bootstrap sequence.
    """
    # Active assignment
    asgn_result = await db.execute(
        select(Assignment).where(Assignment.user_id == user.id, Assignment.is_active == True)
        .order_by(desc(Assignment.created_at)).limit(1)
    )
    assignment = asgn_result.scalar_one_or_none()

    project = None
    location = None
    shift = None

    if assignment:
        project = await db.get(Project, assignment.project_id)
        location = await db.get(Location, assignment.location_id)
        shift = await db.get(Shift, assignment.shift_id)

    # Latest 10 announcements
    ann_result = await db.execute(
        select(Announcement).where(
            Announcement.organization_id == user.organization_id,
            Announcement.status == "PUBLISHED",
        ).order_by(Announcement.published_at.desc()).limit(10)
    )
    announcements = [
        {"id": a.id, "title": a.title, "category": a.category, "body": a.body,
         "pinned": a.pinned, "urgent": a.urgent, "published_at": a.published_at.isoformat() if a.published_at else None}
        for a in ann_result.scalars().all()
    ]

    # Unread notifications
    notif_result = await db.execute(
        select(Notification).where(Notification.user_id == user.id, Notification.read == False).limit(20)
    )
    notifications = [
        {"id": n.id, "type": n.type, "title": n.title, "body": n.body, "read": n.read,
         "created_at": n.created_at.isoformat()}
        for n in notif_result.scalars().all()
    ]

    emp_dict = {
        "id": user.id,
        "employee_code": user.employee_code,
        "full_name": user.full_name,
        "email": user.email,
        "face_enrolled": user.face_enrolled,
        "device_registered": user.device_registered,
        "status": user.status,
    }

    return BootstrapResponse(
        employee=emp_dict,
        assignment={"id": assignment.id, "effective_from": assignment.effective_from.isoformat(),
                    "is_active": assignment.is_active} if assignment else None,
        project={"id": project.id, "name": project.name, "code": project.code} if project else None,
        location={"id": location.id, "name": location.name, "latitude": location.latitude,
                  "longitude": location.longitude, "radius_meters": location.radius_meters,
                  "site_code": location.site_code} if location else None,
        shift={"id": shift.id, "name": shift.name, "start_time": shift.start_time,
               "end_time": shift.end_time, "grace_period_minutes": shift.grace_period_minutes,
               "working_days": shift.working_days} if shift else None,
        attendance_rules={
            "grace_period_minutes": settings.GRACE_PERIOD_MINUTES,
            "late_threshold_minutes": settings.LATE_THRESHOLD_MINUTES,
            "max_offline_days": settings.MAX_OFFLINE_DAYS,
        },
        biometric_config={
            "face_match_threshold": settings.FACE_MATCH_THRESHOLD,
            "liveness_threshold": settings.LIVENESS_THRESHOLD,
        },
        announcements=announcements,
        notifications=notifications,
    )


@router.get("/status", response_model=OnboardingStatus, summary="Onboarding completion status")
async def onboarding_status(user: CurrentUser, db: DbSession) -> OnboardingStatus:
    """Check what onboarding steps the employee has completed."""
    asgn = await db.execute(
        select(Assignment).where(Assignment.user_id == user.id, Assignment.is_active == True)
    )
    has_assignment = asgn.scalar_one_or_none() is not None

    return OnboardingStatus(
        device_registered=user.device_registered,
        face_enrolled=user.face_enrolled,
        permissions_granted=True,  # Permissions are managed on-device
        offline_data_synced=has_assignment,
        onboarding_complete=user.device_registered and user.face_enrolled and has_assignment,
    )
