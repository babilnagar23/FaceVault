"""Assignments router."""
from fastapi import APIRouter
from sqlalchemy import select

from app.core.exceptions import NotFoundError
from app.db.models.assignment import Assignment
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import AssignmentCreate, AssignmentOut

router = APIRouter()


@router.get("/assignments/me", response_model=AssignmentOut | None, summary="My current assignment")
async def my_assignment(user: CurrentUser, db: DbSession) -> AssignmentOut | None:
    result = await db.execute(
        select(Assignment).where(Assignment.user_id == user.id, Assignment.is_active == True)
        .order_by(Assignment.created_at.desc()).limit(1)
    )
    a = result.scalar_one_or_none()
    if not a:
        return None
    return AssignmentOut(id=a.id, user_id=a.user_id, project_id=a.project_id,
                         location_id=a.location_id, shift_id=a.shift_id,
                         effective_from=a.effective_from, effective_to=a.effective_to, is_active=a.is_active)


@router.post("/admin/assignments", response_model=AssignmentOut, summary="Create assignment (admin)")
async def create_assignment(body: AssignmentCreate, user: CurrentUser, db: DbSession) -> AssignmentOut:
    # Deactivate existing assignment for this user
    result = await db.execute(
        select(Assignment).where(Assignment.user_id == body.user_id, Assignment.is_active == True)
    )
    for old in result.scalars().all():
        old.is_active = False

    a = Assignment(
        organization_id=user.organization_id,
        user_id=body.user_id,
        project_id=body.project_id,
        location_id=body.location_id,
        shift_id=body.shift_id,
        effective_from=body.effective_from,
        effective_to=body.effective_to,
        is_active=True,
    )
    db.add(a)
    await db.commit()
    await db.refresh(a)
    return AssignmentOut(id=a.id, user_id=a.user_id, project_id=a.project_id,
                         location_id=a.location_id, shift_id=a.shift_id,
                         effective_from=a.effective_from, effective_to=a.effective_to, is_active=a.is_active)
