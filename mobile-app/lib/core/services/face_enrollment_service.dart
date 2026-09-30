// No external model imports needed — all types are defined in this file.


// ─────────────────────────────────────────────────────────────────────────────
// FACE ENROLLMENT SERVICE — ABSTRACT INTERFACE
// ─────────────────────────────────────────────────────────────────────────────

/// Service interface for on-device face enrollment.
///
/// Implementations perform the full enrollment pipeline:
///   camera → detection → quality check → liveness → embedding generation
///   → secure local storage → backend metadata notification.
///
/// The UI should call [startEnrollmentSession] then iteratively call
/// [captureEnrollmentSample] for each required pose step.
/// Call [finaliseEnrollment] to commit.
abstract interface class FaceEnrollmentService {
  /// Called when enrollment begins.
  Future<void> startEnrollmentSession(String employeeId);

  /// Capture one enrollment sample (a specific pose/angle).
  ///
  /// Returns quality result and instructions for the next action.
  Future<EnrollmentSampleResult> captureEnrollmentSample(EnrollmentPose pose);

  /// Compute the final averaged embedding from all captured samples,
  /// store it securely, and notify the backend.
  ///
  /// Returns an [EnrollmentResult] with the outcome.
  Future<EnrollmentResult> finaliseEnrollment();

  /// Cancel and clean up any in-progress session.
  Future<void> cancelEnrollmentSession();
}

// ─────────────────────────────────────────────────────────────────────────────
// ENROLLMENT MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum EnrollmentPose {
  straight,
  slightRight,
  slightLeft,
  chinUp,
  chinDown,
}

class EnrollmentSampleResult {
  const EnrollmentSampleResult({
    required this.captured,
    required this.pose,
    this.qualityScore = 0.0,
    this.instruction,
    this.livenessScore = 0.0,
    this.livenessPass = false,
  });

  final bool captured;
  final EnrollmentPose pose;
  final double qualityScore;
  final String? instruction;
  final double livenessScore;
  final bool livenessPass;
}

class EnrollmentResult {
  const EnrollmentResult({
    required this.success,
    required this.samplesCaptures,
    required this.averageQualityScore,
    required this.averageLivenessScore,
    this.failureReason,
  });

  final bool success;
  final int samplesCaptures;
  final double averageQualityScore;
  final double averageLivenessScore;
  final String? failureReason;
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

class MockFaceEnrollmentService implements FaceEnrollmentService {
  @override
  Future<void> startEnrollmentSession(String employeeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<EnrollmentSampleResult> captureEnrollmentSample(
    EnrollmentPose pose,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return EnrollmentSampleResult(
      captured: true,
      pose: pose,
      qualityScore: 0.92,
      livenessScore: 0.95,
      livenessPass: true,
    );
  }

  @override
  Future<EnrollmentResult> finaliseEnrollment() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const EnrollmentResult(
      success: true,
      samplesCaptures: 5,
      averageQualityScore: 0.93,
      averageLivenessScore: 0.96,
    );
  }

  @override
  Future<void> cancelEnrollmentSession() async {}
}

class MockEnrollmentFailureService implements FaceEnrollmentService {
  @override
  Future<void> startEnrollmentSession(String employeeId) async {}

  @override
  Future<EnrollmentSampleResult> captureEnrollmentSample(
    EnrollmentPose pose,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const EnrollmentSampleResult(
      captured: false,
      pose: EnrollmentPose.straight,
      qualityScore: 0.28,
      instruction: 'Improve lighting — your face appears too dark.',
    );
  }

  @override
  Future<EnrollmentResult> finaliseEnrollment() async {
    return const EnrollmentResult(
      success: false,
      samplesCaptures: 0,
      averageQualityScore: 0.0,
      averageLivenessScore: 0.0,
      failureReason: 'Insufficient samples captured for enrollment.',
    );
  }

  @override
  Future<void> cancelEnrollmentSession() async {}
}
