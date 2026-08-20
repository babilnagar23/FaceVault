// ─────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────

enum SyncState { synced, syncing, offline, pending, failed }

enum AttendanceStatus {
  notMarked,
  present,
  absent,
  late,
  leave,
  locationError,
  faceFailed,
  livenessFailed,
  pendingReview,
  pendingSync,
}

enum BiometricStatus { notEnrolled, pending, enrolled, rejected, reEnrollRequired }

enum DeviceStatus { registered, pending, revoked, missing }

enum PermissionStatus { notAsked, granted, denied, permanentlyDenied }

enum LivenessStatus { checking, passed, failed, timeout, unsupported }

enum TicketStatus { open, inProgress, urgent, resolved, rejected }

// ─────────────────────────────────────────
// VERIFICATION RESULTS
// ─────────────────────────────────────────

class FaceVerificationResult {
  const FaceVerificationResult({
    required this.verified,
    required this.score,
    this.reason,
  });

  final bool verified;
  final double score;
  final String? reason;
}

class LivenessResult {
  const LivenessResult({
    required this.passed,
    required this.score,
    this.reason,
  });

  final bool passed;
  final double score;
  final String? reason;
}

class LocationVerificationResult {
  const LocationVerificationResult({
    required this.verified,
    required this.assignedSite,
    required this.distanceMeters,
    required this.gpsAccuracyMeters,
    required this.latitude,
    required this.longitude,
    this.failureReason,
  });

  final bool verified;
  final String assignedSite;
  final int distanceMeters;
  final int gpsAccuracyMeters;
  final double latitude;
  final double longitude;
  final String? failureReason;
}

class AttendanceVerificationResult {
  const AttendanceVerificationResult({
    required this.faceVerified,
    required this.faceScore,
    required this.livenessVerified,
    required this.livenessScore,
    required this.locationVerified,
    required this.distanceMeters,
    required this.gpsAccuracyMeters,
    required this.assignedSite,
    required this.timestamp,
    required this.attendanceStatus,
    required this.syncStatus,
    this.failureReason,
  });

  final bool faceVerified;
  final double faceScore;
  final bool livenessVerified;
  final double livenessScore;
  final bool locationVerified;
  final int distanceMeters;
  final int gpsAccuracyMeters;
  final String assignedSite;
  final DateTime timestamp;
  final AttendanceStatus attendanceStatus;
  final SyncState syncStatus;
  final String? failureReason;
}

// ─────────────────────────────────────────
// DOMAIN MODELS
// ─────────────────────────────────────────

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.role,
    required this.project,
    required this.location,
    required this.shift,
    required this.faceEnrolled,
    required this.deviceRegistered,
    this.siteCode,
    this.zone,
    this.managerName,
    this.avatarInitials,
  });

  final String id;
  final String name;
  final String department;
  final String role;
  final String project;
  final String location;
  final String shift;
  final bool faceEnrolled;
  final bool deviceRegistered;
  final String? siteCode;
  final String? zone;
  final String? managerName;
  final String? avatarInitials;

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    required this.checkInTime,
    required this.assignedSite,
    required this.distanceMeters,
    required this.faceStatus,
    required this.livenessStatus,
    required this.locationStatus,
    required this.syncStatus,
    required this.remarks,
    this.checkOutTime,
    this.faceScore,
    this.livenessScore,
    this.gpsAccuracy,
  });

  final String id;
  final DateTime date;
  final AttendanceStatus status;
  final String checkInTime;
  final String assignedSite;
  final int distanceMeters;
  final String faceStatus;
  final String livenessStatus;
  final String locationStatus;
  final SyncState syncStatus;
  final String remarks;
  final String? checkOutTime;
  final double? faceScore;
  final double? livenessScore;
  final int? gpsAccuracy;
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.category,
    required this.body,
    required this.pinned,
    required this.urgent,
    required this.read,
    required this.acknowledged,
    required this.publishedAt,
    this.publisher,
  });

  final String id;
  final String title;
  final String category;
  final String body;
  final bool pinned;
  final bool urgent;
  final bool read;
  final bool acknowledged;
  final DateTime publishedAt;
  final String? publisher;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.timestamp,
  });

  final String id;
  final String type; // attendance, announcement, help, shift, system, verification
  final String title;
  final String body;
  final bool read;
  final DateTime timestamp;
}

class HelpTicket {
  const HelpTicket({
    required this.id,
    required this.issueType,
    required this.description,
    required this.status,
    required this.createdAt,
    this.employeeId,
    this.employeeName,
  });

  final String id;
  final String issueType;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? employeeId;
  final String? employeeName;
}

class DeviceMetadata {
  const DeviceMetadata({
    required this.name,
    required this.model,
    required this.osVersion,
    required this.appVersion,
    required this.registered,
  });

  final String name;
  final String model;
  final String osVersion;
  final String appVersion;
  final bool registered;
}

class SyncItem {
  const SyncItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  final String id;
  final String type;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final int retryCount;
}
