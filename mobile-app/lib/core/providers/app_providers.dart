import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_models.dart';
import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/mock_repositories.dart';

final authApiProvider = Provider<AuthApi>((ref) => MockAuthApi());
final userApiProvider = Provider<UserApi>((ref) => MockUserApi());
final attendanceApiProvider = Provider<AttendanceApi>((ref) => MockAttendanceApi());
final announcementApiProvider = Provider<AnnouncementApi>((ref) => MockAnnouncementApi());
final notificationApiProvider = Provider<NotificationApi>((ref) => MockNotificationApi());
final helpApiProvider = Provider<HelpApi>((ref) => MockHelpApi());
final syncApiProvider = Provider<SyncApi>((ref) => MockSyncApi());

final currentEmployeeProvider = FutureProvider<Employee>((ref) {
  return ref.watch(userApiProvider).currentEmployee();
});

final attendanceHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) {
  return ref.watch(attendanceApiProvider).history();
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) {
  return ref.watch(announcementApiProvider).announcements();
});

final notificationsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(notificationApiProvider).notifications();
});

final syncStatusProvider = FutureProvider<SyncState>((ref) {
  return ref.watch(syncApiProvider).status();
});

