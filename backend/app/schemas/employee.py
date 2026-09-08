"""Employee schemas matching Flutter Employee model and admin domain.ts Employee type."""
from datetime import datetime
from pydantic import BaseModel, EmailStr
from app.schemas.common import OrmModel


class EmployeeOut(OrmModel):
    """Matches Flutter Employee domain model."""
    id: str
    employee_code: str
    first_name: str
    last_name: str
    full_name: str
    email: str
    department: str | None = None   # department name
    role: str | None = None          # role name
    project: str | None = None       # primary project name
    location: str | None = None      # primary location name
    shift: str | None = None         # primary shift display
    face_enrolled: bool
    device_registered: bool
    status: str
    site_code: str | None = None
    avatar_url: str | None = None
    join_date: datetime | None = None
    last_login_at: datetime | None = None


class EmployeeMe(EmployeeOut):
    """Full profile for the current authenticated employee."""
    organization_id: str
    phone: str | None = None


class EmployeeCreate(BaseModel):
    employee_code: str
    first_name: str
    last_name: str
    email: EmailStr
    phone: str | None = None
    password: str
    department_id: str | None = None
    role_id: str | None = None
    join_date: datetime | None = None


class EmployeeUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    email: EmailStr | None = None
    phone: str | None = None
    department_id: str | None = None
    role_id: str | None = None
    status: str | None = None


class EmployeeListFilters(BaseModel):
    search: str | None = None
    department_id: str | None = None
    project_id: str | None = None
    location_id: str | None = None
    status: str | None = None
    face_enrolled: bool | None = None
    device_registered: bool | None = None
