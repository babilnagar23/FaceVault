"""
Sync endpoint — receives batched offline events from mobile.
Idempotency via UNIQUE(client_event_id) — duplicate pushes are completely safe.
"""
from fastapi import APIRouter
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.core.constants import SyncOutcome
from app.db.models.sync_conflict import SyncConflict
from app.db.models.sync_event import SyncEvent
from app.dependencies import CurrentUser, DbSession
from app.schemas.sync import SyncConflictOut, SyncPushRequest, SyncPushResponse, SyncStatusOut
from app.utils.time import utcnow

router = APIRouter()


@router.get("/pull", response_model=SyncStatusOut, summary="Get sync status")
async def sync_status(user: CurrentUser, db: DbSession) -> SyncStatusOut:
    """Flutter SyncApi.status() — returns pending count and last sync time."""
    from sqlalchemy import func, and_

    count_result = await db.execute(
        select(func.count(SyncEvent.id)).where(
            SyncEvent.user_id == user.id,
            SyncEvent.status == "PENDING",
        )
    )
    pending_count = count_result.scalar() or 0

    last_result = await db.execute(
        select(SyncEvent.server_processed_at)
        .where(SyncEvent.user_id == user.id, SyncEvent.status == SyncOutcome.ACCEPTED)
        .order_by(SyncEvent.server_processed_at.desc())
        .limit(1)
    )
    last_sync = last_result.scalar_one_or_none()

    return SyncStatusOut(
        pending_count=pending_count,
        last_sync_at=last_sync,
        server_time=utcnow(),
    )


@router.post("/push", response_model=SyncPushResponse, summary="Push offline events")
async def sync_push(
    body: SyncPushRequest,
    user: CurrentUser,
    db: DbSession,
) -> SyncPushResponse:
    """
    Flutter SyncApi.flush() — processes a batch of offline events.
    Each event is processed atomically. Duplicates return ALREADY_PROCESSED.
    """
    server_now = utcnow()
    accepted: list[str] = []
    rejected: list[str] = []
    conflicts: list[SyncConflictOut] = []
    already_processed: list[str] = []

    for event_payload in body.events:
        # ── Idempotency check ──────────────────────────────────────────────
        existing = await db.execute(
            select(SyncEvent).where(SyncEvent.client_event_id == event_payload.client_event_id)
        )
        existing_event = existing.scalar_one_or_none()
        if existing_event:
            if existing_event.status == SyncOutcome.ACCEPTED:
                already_processed.append(event_payload.client_event_id)
            elif existing_event.status == SyncOutcome.REJECTED:
                rejected.append(event_payload.client_event_id)
            continue

        # ── Validate the event ─────────────────────────────────────────────
        rejection_reason: str | None = None

        if event_payload.entity_type == "attendance_attempt":
            # Delegate to attendance processing
            try:
                from app.schemas.attendance import AttendanceAttemptCreate
                payload = event_payload.payload
                attempt_body = AttendanceAttemptCreate(**payload)

                # Check for existing attempt with same client_event_id
                from app.db.models.attendance_attempt import AttendanceAttempt
                dup = await db.execute(
                    select(AttendanceAttempt).where(
                        AttendanceAttempt.client_event_id == event_payload.client_event_id
                    )
                )
                if dup.scalar_one_or_none():
                    already_processed.append(event_payload.client_event_id)
                    continue
            except Exception as e:
                rejection_reason = f"Invalid payload: {e}"
        elif event_payload.entity_type not in (
            "attendance_attempt", "help_request", "announcement_read", "notification_read"
        ):
            rejection_reason = f"Unknown entity_type: {event_payload.entity_type}"

        # ── Persist the sync event ─────────────────────────────────────────
        sync_event = SyncEvent(
            client_event_id=event_payload.client_event_id,
            organization_id=user.organization_id,
            user_id=user.id,
            entity_type=event_payload.entity_type,
            operation=event_payload.operation,
            client_created_at=event_payload.client_created_at,
            server_received_at=server_now,
            server_processed_at=server_now,
            status=SyncOutcome.REJECTED if rejection_reason else SyncOutcome.ACCEPTED,
            rejection_reason=rejection_reason,
            payload=event_payload.payload,
        )
        db.add(sync_event)

        try:
            await db.flush()
        except IntegrityError:
            # Race condition — another request already inserted this event
            await db.rollback()
            already_processed.append(event_payload.client_event_id)
            continue

        if rejection_reason:
            rejected.append(event_payload.client_event_id)
        else:
            accepted.append(event_payload.client_event_id)

    await db.commit()

    return SyncPushResponse(
        accepted=accepted,
        rejected=rejected,
        conflicts=conflicts,
        server_time=utcnow(),
        already_processed=already_processed,
    )
