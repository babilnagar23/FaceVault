"""Audit log read-only endpoint."""
from fastapi import APIRouter, Query
from sqlalchemy import desc, select

from app.db.models.audit_log import AuditLog
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import AuditLogOut

router = APIRouter()


@router.get("", response_model=list[AuditLogOut], summary="Audit log (admin)")
async def list_audit_logs(
    user: CurrentUser,
    db: DbSession,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    action: str | None = Query(default=None),
    actor_id: str | None = Query(default=None),
) -> list[AuditLogOut]:
    """Admin auditApi.list()."""
    stmt = select(AuditLog).where(AuditLog.organization_id == user.organization_id)
    if action:
        stmt = stmt.where(AuditLog.action.ilike(f"%{action}%"))
    if actor_id:
        stmt = stmt.where(AuditLog.actor_id == actor_id)
    stmt = stmt.order_by(desc(AuditLog.created_at)).limit(limit).offset(offset)
    result = await db.execute(stmt)
    logs = result.scalars().all()
    return [
        AuditLogOut(
            id=log.id,
            event=log.action,
            actor=log.actor_label or "System",
            target=log.entity_id,
            timestamp=log.created_at,
            details=log.details,
        )
        for log in logs
    ]
