from __future__ import annotations
from typing import Optional
"""
SyncService — processes batched offline events from the mobile app.

Each event is dispatched to the appropriate domain service.
For entity_type='attendance_attempt', this dispatches to AttendanceService.

Outcomes:
  ACCEPTED        — event processed successfully
  ALREADY_PROCESSED — duplicate, existing result returned
  REJECTED        — validation failed or business rule rejected
  CONFLICT        — server state conflicts with client intent
"""

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import SyncOutcome
from app.db.models.sync_event import SyncEvent
from app.services.attendance_service import AttendanceService
from app.utils.time import utcnow


class SyncEventResult:
    def __init__(
        self,
        client_event_id: str,
        outcome: str,
        rejection_reason: Optional[str] = None,
        result_entity_id: Optional[str] = None,
    ) -> None:
        self.client_event_id = client_event_id
        self.outcome = outcome
        self.rejection_reason = rejection_reason
        self.result_entity_id = result_entity_id


class SyncService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def push_event(
        self,
        user_id: str,
        organization_id: str,
        org_timezone: str,
        client_event_id: str,
        entity_type: str,
        operation: str,
        payload: Optional[dict],
        client_created_at=None,
        device_id: Optional[str] = None,
    ) -> SyncEventResult:
        """
        Process a single sync event from the mobile app.

        Flow per event:
          1. Idempotency: check if client_event_id already processed
          2. Create SyncEvent in PENDING state
          3. Dispatch to domain service
          4. Update SyncEvent with outcome
          5. Return result (caller commits)
        """
        server_now = utcnow()

        # ── 1. Idempotency check ───────────────────────────────────────────────
        from sqlalchemy import select
        existing_result = await self._db.execute(
            select(SyncEvent).where(
                SyncEvent.client_event_id == client_event_id,
                SyncEvent.organization_id == organization_id,
            )
        )
        existing = existing_result.scalar_one_or_none()
        if existing:
            return SyncEventResult(
                client_event_id=client_event_id,
                outcome=SyncOutcome.ALREADY_PROCESSED,
                result_entity_id=existing.result_entity_id,
            )

        # ── 2. Create SyncEvent (PENDING) ──────────────────────────────────────
        sync_event = SyncEvent(
            client_event_id=client_event_id,
            organization_id=organization_id,
            user_id=user_id,
            device_id=device_id,
            entity_type=entity_type,
            operation=operation,
            client_created_at=client_created_at,
            server_received_at=server_now,
            status="PENDING",
            payload=payload,
        )
        self._db.add(sync_event)

        try:
            await self._db.flush()
        except IntegrityError:
            # Race condition — another concurrent request inserted this event
            await self._db.rollback()
            return SyncEventResult(
                client_event_id=client_event_id,
                outcome=SyncOutcome.ALREADY_PROCESSED,
            )

        # ── 3. Dispatch to domain service ──────────────────────────────────────
        outcome = SyncOutcome.REJECTED
        rejection_reason: Optional[str] = None
        result_entity_id: Optional[str] = None

        if entity_type == "attendance_attempt":
            try:
                att_svc = AttendanceService(self._db)
                attempt = await att_svc.submit_attempt(
                    user_id=user_id,
                    organization_id=organization_id,
                    org_timezone=org_timezone,
                    client_event_id=client_event_id,
                    event_type=payload.get("event_type", "CHECK_IN") if payload else "CHECK_IN",
                    client_timestamp=payload.get("client_timestamp") if payload else None,
                    latitude=payload.get("latitude") if payload else None,
                    longitude=payload.get("longitude") if payload else None,
                    gps_accuracy_meters=payload.get("gps_accuracy_meters") if payload else None,
                    face_verified=payload.get("face_verified", False) if payload else False,
                    face_score=payload.get("face_score") if payload else None,
                    liveness_verified=payload.get("liveness_verified", False) if payload else False,
                    liveness_score=payload.get("liveness_score") if payload else None,
                    offline_created=True,
                    device_id=device_id,
                    attempt_number=payload.get("attempt_number", 1) if payload else 1,
                )
                outcome = SyncOutcome.ACCEPTED
                result_entity_id = attempt.id
            except Exception as exc:
                outcome = SyncOutcome.REJECTED
                rejection_reason = f"Processing error: {exc}"
        else:
            rejection_reason = f"Unsupported entity_type: {entity_type}"

        # ── 4. Update SyncEvent with outcome ───────────────────────────────────
        sync_event.status = outcome
        sync_event.rejection_reason = rejection_reason
        sync_event.result_entity_id = result_entity_id
        sync_event.server_processed_at = utcnow()
        await self._db.flush()

        return SyncEventResult(
            client_event_id=client_event_id,
            outcome=outcome,
            rejection_reason=rejection_reason,
            result_entity_id=result_entity_id,
        )
