import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/app_models.dart';
import '../face_recognition_service.dart';
import '../liveness_detection_service.dart';
import '../location_verification_service.dart';
import '../sync/attendance_outbox.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ATTENDANCE PIPELINE COORDINATOR
// ─────────────────────────────────────────────────────────────────────────────

/// Orchestrates the full attendance verification pipeline:
///
///   Face → Liveness → Location → Backend handoff (or offline queue)
///
/// The coordinator accepts abstract service interfaces so the same pipeline
/// works with real (on-device ML + GPS) or mock services.
///
/// Network connectivity is NEVER a prerequisite for local AI verification.
/// Results come exclusively from the real services — no hardcoded scores.
class AttendancePipelineCoordinator {
  AttendancePipelineCoordinator({
    required FaceRecognitionService faceService,
    required LivenessDetectionService livenessService,
    required LocationVerificationService locationService,
    required AttendanceOutbox outbox,
    required Connectivity connectivity,
    required Dio dio,
  })  : _faceService = faceService,
        _livenessService = livenessService,
        _locationService = locationService,
        _outbox = outbox,
        _connectivity = connectivity,
        _dio = dio;

  final FaceRecognitionService _faceService;
  final LivenessDetectionService _livenessService;
  final LocationVerificationService _locationService;
  final AttendanceOutbox _outbox;
  final Connectivity _connectivity;
  final Dio _dio;

  static const _uuid = Uuid();

  // ── Run ───────────────────────────────────────────────────────────────────

  /// Execute the full pipeline and return a complete [AttendanceVerificationResult].
  ///
  /// [onStep] is called as each pipeline step starts so the UI can update
  /// its progress display.
  Future<AttendanceVerificationResult> run({
    void Function(AttendancePipelineStep step)? onStep,
  }) async {
    final now = DateTime.now();
    final clientEventId = _uuid.v4();

    // ── Step 1: Face Verification ──────────────────────────────────────────
    onStep?.call(AttendancePipelineStep.face);
    final faceResult = await _faceService.verifyLiveFace();

    if (!faceResult.verified) {
      return _failResult(
        clientEventId: clientEventId,
        now: now,
        faceResult: faceResult,
        reason: faceResult.reason ?? 'Face verification failed.',
        status: AttendanceStatus.faceFailed,
      );
    }

    // ── Step 2: Liveness ───────────────────────────────────────────────────
    onStep?.call(AttendancePipelineStep.liveness);
    final livenessResult = await _livenessService.checkLiveness();

    if (!livenessResult.passed) {
      return _failResult(
        clientEventId: clientEventId,
        now: now,
        faceResult: faceResult,
        livenessResult: livenessResult,
        reason: livenessResult.reason ?? 'Liveness check failed.',
        status: AttendanceStatus.livenessFailed,
      );
    }

    // ── Step 3: Location ───────────────────────────────────────────────────
    onStep?.call(AttendancePipelineStep.location);
    final locationResult = await _locationService.verify();

    // ── Step 4: Determine attendance status ───────────────────────────────
    final attendanceStatus = locationResult.verified
        ? AttendanceStatus.present
        : AttendanceStatus.locationError;

    final verifyResult = AttendanceVerificationResult(
      faceVerified: faceResult.verified,
      faceScore: faceResult.score,
      livenessVerified: livenessResult.passed,
      livenessScore: livenessResult.score,
      livenessStatus: livenessResult.status,
      locationVerified: locationResult.verified,
      distanceMeters: locationResult.distanceMeters,
      gpsAccuracyMeters: locationResult.gpsAccuracyMeters,
      assignedSite: locationResult.assignedSite,
      latitude: locationResult.latitude,
      longitude: locationResult.longitude,
      timestamp: now,
      attendanceStatus: attendanceStatus,
      syncStatus: SyncState.pending,
      clientEventId: clientEventId,
      failureReason: locationResult.verified ? null : locationResult.failureReason,
    );

    // ── Step 5: Backend handoff ────────────────────────────────────────────
    onStep?.call(AttendancePipelineStep.sync);
    await _submitOrQueue(verifyResult);

    return verifyResult.copyWith(
      syncStatus: await _currentSyncState(verifyResult),
    );
  }

  // ── Backend submission ────────────────────────────────────────────────────

