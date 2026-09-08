"""Admin dashboard KPIs and recent activity."""
from fastapi import APIRouter
from sqlalchemy import func, select

from app.db.models.attendance_exception import AttendanceException
from app.db.models.attendance_record import AttendanceRecord
from app.db.models.location import Location
from app.db.models.user import User
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import DashboardKPIs
from app.utils.time import utcnow

router = APIRouter()


@router.get("/kpis", response_model=DashboardKPIs, summary="Dashboard KPIs")
async def dashboard_kpis(user: CurrentUser, db: DbSession) -> DashboardKPIs:
    """Admin dashboardApi.kpis()."""
    today = utcnow().date()
    org_id = user.organization_id

    # Total active employees
    total_result = await db.execute(
        select(func.count(User.id)).where(User.organization_id == org_id, User.status == "ACTIVE")
    )
    total_employees = total_result.scalar() or 0

    # Present today
    present_result = await db.execute(
        select(func.count(AttendanceRecord.id)).where(
            AttendanceRecord.organization_id == org_id,
            AttendanceRecord.attendance_date == today,
            AttendanceRecord.status == "PRESENT",
        )
    )
    present_today = present_result.scalar() or 0

    # Absent today (not in attendance_records with PRESENT/LATE)
    late_result = await db.execute(
        select(func.count(AttendanceRecord.id)).where(
            AttendanceRecord.organization_id == org_id,
            AttendanceRecord.attendance_date == today,
            AttendanceRecord.status == "LATE",
        )
    )
    late_count = late_result.scalar() or 0
    absent_today = max(0, total_employees - present_today - late_count)

    # Pending verification
    pv_result = await db.execute(
        select(func.count(AttendanceException.id)).where(
            AttendanceException.organization_id == org_id,
            AttendanceException.status == "NEEDS_REVIEW",
        )
    )
    pending_verification = pv_result.scalar() or 0

    # Active locations
    loc_result = await db.execute(
        select(func.count(Location.id)).where(Location.organization_id == org_id, Location.active == True)
    )
    active_locations = loc_result.scalar() or 0

    return DashboardKPIs(
        total_employees=total_employees,
        present_today=present_today,
        present_trend="+0.0%",
        absent_today=absent_today,
        late=late_count,
        pending_verification=pending_verification,
        active_locations=active_locations,
    )


@router.get("/activity", summary="Recent activity feed")
async def recent_activity(user: CurrentUser, db: DbSession) -> list[dict]:
    """Admin dashboardApi.recentActivity() — last 20 attendance events."""
    org_id = user.organization_id
    result = await db.execute(
        select(AttendanceRecord)
        .where(AttendanceRecord.organization_id == org_id)
        .order_by(AttendanceRecord.check_in_time.desc().nullslast())
        .limit(20)
    )
    records = result.scalars().all()
    items = []
    for r in records:
        emp = await db.get(User, r.user_id)
        emp_name = emp.full_name if emp else "Unknown"
        action = "clocked in." if r.status == "PRESENT" else f"marked as {r.status.title()}."
        items.append({
            "id": r.id,
            "actor": emp_name,
            "action": action,
            "time": r.check_in_time.strftime("%I:%M %p") if r.check_in_time else "—",
            "type": "checkin" if r.status == "PRESENT" else "late" if r.status == "LATE" else "failed",
        })
    return items
