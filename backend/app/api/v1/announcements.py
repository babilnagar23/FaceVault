"""Announcements — mobile read/acknowledge + admin CRUD."""
from fastapi import APIRouter, Query
from sqlalchemy import and_, select

from app.core.exceptions import NotFoundError
from app.db.models.announcement import Announcement
from app.db.models.announcement_read import AnnouncementRead
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import AnnouncementCreate, AnnouncementOut, AnnouncementUpdate
from app.utils.time import utcnow

router = APIRouter()


@router.get("/announcements", response_model=list[AnnouncementOut], summary="List announcements")
async def list_announcements(user: CurrentUser, db: DbSession) -> list[AnnouncementOut]:
    """Flutter AnnouncementApi.announcements()."""
    result = await db.execute(
        select(Announcement).where(
            Announcement.organization_id == user.organization_id,
            Announcement.status == "PUBLISHED",
        ).order_by(Announcement.pinned.desc(), Announcement.published_at.desc()).limit(50)
    )
    announcements = result.scalars().all()

    # Load read/ack state for this user
    read_result = await db.execute(
        select(AnnouncementRead).where(AnnouncementRead.user_id == user.id)
    )
    reads_by_id = {r.announcement_id: r for r in read_result.scalars().all()}

    out = []
    for ann in announcements:
        read_rec = reads_by_id.get(ann.id)
        out.append(AnnouncementOut(
            id=ann.id,
            title=ann.title,
            category=ann.category,
            body=ann.body,
            pinned=ann.pinned,
            urgent=ann.urgent,
            read=read_rec.read if read_rec else False,
            acknowledged=read_rec.acknowledged if read_rec else False,
            published_at=ann.published_at,
            publisher=None,
            status=ann.status,
        ))
    return out


@router.get("/announcements/{ann_id}", response_model=AnnouncementOut, summary="Announcement detail")
async def get_announcement(ann_id: str, user: CurrentUser, db: DbSession) -> AnnouncementOut:
    """Flutter AnnouncementApi.detail(id) — also marks as read."""
    result = await db.execute(
        select(Announcement).where(Announcement.id == ann_id, Announcement.organization_id == user.organization_id)
    )
    ann = result.scalar_one_or_none()
    if not ann:
        raise NotFoundError()

    # Mark as read
    read_result = await db.execute(
        select(AnnouncementRead).where(AnnouncementRead.announcement_id == ann_id, AnnouncementRead.user_id == user.id)
    )
    read_rec = read_result.scalar_one_or_none()
    if read_rec:
        read_rec.read = True
        read_rec.read_at = read_rec.read_at or utcnow()
    else:
        read_rec = AnnouncementRead(
            announcement_id=ann_id,
            user_id=user.id,
            read=True,
            acknowledged=False,
            read_at=utcnow(),
        )
        db.add(read_rec)
    await db.commit()

    return AnnouncementOut(
        id=ann.id,
        title=ann.title,
        category=ann.category,
        body=ann.body,
        pinned=ann.pinned,
        urgent=ann.urgent,
        read=True,
        acknowledged=read_rec.acknowledged,
        published_at=ann.published_at,
        status=ann.status,
    )


@router.post("/announcements/{ann_id}/acknowledge", summary="Acknowledge announcement")
async def acknowledge(ann_id: str, user: CurrentUser, db: DbSession) -> dict:
    """Flutter AnnouncementApi.acknowledge(id)."""
    result = await db.execute(
        select(AnnouncementRead).where(AnnouncementRead.announcement_id == ann_id, AnnouncementRead.user_id == user.id)
    )
    read_rec = result.scalar_one_or_none()
    if read_rec:
        read_rec.acknowledged = True
        read_rec.acknowledged_at = utcnow()
    else:
        db.add(AnnouncementRead(
            announcement_id=ann_id,
            user_id=user.id,
            read=True,
            acknowledged=True,
            read_at=utcnow(),
            acknowledged_at=utcnow(),
        ))
    await db.commit()
    return {"acknowledged": True}


# ─── Admin ────────────────────────────────────────────────────────────────────

@router.get("/admin/announcements", response_model=list[AnnouncementOut], summary="Admin list announcements")
async def admin_list_announcements(user: CurrentUser, db: DbSession) -> list[AnnouncementOut]:
    result = await db.execute(
        select(Announcement).where(Announcement.organization_id == user.organization_id)
        .order_by(Announcement.created_at.desc()).limit(100)
    )
    anns = result.scalars().all()
    return [AnnouncementOut(id=a.id, title=a.title, category=a.category, body=a.body or "",
                            pinned=a.pinned, urgent=a.urgent, published_at=a.published_at, status=a.status) for a in anns]


@router.post("/admin/announcements", response_model=AnnouncementOut, summary="Create announcement (admin)")
async def create_announcement(body: AnnouncementCreate, user: CurrentUser, db: DbSession) -> AnnouncementOut:
    now = utcnow()
    status = "SCHEDULED" if body.scheduled_for and body.scheduled_for > now else "PUBLISHED"
    ann = Announcement(
        organization_id=user.organization_id,
        created_by_id=user.id,
        title=body.title,
        category=body.category,
        body=body.body,
        pinned=body.pinned,
        urgent=body.urgent,
        target_type=body.target_type,
        target_ids=body.target_ids,
        scheduled_for=body.scheduled_for,
        status=status,
        published_at=now if status == "PUBLISHED" else None,
    )
    db.add(ann)
    await db.commit()
    await db.refresh(ann)
    return AnnouncementOut(id=ann.id, title=ann.title, category=ann.category, body=ann.body,
                           pinned=ann.pinned, urgent=ann.urgent, published_at=ann.published_at, status=ann.status)


@router.patch("/admin/announcements/{ann_id}", summary="Update announcement (admin)")
async def update_announcement(ann_id: str, body: AnnouncementUpdate, user: CurrentUser, db: DbSession) -> dict:
    ann = await db.get(Announcement, ann_id)
    if not ann or ann.organization_id != user.organization_id:
        raise NotFoundError()
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(ann, field, value)
    await db.commit()
    return {"id": ann_id, "message": "Updated."}
