from __future__ import annotations
from typing import Optional
"""Sync schemas matching Flutter SyncApi.flush() / SyncItem model."""

from datetime import datetime
from pydantic import BaseModel


class SyncEventPayload(BaseModel):
    """A single offline event from the mobile app."""
    client_event_id: str
    entity_type: str   # attendance_attempt, help_request, etc.
    operation: str     # create, update, delete
    client_created_at: Optional[datetime] = None
    payload: dict = {}


class SyncPushRequest(BaseModel):
    """POST /api/v1/sync/push body."""
    device_id: str
    events: list[SyncEventPayload]


class SyncConflictOut(BaseModel):
    client_event_id: str
    reason: str
    server_record_id: Optional[str] = None
    server_state: Optional[dict] = None
    resolution: Optional[str] = None


class SyncPushResponse(BaseModel):
    """Response matching the spec from the requirements."""
    accepted: list[str]
    rejected: list[str]
    conflicts: list[SyncConflictOut]
    server_time: datetime
    already_processed: list[str] = []


class SyncStatusOut(BaseModel):
    """Response for GET /api/v1/sync/pull — tells mobile what to sync."""
    pending_count: int
    last_sync_at: Optional[datetime]
    server_time: datetime
