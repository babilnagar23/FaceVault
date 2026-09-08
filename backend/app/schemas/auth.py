"""Auth request/response schemas."""
from pydantic import BaseModel, EmailStr, field_validator


class EmployeeLoginRequest(BaseModel):
    employee_id: str
    password: str

    @field_validator("employee_id")
    @classmethod
    def clean_employee_id(cls, v: str) -> str:
        return v.strip().upper()


class AdminLoginRequest(BaseModel):
    organisation_code: str
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds


class RefreshRequest(BaseModel):
    refresh_token: str


class UserInToken(BaseModel):
    id: str
    employee_code: str
    full_name: str
    email: str
    role: str
    organization_id: str
    face_enrolled: bool
    device_registered: bool
    first_device_login: bool = False


class LoginResponse(BaseModel):
    tokens: TokenResponse
    user: UserInToken


class ForgotPasswordRequest(BaseModel):
    employee_id: str | None = None
    email: EmailStr | None = None


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str
