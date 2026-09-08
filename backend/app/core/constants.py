"""
FaceVault API — Application-wide constants
"""

# Attendance attempt status codes (what happened during the scan)
class AttemptStatus:
    VERIFIED = "VERIFIED"
    FACE_FAILED = "FACE_FAILED"
    LIVENESS_FAILED = "LIVENESS_FAILED"
    LOCATION_FAILED = "LOCATION_FAILED"
    GPS_FAILED = "GPS_FAILED"
    DEVICE_INVALID = "DEVICE_INVALID"
    SHIFT_INVALID = "SHIFT_INVALID"
    PENDING_REVIEW = "PENDING_REVIEW"
    DUPLICATE = "DUPLICATE"
    REJECTED = "REJECTED"


# Official attendance record status (the authoritative state)
class AttendanceRecordStatus:
    PRESENT = "PRESENT"
    ABSENT = "ABSENT"
    LATE = "LATE"
    LEAVE = "LEAVE"
    PENDING_REVIEW = "PENDING_REVIEW"
    APPROVED_EXCEPTION = "APPROVED_EXCEPTION"
    REJECTED = "REJECTED"


# Attendance event types
class AttendanceEventType:
    CHECK_IN = "CHECK_IN"
    CHECK_OUT = "CHECK_OUT"


# Device status
class DeviceStatus:
    PENDING = "PENDING"
    REGISTERED = "REGISTERED"
    REVOKED = "REVOKED"
    MISSING = "MISSING"


# Biometric enrollment status
class BiometricStatus:
    NOT_ENROLLED = "NOT_ENROLLED"
    PENDING = "PENDING"
    ENROLLED = "ENROLLED"
    REJECTED = "REJECTED"
    RE_ENROLL_REQUIRED = "RE_ENROLL_REQUIRED"


# Sync event outcomes
class SyncOutcome:
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"
    CONFLICT = "CONFLICT"
    ALREADY_PROCESSED = "ALREADY_PROCESSED"


# Help ticket status
class TicketStatus:
    OPEN = "OPEN"
    IN_PROGRESS = "IN_PROGRESS"
    URGENT = "URGENT"
    RESOLVED = "RESOLVED"
    REJECTED = "REJECTED"


# Announcement status
class AnnouncementStatus:
    DRAFT = "DRAFT"
    SCHEDULED = "SCHEDULED"
    PUBLISHED = "PUBLISHED"
    ARCHIVED = "ARCHIVED"


# Verification queue status
class VerificationStatus:
    NEEDS_REVIEW = "NEEDS_REVIEW"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    PENDING_EXPLANATION = "PENDING_EXPLANATION"


# Report export status
class ExportStatus:
    QUEUED = "QUEUED"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


# Risk flags for fraud detection
class RiskFlag:
    POOR_GPS_ACCURACY = "POOR_GPS_ACCURACY"
    IMPOSSIBLE_MOVEMENT = "IMPOSSIBLE_MOVEMENT"
    FUTURE_TIMESTAMP = "FUTURE_TIMESTAMP"
    LARGE_CLOCK_DRIFT = "LARGE_CLOCK_DRIFT"
    MOCK_LOCATION_SUSPECTED = "MOCK_LOCATION_SUSPECTED"
    DUPLICATE_COORDINATES = "DUPLICATE_COORDINATES"
    DEVICE_MISMATCH = "DEVICE_MISMATCH"
    SUSPICIOUS_SEQUENCE = "SUSPICIOUS_SEQUENCE"
