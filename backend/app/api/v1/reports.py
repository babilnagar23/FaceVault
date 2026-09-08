"""Reports — attendance analytics for admin dashboard."""
from fastapi import APIRouter, Query
from sqlalchemy import func, select

from app.db.models.attendance_record import AttendanceRecord
from app.db.models.department import Department
from app.db.models.user import User
from app.dependencies import CurrentUser, DbSession
from app.utils.time import utcnow
from datetime import timedelta

router = APIRouter()


@router.get("/dashboard", summary="Weekly attendance chart data")
async def dashboard_report(user: CurrentUser, db: DbSession) -> list[dict]:
    """Admin reportApi.dashboard() — present/absent/late per day for last 7 days."""
    org_id = user.organization_id
    today = utcnow().date()
    days = [(today - timedelta(days=i)) for i in range(6, -1, -1)]
    day_labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    result_data = []
    for i, day in enumerate(days):
        present = await db.execute(
            select(func.count(AttendanceRecord.id)).where(
                AttendanceRecord.organization_id == org_id,
                AttendanceRecord.attendance_date == day,
                AttendanceRecord.status == "PRESENT",
            )
        )
        late = await db.execute(
            select(func.count(AttendanceRecord.id)).where(
                AttendanceRecord.organization_id == org_id,
                AttendanceRecord.attendance_date == day,
                AttendanceRecord.status == "LATE",
            )
        )
        absent = await db.execute(
            select(func.count(AttendanceRecord.id)).where(
                AttendanceRecord.organization_id == org_id,
                AttendanceRecord.attendance_date == day,
                AttendanceRecord.status == "ABSENT",
            )
        )
        result_data.append({
            "day": day_labels[day.weekday()],
            "date": day.isoformat(),
            "present": present.scalar() or 0,
            "late": late.scalar() or 0,
            "absent": absent.scalar() or 0,
        })
    return result_data


@router.get("/departments", summary="Department attendance breakdown")
async def department_report(user: CurrentUser, db: DbSession) -> list[dict]:
    """Admin reportApi.departments()."""
    org_id = user.organization_id
    today = utcnow().date()

    dept_result = await db.execute(
        select(Department).where(Department.organization_id == org_id)
    )
    departments = dept_result.scalars().all()

    colors = ["#0F4C81", "#1E88E5", "#2E7D32", "#ED6C02", "#D32F2F", "#6A1B9A", "#00838F"]
    out = []
    for i, dept in enumerate(departments):
        # Count employees in dept
        emp_count = await db.execute(
            select(func.count(User.id)).where(User.department_id == dept.id, User.status == "ACTIVE")
        )
        total = emp_count.scalar() or 0
        if total == 0:
            continue
        # Count present today
        present = await db.execute(
            select(func.count(AttendanceRecord.id))
            .join(User, AttendanceRecord.user_id == User.id)
            .where(
                AttendanceRecord.organization_id == org_id,
                AttendanceRecord.attendance_date == today,
                AttendanceRecord.status.in_(["PRESENT", "LATE"]),
                User.department_id == dept.id,
            )
        )
        present_count = present.scalar() or 0
        percent = round((present_count / total) * 100) if total > 0 else 0
        out.append({"department": dept.name, "percent": percent, "color": colors[i % len(colors)]})

    return out


@router.get("/export/attendance", summary="Export attendance report (async)")
async def export_attendance(
    user: CurrentUser,
    date_from: str = Query(...),
    date_to: str = Query(...),
    format: str = Query(default="csv", pattern="^(csv|xlsx|pdf)$"),
) -> dict:
    """Queue a report export task via Celery."""
    try:
        from app.workers.tasks import export_attendance_report
        task = export_attendance_report.delay(
            org_id=user.organization_id,
            date_from=date_from,
            date_to=date_to,
            format=format,
            requested_by=user.id,
        )
        return {"task_id": task.id, "status": "QUEUED", "message": "Report queued. Check task status for download URL."}
    except Exception:
        return {"task_id": None, "status": "ERROR", "message": "Worker not available."}
