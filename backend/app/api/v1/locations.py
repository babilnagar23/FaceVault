"""Locations — mobile read + admin CRUD."""
from fastapi import APIRouter
from sqlalchemy import func, select

from app.core.exceptions import LocationNotFoundError
from app.db.models.assignment import Assignment
from app.db.models.location import Location
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import LocationCreate, LocationOut, LocationUpdate

router = APIRouter()


async def _count_assigned(db, location_id: str) -> int:
    result = await db.execute(
        select(func.count(Assignment.id)).where(
            Assignment.location_id == location_id, Assignment.is_active == True
        )
    )
    return result.scalar() or 0


@router.get("/locations", response_model=list[LocationOut], summary="List locations")
async def list_locations(user: CurrentUser, db: DbSession) -> list[LocationOut]:
    result = await db.execute(
        select(Location).where(Location.organization_id == user.organization_id)
        .order_by(Location.name)
    )
    locations = result.scalars().all()
    out = []
    for loc in locations:
        count = await _count_assigned(db, loc.id)
        out.append(LocationOut(
            id=loc.id, name=loc.name, address=loc.address, latitude=loc.latitude,
            longitude=loc.longitude, radius_meters=loc.radius_meters, active=loc.active,
            site_code=loc.site_code, assigned_employees=count,
        ))
    return out


@router.get("/admin/locations", response_model=list[LocationOut], summary="Admin list locations")
async def admin_list_locations(user: CurrentUser, db: DbSession) -> list[LocationOut]:
    """Admin locationAdminApi.list()."""
    return await list_locations(user, db)


@router.get("/admin/locations/{loc_id}", response_model=LocationOut, summary="Location detail")
async def get_location(loc_id: str, user: CurrentUser, db: DbSession) -> LocationOut:
    loc = await db.get(Location, loc_id)
    if not loc or loc.organization_id != user.organization_id:
        raise LocationNotFoundError()
    count = await _count_assigned(db, loc.id)
    return LocationOut(id=loc.id, name=loc.name, address=loc.address, latitude=loc.latitude,
                       longitude=loc.longitude, radius_meters=loc.radius_meters, active=loc.active,
                       site_code=loc.site_code, assigned_employees=count)


@router.post("/admin/locations", response_model=LocationOut, summary="Create location (admin)")
async def create_location(body: LocationCreate, user: CurrentUser, db: DbSession) -> LocationOut:
    """Admin locationAdminApi.create()."""
    loc = Location(
        organization_id=user.organization_id,
        name=body.name, project_id=body.project_id, address=body.address,
        latitude=body.latitude, longitude=body.longitude,
        radius_meters=body.radius_meters, site_code=body.site_code, active=True,
    )
    db.add(loc)
    await db.commit()
    await db.refresh(loc)
    return LocationOut(id=loc.id, name=loc.name, address=loc.address, latitude=loc.latitude,
                       longitude=loc.longitude, radius_meters=loc.radius_meters, active=loc.active,
                       site_code=loc.site_code)


@router.patch("/admin/locations/{loc_id}", response_model=LocationOut, summary="Update location (admin)")
async def update_location(loc_id: str, body: LocationUpdate, user: CurrentUser, db: DbSession) -> LocationOut:
    loc = await db.get(Location, loc_id)
    if not loc or loc.organization_id != user.organization_id:
        raise LocationNotFoundError()
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(loc, field, value)
    await db.commit()
    await db.refresh(loc)
    return LocationOut(id=loc.id, name=loc.name, address=loc.address, latitude=loc.latitude,
                       longitude=loc.longitude, radius_meters=loc.radius_meters, active=loc.active)
