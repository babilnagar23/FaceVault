"""
AuditService — structured audit log recording.

Sensitive actions must generate AuditLog entries.
NEVER log: passwords, tokens, raw face embeddings.
"""
from __future__ import annotations
from typing import Optional, Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.audit_log import AuditLog


class AuditService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def log(
        self,
        organization_id: str,
        actor_id: Optional[str],
        action: str,
        entity_type: Optional[str] = None,
        entity_id: Optional[str] = None,
        before_data: dict[str, Any] | None = None,
        after_data: dict[str, Any] | None = None,
        ip_address: Optional[str] = None,
        details: Optional[str] = None,
    ) -> None:
        """
        Write a structured audit log entry.

        Args:
            organization_id: The organization context (NOT nullable — audit must be org-scoped).
            actor_id: The user who performed the action (None for system actions).
            action: Verb describing the action (e.g. 'employee.deactivate').
            entity_type: The affected resource type (e.g. 'user', 'assignment').
            entity_id: The affected resource ID.
            before_data: State before the change.
            after_data: State after the change.
            ip_address: Requester's IP for admin actions.
            details: Human-readable description.
        """
        entry = AuditLog(
            organization_id=organization_id,
            actor_id=actor_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            before_data=before_data,
            after_data=after_data,
            ip_address=ip_address,
            details=details,
        )
        self._db.add(entry)
        await self._db.flush()
