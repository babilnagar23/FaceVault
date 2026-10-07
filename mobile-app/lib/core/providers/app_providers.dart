import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/app_models.dart';
import '../../data/repositories/app_repositories.dart';
import '../../data/repositories/mock_repositories.dart';
import '../services/face_enrollment_service.dart';
import '../services/face_recognition_service.dart';
import '../services/liveness_detection_service.dart';
import '../services/location_verification_service.dart';
import '../services/ml/face_aligner.dart';
import '../services/ml/face_detector_service.dart';
import '../services/ml/face_quality_checker.dart';
import '../services/ml/tflite_runners.dart';
import '../services/real/attendance_pipeline_coordinator.dart';
import '../services/real/real_face_enrollment_service.dart';
import '../services/real/real_face_recognition_service.dart';
import '../services/real/real_liveness_detection_service.dart';
import '../services/real/real_location_verification_service.dart';
import '../services/storage/biometric_template_store.dart';
import '../services/storage/site_assignment_cache.dart';
import '../services/sync/attendance_outbox.dart';
import '../services/camera/camera_frame_bus.dart';
import '../services/camera/camera_session_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE FLAGS
// ─────────────────────────────────────────────────────────────────────────────

/// Set to [true] to use real on-device ML services.
/// Set to [false] for UI development / automated tests.
const bool kUseRealServices = true;

/// Set to [true] in integration tests to use failure mocks.
const bool kUseFailureMocks = false;

// ─────────────────────────────────────────────────────────────────────────────
// INFRASTRUCTURE PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: 'https://api.facevault.example.com/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));
});

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// CAMERA PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final cameraFrameBusProvider = Provider<CameraFrameBus>((ref) {
  final bus = CameraFrameBus();
  ref.onDispose(() => bus.dispose());
  return bus;
});

final cameraSessionProvider = Provider<CameraSessionController>((ref) {
  final bus = ref.watch(cameraFrameBusProvider);
  final controller = CameraSessionController(bus);
  ref.onDispose(() => controller.dispose());
  return controller;
});

// ─────────────────────────────────────────────────────────────────────────────
// ML COMPONENT PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final faceDetectorServiceProvider = Provider<FaceDetectorService>((ref) {
  final service = FaceDetectorService.instance;
  ref.onDispose(() => service.dispose());
  return service;
});

final embeddingGeneratorProvider = Provider<EmbeddingGenerator>((ref) {
  final gen = EmbeddingGenerator.instance;
  ref.onDispose(() => gen.dispose());
  return gen;
});

final antiSpoofRunnerProvider = Provider<AntiSpoofRunner>((ref) {
  final runner = AntiSpoofRunner.instance;
  ref.onDispose(() => runner.dispose());
  return runner;
});

final faceAlignerProvider = Provider<FaceAligner>((_) => const FaceAligner());

final faceQualityCheckerProvider = Provider<FaceQualityChecker>(
  (_) => const FaceQualityChecker(),
);

// ─────────────────────────────────────────────────────────────────────────────
// STORAGE PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final biometricTemplateStoreProvider = Provider<BiometricTemplateStore>((ref) {
  return BiometricTemplateStore();
});

final siteAssignmentCacheProvider = Provider<SiteAssignmentCache>((ref) {
  return SiteAssignmentCache();
});

final attendanceOutboxProvider = Provider<AttendanceOutbox>((ref) {
  return AttendanceOutbox();
});

// ─────────────────────────────────────────────────────────────────────────────
// API PROVIDERS (swap mock → real here)
// ─────────────────────────────────────────────────────────────────────────────