  Future<void> _submitOrQueue(AttendanceVerificationResult result) async {
    final event = AttendanceOutboxEvent(
      clientEventId: result.clientEventId ?? _uuid.v4(),
      eventType: 'CHECK_IN',
      clientTimestamp: result.timestamp,
      faceVerified: result.faceVerified,
      faceScore: result.faceScore,
      livenessVerified: result.livenessVerified,
      livenessScore: result.livenessScore,
      locationVerified: result.locationVerified,
      latitude: result.latitude,
      longitude: result.longitude,
      gpsAccuracyMeters: result.gpsAccuracyMeters.toDouble(),
      assignedSite: result.assignedSite,
      distanceMeters: result.distanceMeters,
      offlineCreated: false, // will update if offline
    );

    // Check connectivity
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = !connectivity.contains(ConnectivityResult.none);

    if (isOnline) {
      try {
        await _dio.post('/attendance/attempt', data: event.toJson());
        // If successful, no need to queue
        return;
      } catch (_) {
        // Fall through to offline queue
      }
    }

    // Offline or failed online → enqueue
    await _outbox.enqueue(
      eventType: 'CHECK_IN',
      event: AttendanceOutboxEvent(
        clientEventId: event.clientEventId,
        eventType: event.eventType,
        clientTimestamp: event.clientTimestamp,
        faceVerified: event.faceVerified,
        faceScore: event.faceScore,
        livenessVerified: event.livenessVerified,
        livenessScore: event.livenessScore,
        locationVerified: event.locationVerified,
        latitude: event.latitude,
        longitude: event.longitude,
        gpsAccuracyMeters: event.gpsAccuracyMeters,
        assignedSite: event.assignedSite,
        distanceMeters: event.distanceMeters,
        offlineCreated: true,
      ),
    );
  }

  Future<SyncState> _currentSyncState(AttendanceVerificationResult result) async {
    final pendingCount = await _outbox.pendingCount();
    return pendingCount > 0 ? SyncState.pending : SyncState.synced;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  AttendanceVerificationResult _failResult({
    required String clientEventId,
    required DateTime now,
    required FaceVerificationResult faceResult,
    LivenessResult? livenessResult,
    required String reason,
    required AttendanceStatus status,
  }) {
    return AttendanceVerificationResult(
      faceVerified: faceResult.verified,
      faceScore: faceResult.score,
      livenessVerified: livenessResult?.passed ?? false,
      livenessScore: livenessResult?.score ?? 0.0,
      livenessStatus: livenessResult?.status ?? LivenessStatus.checking,
      locationVerified: false,
      distanceMeters: 0,
      gpsAccuracyMeters: 0,
      assignedSite: '',
      latitude: 0.0,
      longitude: 0.0,
      timestamp: now,
      attendanceStatus: status,
      syncStatus: SyncState.pending,
      clientEventId: clientEventId,
      failureReason: reason,
    );
  }
}

/// Pipeline step enum for UI progress display.
enum AttendancePipelineStep { face, liveness, location, sync }

// ─────────────────────────────────────────────────────────────────────────────
// COPY-WITH EXTENSION
// ─────────────────────────────────────────────────────────────────────────────

extension AttendanceVerificationResultX on AttendanceVerificationResult {
  AttendanceVerificationResult copyWith({
    bool? faceVerified,
    double? faceScore,
    bool? livenessVerified,
    double? livenessScore,
    LivenessStatus? livenessStatus,
    bool? locationVerified,
    int? distanceMeters,
    int? gpsAccuracyMeters,
    String? assignedSite,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    AttendanceStatus? attendanceStatus,
    SyncState? syncStatus,
    String? clientEventId,
    String? failureReason,
  }) {
    return AttendanceVerificationResult(
      faceVerified: faceVerified ?? this.faceVerified,
      faceScore: faceScore ?? this.faceScore,
      livenessVerified: livenessVerified ?? this.livenessVerified,
      livenessScore: livenessScore ?? this.livenessScore,
      livenessStatus: livenessStatus ?? this.livenessStatus,
      locationVerified: locationVerified ?? this.locationVerified,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
      assignedSite: assignedSite ?? this.assignedSite,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      clientEventId: clientEventId ?? this.clientEventId,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}
