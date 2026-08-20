import '../../data/models/app_models.dart';

// ─────────────────────────────────────────
// ABSTRACT INTERFACE
// ─────────────────────────────────────────

abstract interface class LivenessDetectionService {
  /// Checks liveness — anti-spoofing verification.
  /// UI receives only a safe LivenessResult.
  Future<LivenessResult> checkLiveness();
}

// ─────────────────────────────────────────
// MOCK IMPLEMENTATION
// ─────────────────────────────────────────

class MockLivenessDetectionService implements LivenessDetectionService {
  @override
  Future<LivenessResult> checkLiveness() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const LivenessResult(passed: true, score: 0.97);
  }
}

class MockLivenessFailureService implements LivenessDetectionService {
  @override
  Future<LivenessResult> checkLiveness() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return const LivenessResult(
      passed: false,
      score: 0.31,
      reason: 'Liveness check failed. Please look directly at the camera and try again.',
    );
  }
}