final authApiProvider = Provider<AuthApi>((ref) => MockAuthApi());
final userApiProvider = Provider<UserApi>((ref) => MockUserApi());
final attendanceApiProvider = Provider<AttendanceApi>((ref) => MockAttendanceApi());
final announcementApiProvider = Provider<AnnouncementApi>((ref) => MockAnnouncementApi());
final notificationApiProvider = Provider<NotificationApi>((ref) => MockNotificationApi());
final helpApiProvider = Provider<HelpApi>((ref) => MockHelpApi());
final syncApiProvider = Provider<SyncApi>((ref) => MockSyncApi());
final faceEnrollmentApiProvider = Provider<FaceEnrollmentApi>((ref) => MockFaceEnrollmentApi());

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE PROVIDERS  (real vs mock switchable via kUseRealServices)
// ─────────────────────────────────────────────────────────────────────────────

/// The logged-in employee ID — read from session/secure storage in production.
/// Currently seeded with the mock employee ID.
final currentEmployeeIdProvider = Provider<String>((ref) => 'EMP-1042');

final faceRecognitionServiceProvider = Provider<FaceRecognitionService>((ref) {
  if (!kUseRealServices) {
    return kUseFailureMocks
        ? MockFaceFailureService()
        : MockFaceRecognitionService();
  }
  return RealFaceRecognitionService(
    embeddingGenerator: ref.watch(embeddingGeneratorProvider),
    faceDetector: ref.watch(faceDetectorServiceProvider),
    aligner: ref.watch(faceAlignerProvider),
    qualityChecker: ref.watch(faceQualityCheckerProvider),
    templateStore: ref.watch(biometricTemplateStoreProvider),
    frameBus: ref.watch(cameraFrameBusProvider),
    employeeId: ref.watch(currentEmployeeIdProvider),
  );
});

final livenessServiceProvider = Provider<LivenessDetectionService>((ref) {
  if (!kUseRealServices) {
    return kUseFailureMocks
        ? MockLivenessFailureService()
        : MockLivenessDetectionService();
  }
  final service = RealLivenessDetectionService(
    antiSpoofRunner: ref.watch(antiSpoofRunnerProvider),
    faceDetector: ref.watch(faceDetectorServiceProvider),
    aligner: ref.watch(faceAlignerProvider),
    qualityChecker: ref.watch(faceQualityCheckerProvider),
  );
  return service as LivenessDetectionService;
});


final locationServiceProvider = Provider<LocationVerificationService>((ref) {
  if (!kUseRealServices) {
    return kUseFailureMocks
        ? MockLocationFailureService()
        : MockLocationVerificationService();
  }
  return RealLocationVerificationService(
    assignmentCache: ref.watch(siteAssignmentCacheProvider),
  );
});

final faceEnrollmentServiceProvider = Provider<FaceEnrollmentService>((ref) {
  if (!kUseRealServices) {
    return kUseFailureMocks
        ? MockEnrollmentFailureService()
        : MockFaceEnrollmentService();
  }
  return RealFaceEnrollmentService(
    embeddingGenerator: ref.watch(embeddingGeneratorProvider),
    antiSpoofRunner: ref.watch(antiSpoofRunnerProvider),
    faceDetector: ref.watch(faceDetectorServiceProvider),
    aligner: ref.watch(faceAlignerProvider),
    qualityChecker: ref.watch(faceQualityCheckerProvider),
    templateStore: ref.watch(biometricTemplateStoreProvider),
    frameBus: ref.watch(cameraFrameBusProvider),
    dio: ref.watch(dioProvider),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// ATTENDANCE PIPELINE COORDINATOR
// ─────────────────────────────────────────────────────────────────────────────

final attendancePipelineProvider = Provider<AttendancePipelineCoordinator>((ref) {
  return AttendancePipelineCoordinator(
    faceService: ref.watch(faceRecognitionServiceProvider),
    livenessService: ref.watch(livenessServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    outbox: ref.watch(attendanceOutboxProvider),
    connectivity: ref.watch(connectivityProvider),
    dio: ref.watch(dioProvider),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// DATA PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

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

final offlinePendingCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(attendanceOutboxProvider).pendingCount();
});
