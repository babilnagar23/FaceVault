import '../models/app_models.dart';

// ─────────────────────────────────────────
// AUTH
// ─────────────────────────────────────────

abstract interface class AuthApi {
  Future<bool> hasSession();
  Future<LoginResult> login(String employeeId, String password);
  Future<void> logout();
}

class LoginResult {
  const LoginResult({
    required this.authenticated,
    required this.firstDeviceLogin,
    this.message,
    this.employeeId,
  });

  final bool authenticated;
  final bool firstDeviceLogin;
  final String? message;
  final String? employeeId;
}

// ─────────────────────────────────────────
// USER / EMPLOYEE
// ─────────────────────────────────────────

abstract interface class UserApi {
  Future<Employee> currentEmployee();
  Future<DeviceMetadata> deviceMetadata();
  Future<DeviceMetadata> registerDevice();
}

// ─────────────────────────────────────────
// ATTENDANCE
// ─────────────────────────────────────────

abstract interface class AttendanceApi {
  Future<AttendanceRecord> markAttendance();
  Future<List<AttendanceRecord>> history();
  Future<AttendanceRecord> detail(String id);
  Future<AttendanceVerificationResult> runVerification();
}

// ─────────────────────────────────────────
// ANNOUNCEMENTS
// ─────────────────────────────────────────

abstract interface class AnnouncementApi {
  Future<List<Announcement>> announcements();
  Future<Announcement> detail(String id);
  Future<void> acknowledge(String id);
}

// ─────────────────────────────────────────
// NOTIFICATIONS
// ─────────────────────────────────────────

abstract interface class NotificationApi {
  Future<List<AppNotification>> notifications();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

// ─────────────────────────────────────────
// HELP
// ─────────────────────────────────────────

abstract interface class HelpApi {
  Future<List<String>> issueTypes();
  Future<HelpTicket> createTicket({
    required String issueType,
    required String description,
  });
  Future<HelpTicket> detail(String id);
  Future<List<HelpTicket>> myTickets();
}

// ─────────────────────────────────────────
// SYNC
// ─────────────────────────────────────────

abstract interface class SyncApi {
  Future<SyncState> status();
  Future<void> enqueue(String type, Map<String, Object?> payload);
  Future<void> flush();
  Future<List<SyncItem>> pendingItems();
}

// ─────────────────────────────────────────
// FACE ENROLLMENT
// ─────────────────────────────────────────

abstract interface class FaceEnrollmentApi {
  Future<bool> isEnrolled();
  Future<void> startEnrollment();
  Future<void> completeEnrollment();
}
