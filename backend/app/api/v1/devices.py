"""Device registration and heartbeat endpoints."""
from datetime import datetime

from fastapi import APIRouter
from sqlalchemy import select

from app.core.constants import DeviceStatus
from app.core.exceptions import DeviceAlreadyRegisteredError, DeviceRevokedError, NotFoundError
from app.db.models.device import Device
from app.db.models.user import User
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import DeviceHeartbeatRequest, DeviceOut, DeviceRegisterRequest
from app.utils.time import utcnow

router = APIRouter()


@router.get("/me", response_model=DeviceOut | None, summary="Current device metadata")
async def get_device(user: CurrentUser, db: DbSession) -> DeviceOut | None:
    """Flutter UserApi.deviceMetadata()."""
    result = await db.execute(
        select(Device).where(
            Device.user_id == user.id,
            Device.status == DeviceStatus.REGISTERED,
        ).limit(1)
    )
    device = result.scalar_one_or_none()
    if not device:
        return None
    return _to_out(device)


@router.post("/register", response_model=DeviceOut, summary="Register device")
async def register_device(
    body: DeviceRegisterRequest, user: CurrentUser, db: DbSession
) -> DeviceOut:
    """Flutter UserApi.registerDevice()."""
    # Check for existing active device
    existing = await db.execute(
        select(Device).where(
            Device.user_id == user.id,
            Device.status == DeviceStatus.REGISTERED,
        )
    )
    existing_device = existing.scalar_one_or_none()
    if existing_device:
        # Allow re-registration with same device UUID (idempotent)
        if existing_device.device_uuid == body.device_uuid:
            existing_device.app_version = body.app_version or existing_device.app_version
            existing_device.last_seen_at = utcnow()
            await db.commit()
            await db.refresh(existing_device)
            return _to_out(existing_device)
        raise DeviceAlreadyRegisteredError()

    device = Device(
        user_id=user.id,
        organization_id=user.organization_id,
        device_uuid=body.device_uuid,
        platform=body.platform,
        manufacturer=body.manufacturer,
        model=body.model,
        os_version=body.os_version,
        app_version=body.app_version,
        public_key=body.public_key,
        status=DeviceStatus.REGISTERED,
        registered_at=utcnow(),
        last_seen_at=utcnow(),
    )
    db.add(device)

    # Mark user as having a registered device
    user_obj = await db.get(User, user.id)
    if user_obj:
        user_obj.device_registered = True

    await db.commit()
    await db.refresh(device)
    return _to_out(device)


@router.post("/{device_id}/heartbeat", summary="Device heartbeat")
async def device_heartbeat(
    device_id: str, body: DeviceHeartbeatRequest, user: CurrentUser, db: DbSession
) -> dict:
    device = await db.get(Device, device_id)
    if not device or device.user_id != user.id:
        raise NotFoundError()
    if device.status == DeviceStatus.REVOKED:
        raise DeviceRevokedError()
    device.last_seen_at = utcnow()
    if body.app_version:
        device.app_version = body.app_version
    await db.commit()
    return {"status": "ok", "server_time": utcnow().isoformat()}


@router.post("/{device_id}/revoke", summary="Revoke device (admin)")
async def revoke_device(device_id: str, user: CurrentUser, db: DbSession) -> dict:
    device = await db.get(Device, device_id)
    if not device or device.organization_id != user.organization_id:
        raise NotFoundError()
    device.status = DeviceStatus.REVOKED
    # Update user flag
    emp = await db.get(User, device.user_id)
    if emp:
        # Check if any other active devices exist
        other = await db.execute(
            select(Device).where(
                Device.user_id == emp.id,
                Device.id != device_id,
                Device.status == DeviceStatus.REGISTERED,
            )
        )
        if not other.scalar_one_or_none():
            emp.device_registered = False
    await db.commit()
    return {"message": "Device revoked."}


def _to_out(device: Device) -> DeviceOut:
    return DeviceOut(
        id=device.id,
        device_uuid=device.device_uuid,
        platform=device.platform,
        model=device.model,
        os_version=device.os_version,
        app_version=device.app_version,
        status=device.status,
        registered_at=device.registered_at,
        last_seen_at=device.last_seen_at,
    )
