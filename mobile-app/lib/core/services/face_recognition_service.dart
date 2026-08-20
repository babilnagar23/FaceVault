import '../../data/models/app_models.dart';

// ─────────────────────────────────────────
// ABSTRACT INTERFACE
// ─────────────────────────────────────────

abstract interface class FaceRecognitionService {
  /// Verifies a live face against the enrolled template.
  /// Returns only a safe result — no raw embeddings.
  Future<FaceVerificationResult> verifyLiveFace();
}

// ─────────────────────────────────────────
// MOCK IMPLEMENTATION
// ─────────────────────────────────────────

class MockFaceRecognitionService implements FaceRecognitionService {
  @override
  Future<FaceVerificationResult> verifyLiveFace() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return const FaceVerificationResult(
      verified: true,
      score: 0.992,
    );
  }
}

// Simulates a face recognition failure (for testing exception flows)
class MockFaceFailureService implements FaceRecognitionService {
  @override
  Future<FaceVerificationResult> verifyLiveFace() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const FaceVerificationResult(
      verified: false,
      score: 0.52,
      reason: 'Face not recognised. Ensure adequate lighting and face the camera directly.',
    );
  }
}
