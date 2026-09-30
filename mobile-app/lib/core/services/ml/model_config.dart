/// Model configuration — single source of truth for all ML model parameters.
///
/// These values are compile-time constants. They must match the bundled model files.
/// Do NOT change without updating the corresponding .tflite asset.
class ModelConfig {
  ModelConfig._();

  // ── Face Embedding (MobileFaceNet) ───────────────────────────────────────
  static const String embeddingModelName = 'mobilefacenet';
  static const String embeddingModelVersion = '1.0.0';
  static const String embeddingModelAsset = 'assets/models/mobilefacenet.tflite';
  static const int embeddingInputSize = 96; // width & height in pixels
  static const int embeddingDimension = 192;
  static const double verificationThreshold = 0.75; // cosine similarity ≥ threshold → match

  // ── Anti-Spoofing / Liveness (Silent-Face) ──────────────────────────────
  static const String antiSpoofModelName = 'anti_spoof_mini';
  static const String antiSpoofModelVersion = '1.0.0';
  static const String antiSpoofModelAsset = 'assets/models/anti_spoof.tflite';
  static const int antiSpoofInputSize = 128; // width & height in pixels
  static const double livenessThreshold = 0.60; // real_prob ≥ threshold → live

  // ── Quality thresholds ───────────────────────────────────────────────────
  static const double minFaceAreaRatio = 0.05; // face bbox area / frame area
  static const double maxFaceAreaRatio = 0.90;
  static const double minBrightness = 40.0; // 0–255 scale mean luma
  static const double maxBrightness = 220.0;
  static const double maxBlurLaplacian = 60.0; // Laplacian variance; below = too blurry
  static const double maxYawDegrees = 25.0;
  static const double maxPitchDegrees = 20.0;
  static const double maxRollDegrees = 20.0;

  // ── Inference cadence ────────────────────────────────────────────────────
  /// Only one quality-check inference per [qualityCheckIntervalMs] milliseconds.
  static const int qualityCheckIntervalMs = 500;
  /// Full verification pipeline triggered once per session (not every frame).
  /// Quality checks run at cadence; verification runs once on user action.
  static const int maxVerificationAttempts = 3;
}
