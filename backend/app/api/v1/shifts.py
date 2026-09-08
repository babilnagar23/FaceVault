"""Shifts router."""
from fastapi import APIRouter
from sqlalchemy import select

from app.db.models.shift import Shift
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import ShiftCreate, ShiftOut

router = APIRouter()


@router.get("/shifts", response_model=list[ShiftOut], summary="List shifts")
async def list_shifts(user: CurrentUser, db: DbSession) -> list[ShiftOut]:
    result = await db.execute(
        select(Shift).where(Shift.organization_id == user.organization_id, Shift.active == True)
    )
    return [ShiftOut(id=s.id, name=s.name, start_time=s.start_time, end_time=s.end_time,
                     grace_period_minutes=s.grace_period_minutes, late_threshold_minutes=s.late_threshold_minutes,
                     working_days=s.working_days, active=s.active)
            for s in result.scalars().all()]


@router.post("/admin/shifts", response_model=ShiftOut, summary="Create shift (admin)")
async def create_shift(body: ShiftCreate, user: CurrentUser, db: DbSession) -> ShiftOut:
    shift = Shift(
        organization_id=user.organization_id,
        name=body.name, start_time=body.start_time, end_time=body.end_time,
        grace_period_minutes=body.grace_period_minutes, late_threshold_minutes=body.late_threshold_minutes,
        working_days=body.working_days,
    )
    db.add(shift)
    await db.commit()
    await db.refresh(shift)
    return ShiftOut(id=shift.id, name=shift.name, start_time=shift.start_time, end_time=shift.end_time,
                    grace_period_minutes=shift.grace_period_minutes, late_threshold_minutes=shift.late_threshold_minutes,
                    working_days=shift.working_days, active=shift.active)
