"""
FaceVault API — Core Exception Classes
All exceptions derive from FaceVaultException so the global handler
can produce a consistent error envelope.
"""
from typing import Any


class FaceVaultException(Exception):
    """Base exception — maps to a structured JSON error response."""

    status_code: int = 500
    code: str = "INTERNAL_ERROR"
    message: str = "An unexpected error occurred."

    def __init__(
        self,
        message: str | None = None,
        details: dict[str, Any] | None = None,
    ) -> None:
        self.message = message or self.__class__.message
        self.details = details or {}
        super().__init__(self.message)


# ─── 400 Bad Request ─────────────────────────────────────────────────────────


class BadRequestError(FaceVaultException):
    status_code = 400
    code = "BAD_REQUEST"
    message = "Invalid request."


class ValidationError(FaceVaultException):
    status_code = 422
    code = "VALIDATION_ERROR"
    message = "Request validation failed."


# ─── 401 Unauthorized ────────────────────────────────────────────────────────


class AuthenticationError(FaceVaultException):
    status_code = 401
    code = "AUTHENTICATION_FAILED"
    message = "Authentication failed."


class TokenExpiredError(FaceVaultException):
    status_code = 401
    code = "TOKEN_EXPIRED"
    message = "Access token has expired."


class InvalidTokenError(FaceVaultException):
    status_code = 401
    code = "INVALID_TOKEN"
    message = "Invalid or missing token."


# ─── 403 Forbidden ───────────────────────────────────────────────────────────


class PermissionDeniedError(FaceVaultException):
    status_code = 403
    code = "PERMISSION_DENIED"
    message = "You do not have permission to perform this action."


class DeviceRevokedError(FaceVaultException):
    status_code = 403
    code = "DEVICE_REVOKED"
    message = "This device has been revoked."


class OrganizationMismatchError(FaceVaultException):
    status_code = 403
    code = "ORGANIZATION_MISMATCH"
    message = "Access to this resource is not permitted."


# ─── 404 Not Found ───────────────────────────────────────────────────────────


class NotFoundError(FaceVaultException):
    status_code = 404
    code = "NOT_FOUND"
    message = "The requested resource was not found."


class EmployeeNotFoundError(FaceVaultException):
    status_code = 404
    code = "EMPLOYEE_NOT_FOUND"
    message = "Employee not found."


class AssignmentNotFoundError(FaceVaultException):
    status_code = 404
    code = "ASSIGNMENT_NOT_FOUND"
    message = "No active assignment was found."


class LocationNotFoundError(FaceVaultException):
    status_code = 404
    code = "LOCATION_NOT_FOUND"
    message = "Location not found."


class AttendanceNotFoundError(FaceVaultException):
    status_code = 404
    code = "ATTENDANCE_NOT_FOUND"
    message = "Attendance record not found."


# ─── 409 Conflict ────────────────────────────────────────────────────────────


class DuplicateEventError(FaceVaultException):
    status_code = 409
    code = "DUPLICATE_EVENT"
    message = "This event has already been processed (idempotency)."


class DeviceAlreadyRegisteredError(FaceVaultException):
    status_code = 409
    code = "DEVICE_ALREADY_REGISTERED"
    message = "A device is already registered for this user."


# ─── 422 Business Logic ──────────────────────────────────────────────────────


class ShiftViolationError(FaceVaultException):
    status_code = 422
    code = "SHIFT_VIOLATION"
    message = "Check-in is outside the allowed shift window."


class AttendanceAlreadyMarkedError(FaceVaultException):
    status_code = 422
    code = "ATTENDANCE_ALREADY_MARKED"
    message = "Attendance has already been marked for today."
