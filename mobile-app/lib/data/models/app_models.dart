enum SyncState { synced, syncing, offline, pending }

enum AttendanceStatus {
  notMarked,
  present,
  absent,
  late,
  leave,
  locationError,
  faceFailed,
  pendingReview,
  pendingSync,
}

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
  });

  final String id;
  final String title;
  final String category;
  final String body;
  final bool pinned;
  final bool urgent;
  final bool read;
  final bool acknowledged;
}

class HelpTicket {
  const HelpTicket({
    required this.id,
    required this.issueType,
    required this.description,
    required this.status,
  });

  final String id;
  final String issueType;
  final String description;
  final String status;
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

