"""Organization settings — read and update."""
from fastapi import APIRouter
from sqlalchemy import select

from app.db.models.organization_settings import OrganizationSettings
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import AttendanceSettingsUpdate, BiometricSettingsUpdate, OfflineSettingsUpdate

router = APIRouter()


@router.get("", summary="Get organization settings")
async def get_settings(user: CurrentUser, db: DbSession) -> dict:
    """Admin settingsApi.sections() + full config."""
    result = await db.execute(
        select(OrganizationSettings).where(OrganizationSettings.organization_id == user.organization_id)
    )
    s = result.scalar_one_or_none()
    if not s:
        return {"message": "No settings configured. Defaults in use."}
    return {
        "attendance": {
            "default_geofence_radius_meters": s.default_geofence_radius_meters,
            "grace_period_minutes": s.grace_period_minutes,
            "late_threshold_minutes": s.late_threshold_minutes,
            "checkin_window_hours": s.checkin_window_hours,
        },
        "biometrics": {
            "face_match_threshold": s.face_match_threshold,
            "liveness_threshold": s.liveness_threshold,
            "minimum_face_quality": s.minimum_face_quality,
        },
        "offline": {
            "offline_enabled": s.offline_enabled,
            "max_offline_days": s.max_offline_days,
        },
        "notifications": {
            "notify_on_late": s.notify_on_late,
            "notify_on_absent": s.notify_on_absent,
            "notify_on_verification": s.notify_on_verification,
        },
    }


@router.patch("/attendance", summary="Update attendance settings")
async def update_attendance_settings(
    body: AttendanceSettingsUpdate, user: CurrentUser, db: DbSession
) -> dict:
    s = await _get_or_create(db, user.organization_id)
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(s, field, value)
    await db.commit()
    return {"message": "Attendance settings updated."}


@router.patch("/biometrics", summary="Update biometric settings")
async def update_biometric_settings(
    body: BiometricSettingsUpdate, user: CurrentUser, db: DbSession
) -> dict:
    s = await _get_or_create(db, user.organization_id)
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(s, field, value)
    await db.commit()
    return {"message": "Biometric settings updated."}


@router.patch("/offline", summary="Update offline settings")
async def update_offline_settings(
    body: OfflineSettingsUpdate, user: CurrentUser, db: DbSession
) -> dict:
    s = await _get_or_create(db, user.organization_id)
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(s, field, value)
    await db.commit()
    return {"message": "Offline settings updated."}


async def _get_or_create(db, org_id: str) -> OrganizationSettings:
    result = await db.execute(
        select(OrganizationSettings).where(OrganizationSettings.organization_id == org_id)
    )
    s = result.scalar_one_or_none()
    if not s:
        s = OrganizationSettings(organization_id=org_id)
        db.add(s)
        await db.flush()
    return s
