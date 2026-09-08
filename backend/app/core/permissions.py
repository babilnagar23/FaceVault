"""
FaceVault API — RBAC Permission Constants and Role Definitions
"""
from enum import StrEnum


class Role(StrEnum):
    OWNER = "OWNER"
    ADMIN = "ADMIN"
    HR = "HR"
    MANAGER = "MANAGER"
    SUPERVISOR = "SUPERVISOR"
    EMPLOYEE = "EMPLOYEE"


class Permission(StrEnum):
    # Employee management
    EMPLOYEE_READ = "EMPLOYEE_READ"
    EMPLOYEE_CREATE = "EMPLOYEE_CREATE"
    EMPLOYEE_UPDATE = "EMPLOYEE_UPDATE"
    EMPLOYEE_DELETE = "EMPLOYEE_DELETE"

    # Attendance
    ATTENDANCE_READ = "ATTENDANCE_READ"
    ATTENDANCE_APPROVE = "ATTENDANCE_APPROVE"
    ATTENDANCE_REJECT = "ATTENDANCE_REJECT"

    # Location management
    LOCATION_READ = "LOCATION_READ"
    LOCATION_CREATE = "LOCATION_CREATE"
    LOCATION_UPDATE = "LOCATION_UPDATE"
    LOCATION_DELETE = "LOCATION_DELETE"

    # Biometrics
    BIOMETRIC_READ = "BIOMETRIC_READ"
    BIOMETRIC_MANAGE = "BIOMETRIC_MANAGE"

    # Help desk
    HELP_READ = "HELP_READ"
    HELP_RESPOND = "HELP_RESPOND"

    # Announcements
    ANNOUNCEMENT_READ = "ANNOUNCEMENT_READ"
    ANNOUNCEMENT_MANAGE = "ANNOUNCEMENT_MANAGE"

    # Reports
    REPORT_READ = "REPORT_READ"
    REPORT_EXPORT = "REPORT_EXPORT"

    # Audit
    AUDIT_READ = "AUDIT_READ"

    # Settings
    SETTINGS_READ = "SETTINGS_READ"
    SETTINGS_UPDATE = "SETTINGS_UPDATE"

    # Projects / Shifts / Assignments
    PROJECT_READ = "PROJECT_READ"
    PROJECT_MANAGE = "PROJECT_MANAGE"
    SHIFT_READ = "SHIFT_READ"
    SHIFT_MANAGE = "SHIFT_MANAGE"
    ASSIGNMENT_READ = "ASSIGNMENT_READ"
    ASSIGNMENT_MANAGE = "ASSIGNMENT_MANAGE"


# Default permissions per role (can be overridden by org settings)
ROLE_DEFAULT_PERMISSIONS: dict[Role, set[Permission]] = {
    Role.OWNER: set(Permission),  # all permissions
    Role.ADMIN: set(Permission),  # all permissions
    Role.HR: {
        Permission.EMPLOYEE_READ,
        Permission.EMPLOYEE_CREATE,
        Permission.EMPLOYEE_UPDATE,
        Permission.ATTENDANCE_READ,
        Permission.ATTENDANCE_APPROVE,
        Permission.ATTENDANCE_REJECT,
        Permission.BIOMETRIC_READ,
        Permission.BIOMETRIC_MANAGE,
        Permission.HELP_READ,
        Permission.HELP_RESPOND,
        Permission.ANNOUNCEMENT_READ,
        Permission.ANNOUNCEMENT_MANAGE,
        Permission.REPORT_READ,
        Permission.REPORT_EXPORT,
        Permission.SHIFT_READ,
        Permission.ASSIGNMENT_READ,
        Permission.ASSIGNMENT_MANAGE,
        Permission.LOCATION_READ,
        Permission.PROJECT_READ,
    },
    Role.MANAGER: {
        Permission.EMPLOYEE_READ,
        Permission.ATTENDANCE_READ,
        Permission.ATTENDANCE_APPROVE,
        Permission.ATTENDANCE_REJECT,
        Permission.LOCATION_READ,
        Permission.HELP_READ,
        Permission.HELP_RESPOND,
        Permission.ANNOUNCEMENT_READ,
        Permission.REPORT_READ,
        Permission.SHIFT_READ,
        Permission.ASSIGNMENT_READ,
        Permission.PROJECT_READ,
    },
    Role.SUPERVISOR: {
        Permission.EMPLOYEE_READ,
        Permission.ATTENDANCE_READ,
        Permission.LOCATION_READ,
        Permission.HELP_READ,
        Permission.ANNOUNCEMENT_READ,
        Permission.SHIFT_READ,
        Permission.PROJECT_READ,
    },
    Role.EMPLOYEE: {
        Permission.ANNOUNCEMENT_READ,
        Permission.HELP_READ,
        Permission.LOCATION_READ,
        Permission.PROJECT_READ,
        Permission.SHIFT_READ,
    },
}
