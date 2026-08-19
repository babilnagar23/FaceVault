import '../models/app_models.dart';

abstract interface class AuthApi {
  Future<bool> hasSession();
  Future<LoginResult> login(String employeeId, String password);
  Future<void> logout();
}

abstract interface class UserApi {
  Future<Employee> currentEmployee();
  Future<DeviceMetadata> deviceMetadata();
  Future<DeviceMetadata> registerDevice();
}

abstract interface class AttendanceApi {
  Future<AttendanceRecord> markAttendance();
  Future<List<AttendanceRecord>> history();
  Future<AttendanceRecord> detail(String id);
}

abstract interface class AnnouncementApi {
  Future<List<Announcement>> announcements();
}

abstract interface class NotificationApi {
  Future<List<String>> notifications();
}

abstract interface class HelpApi {
  Future<List<String>> issueTypes();
  Future<HelpTicket> createTicket({
    required String issueType,
    required String description,
  });
}

abstract interface class SyncApi {
  Future<SyncState> status();
  Future<void> enqueue(String type, Map<String, Object?> payload);
  Future<void> flush();
}

class LoginResult {
  const LoginResult({
    required this.authenticated,
    required this.firstDeviceLogin,
    this.message,
  });

  final bool authenticated;
  final bool firstDeviceLogin;
  final String? message;
}

