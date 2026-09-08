"""Employee endpoints — mobile current user + admin CRUD."""
from fastapi import APIRouter, Query
from sqlalchemy import desc, select

from app.core.exceptions import EmployeeNotFoundError
from app.db.models.user import User
from app.dependencies import CurrentUser, DbSession
from app.schemas.employee import EmployeeCreate, EmployeeListFilters, EmployeeMe, EmployeeOut, EmployeeUpdate

router = APIRouter()


@router.get("/employees/me", response_model=EmployeeMe, summary="Current employee profile")
async def get_me(user: CurrentUser, db: DbSession) -> EmployeeMe:
    """Flutter UserApi.currentEmployee()."""
    dept_name = None
    if user.department_id:
        from app.db.models.department import Department
        dept = await db.get(Department, user.department_id)
        dept_name = dept.name if dept else None

    role_name = None
    if user.role_id:
        from app.db.models.role import Role
        role = await db.get(Role, user.role_id)
        role_name = role.display_name if role else None

    return EmployeeMe(
        id=user.id,
        employee_code=user.employee_code,
        first_name=user.first_name,
        last_name=user.last_name,
        full_name=user.full_name,
        email=user.email,
        phone=user.phone,
        department=dept_name,
        role=role_name,
        project=None,
        location=None,
        shift=None,
        face_enrolled=user.face_enrolled,
        device_registered=user.device_registered,
        status=user.status,
        organization_id=user.organization_id,
        avatar_url=user.avatar_url,
        join_date=user.join_date,
        last_login_at=user.last_login_at,
    )


@router.get("/admin/employees", response_model=list[EmployeeOut], summary="List all employees (admin)")
async def list_employees(
    user: CurrentUser,
    db: DbSession,
    search: str | None = Query(default=None),
    status: str | None = Query(default=None),
    department_id: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[EmployeeOut]:
    """Admin employeeApi.list()."""
    stmt = select(User).where(User.organization_id == user.organization_id)
    if status:
        stmt = stmt.where(User.status == status)
    if department_id:
        stmt = stmt.where(User.department_id == department_id)
    stmt = stmt.order_by(User.first_name).limit(limit).offset(offset)

    result = await db.execute(stmt)
    users = result.scalars().all()

    out = []
    for u in users:
        out.append(EmployeeOut(
            id=u.id,
            employee_code=u.employee_code,
            first_name=u.first_name,
            last_name=u.last_name,
            full_name=u.full_name,
            email=u.email,
            department=None,
            role=None,
            project=None,
            location=None,
            shift=None,
            face_enrolled=u.face_enrolled,
            device_registered=u.device_registered,
            status=u.status,
            avatar_url=u.avatar_url,
            join_date=u.join_date,
        ))
    return out


@router.get("/admin/employees/{employee_id}", response_model=EmployeeOut, summary="Employee detail (admin)")
async def get_employee(employee_id: str, user: CurrentUser, db: DbSession) -> EmployeeOut:
    """Admin employeeApi.detail(id)."""
    result = await db.execute(
        select(User).where(User.id == employee_id, User.organization_id == user.organization_id)
    )
    emp = result.scalar_one_or_none()
    if not emp:
        raise EmployeeNotFoundError()
    return EmployeeOut(
        id=emp.id,
        employee_code=emp.employee_code,
        first_name=emp.first_name,
        last_name=emp.last_name,
        full_name=emp.full_name,
        email=emp.email,
        face_enrolled=emp.face_enrolled,
        device_registered=emp.device_registered,
        status=emp.status,
        avatar_url=emp.avatar_url,
        join_date=emp.join_date,
    )


@router.post("/admin/employees", response_model=EmployeeOut, summary="Create employee (admin)")
async def create_employee(body: EmployeeCreate, user: CurrentUser, db: DbSession) -> EmployeeOut:
    from app.core.security import hash_password
    emp = User(
        organization_id=user.organization_id,
        employee_code=body.employee_code.upper(),
        first_name=body.first_name,
        last_name=body.last_name,
        email=body.email,
        phone=body.phone,
        password_hash=hash_password(body.password),
        department_id=body.department_id,
        role_id=body.role_id,
        join_date=body.join_date,
        status="ACTIVE",
    )
    db.add(emp)
    await db.commit()
    await db.refresh(emp)
    return EmployeeOut(
        id=emp.id,
        employee_code=emp.employee_code,
        first_name=emp.first_name,
        last_name=emp.last_name,
        full_name=emp.full_name,
        email=emp.email,
        face_enrolled=emp.face_enrolled,
        device_registered=emp.device_registered,
        status=emp.status,
    )


@router.patch("/admin/employees/{employee_id}", response_model=EmployeeOut, summary="Update employee (admin)")
async def update_employee(
    employee_id: str, body: EmployeeUpdate, user: CurrentUser, db: DbSession
) -> EmployeeOut:
    result = await db.execute(
        select(User).where(User.id == employee_id, User.organization_id == user.organization_id)
    )
    emp = result.scalar_one_or_none()
    if not emp:
        raise EmployeeNotFoundError()
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(emp, field, value)
    await db.commit()
    await db.refresh(emp)
    return EmployeeOut(
        id=emp.id,
        employee_code=emp.employee_code,
        first_name=emp.first_name,
        last_name=emp.last_name,
        full_name=emp.full_name,
        email=emp.email,
        face_enrolled=emp.face_enrolled,
        device_registered=emp.device_registered,
        status=emp.status,
    )
