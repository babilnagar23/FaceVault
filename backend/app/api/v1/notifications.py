"""Notifications — read and mark-read endpoints."""
from fastapi import APIRouter
from sqlalchemy import select, update

from app.db.models.notification import Notification
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import NotificationOut
from app.utils.time import utcnow

router = APIRouter()


@router.get("", response_model=list[NotificationOut], summary="List notifications")
async def list_notifications(user: CurrentUser, db: DbSession) -> list[NotificationOut]:
    """Flutter NotificationApi.notifications()."""
    result = await db.execute(
        select(Notification)
        .where(Notification.user_id == user.id)
        .order_by(Notification.created_at.desc())
        .limit(50)
    )
    notes = result.scalars().all()
    return [
        NotificationOut(id=n.id, type=n.type, title=n.title, body=n.body, read=n.read, created_at=n.created_at)
        for n in notes
    ]


@router.post("/{note_id}/read", summary="Mark notification as read")
async def mark_read(note_id: str, user: CurrentUser, db: DbSession) -> dict:
    """Flutter NotificationApi.markRead(id)."""
    await db.execute(
        update(Notification)
        .where(Notification.id == note_id, Notification.user_id == user.id)
        .values(read=True)
    )
    await db.commit()
    return {"read": True}


@router.post("/read-all", summary="Mark all notifications as read")
async def mark_all_read(user: CurrentUser, db: DbSession) -> dict:
    """Flutter NotificationApi.markAllRead()."""
    await db.execute(
        update(Notification)
        .where(Notification.user_id == user.id, Notification.read == False)
        .values(read=True)
    )
    await db.commit()
    return {"message": "All notifications marked as read."}
