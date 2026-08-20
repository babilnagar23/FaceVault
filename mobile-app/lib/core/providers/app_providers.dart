import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_models.dart';
import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/mock_repositories.dart';
import '../services/face_recognition_service.dart';
import '../services/liveness_detection_service.dart';
import '../services/location_verification_service.dart';

// ─────────────────────────────────────────
// API PROVIDERS (swap mock → real here)
// ─────────────────────────────────────────

final authApiProvider = Provider<AuthApi>((ref) => MockAuthApi());
final userApiProvider = Provider<UserApi>((ref) => MockUserApi());
final attendanceApiProvider = Provider<AttendanceApi>((ref) => MockAttendanceApi());
final announcementApiProvider = Provider<AnnouncementApi>((ref) => MockAnnouncementApi());
final notificationApiProvider = Provider<NotificationApi>((ref) => MockNotificationApi());
final helpApiProvider = Provider<HelpApi>((ref) => MockHelpApi());
final syncApiProvider = Provider<SyncApi>((ref) => MockSyncApi());
final faceEnrollmentApiProvider = Provider<FaceEnrollmentApi>((ref) => MockFaceEnrollmentApi());

// ─────────────────────────────────────────
// SERVICE PROVIDERS
// ─────────────────────────────────────────

final faceRecognitionServiceProvider = Provider<FaceRecognitionService>(
  (ref) => MockFaceRecognitionService(),
);

final livenessServiceProvider = Provider<LivenessDetectionService>(
  (ref) => MockLivenessDetectionService(),
);

final locationServiceProvider = Provider<LocationVerificationService>(
  (ref) => MockLocationVerificationService(),
);

// ─────────────────────────────────────────
// DATA PROVIDERS
// ─────────────────────────────────────────

final currentEmployeeProvider = FutureProvider<Employee>((ref) {
  return ref.watch(userApiProvider).currentEmployee();
});

final attendanceHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) {
  return ref.watch(attendanceApiProvider).history();
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) {
  return ref.watch(announcementApiProvider).announcements();
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationApiProvider).notifications();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final items = await ref.watch(notificationsProvider.future);
  return items.where((n) => !n.read).length;
});

final syncStatusProvider = FutureProvider<SyncState>((ref) {
  return ref.watch(syncApiProvider).status();
});

final myHelpTicketsProvider = FutureProvider<List<HelpTicket>>((ref) {
  return ref.watch(helpApiProvider).myTickets();
});
