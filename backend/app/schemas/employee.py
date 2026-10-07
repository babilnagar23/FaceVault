from __future__ import annotations
from typing import Optional
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
    department: Optional[str] = None   # department name
    role: Optional[str] = None          # role name
    project: Optional[str] = None       # primary project name
    location: Optional[str] = None      # primary location name
    shift: Optional[str] = None         # primary shift display
    face_enrolled: bool
    device_registered: bool
    status: str
    site_code: Optional[str] = None
    avatar_url: Optional[str] = None
    join_date: Optional[datetime] = None
    last_login_at: Optional[datetime] = None


class EmployeeMe(EmployeeOut):
    """Full profile for the current authenticated employee."""
    organization_id: str
    phone: Optional[str] = None


class EmployeeCreate(BaseModel):
    employee_code: str
    first_name: str
    last_name: str
    email: EmailStr
    phone: Optional[str] = None
    password: str
    department_id: Optional[str] = None
    role_id: Optional[str] = None
    join_date: Optional[datetime] = None


class EmployeeUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    department_id: Optional[str] = None
    role_id: Optional[str] = None
    status: Optional[str] = None


class EmployeeListFilters(BaseModel):
    search: Optional[str] = None
    department_id: Optional[str] = None
    project_id: Optional[str] = None
    location_id: Optional[str] = None
    status: Optional[str] = None
    face_enrolled: Optional[bool] = None
    device_registered: Optional[bool] = None
