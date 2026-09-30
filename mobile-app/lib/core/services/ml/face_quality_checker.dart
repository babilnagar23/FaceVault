import 'dart:math' as math;
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'model_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FACE QUALITY RESULT
// ─────────────────────────────────────────────────────────────────────────────

enum QualityIssue {
  noFace,
  multipleFaces,
  tooSmall,
  tooLarge,
  offCenter,
  tooDark,
  tooBright,
  tooBlurry,
  badPose,
  occluded,
}

class FaceQualityResult {
  const FaceQualityResult({
    required this.passed,
    this.issue,
    this.userInstruction,
    this.faceAreaRatio = 0.0,
    this.brightness = 0.0,
    this.blurScore = 0.0,
    this.faceCount = 0,
  });

  final bool passed;
  final QualityIssue? issue;

  /// Human-readable instruction shown directly in the UI.
  final String? userInstruction;

  final double faceAreaRatio;
  final double brightness;
  final double blurScore;
  final int faceCount;

  static const FaceQualityResult noFace = FaceQualityResult(
    passed: false,
    issue: QualityIssue.noFace,
    userInstruction: 'No face detected. Please position your face in the frame.',
  );

  static const FaceQualityResult multipleFaces = FaceQualityResult(
    passed: false,
    issue: QualityIssue.multipleFaces,
    userInstruction: 'Only one person should be visible.',
  );

  static const FaceQualityResult offCenter = FaceQualityResult(
    passed: false,
    issue: QualityIssue.offCenter,
    userInstruction: 'Center your face in the oval.',
  );

  static const FaceQualityResult tooSmall = FaceQualityResult(
    passed: false,
    issue: QualityIssue.tooSmall,
    userInstruction: 'Move closer.',
  );

  static const FaceQualityResult tooLarge = FaceQualityResult(
    passed: false,
    issue: QualityIssue.tooLarge,
    userInstruction: 'Move farther away.',
  );

  static const FaceQualityResult tooDark = FaceQualityResult(
    passed: false,
    issue: QualityIssue.tooDark,
    userInstruction: 'Improve lighting — your face appears too dark.',
  );

  static const FaceQualityResult tooBright = FaceQualityResult(
    passed: false,
    issue: QualityIssue.tooBright,
    userInstruction: 'Reduce brightness — your face appears overexposed.',
  );

  static const FaceQualityResult tooBlurry = FaceQualityResult(
    passed: false,
    issue: QualityIssue.tooBlurry,
    userInstruction: 'Hold still — image is blurry.',
  );

  static const FaceQualityResult badPose = FaceQualityResult(
    passed: false,
    issue: QualityIssue.badPose,
    userInstruction: 'Look directly at the camera.',
  );

  static const FaceQualityResult ok = FaceQualityResult(passed: true);
}

// ─────────────────────────────────────────────────────────────────────────────
// FACE QUALITY CHECKER
// ─────────────────────────────────────────────────────────────────────────────

/// Runs quality checks on a detected face without performing ML inference.
/// All checks are pure computation and can run on any isolate.
class FaceQualityChecker {
  const FaceQualityChecker();

  /// Checks quality using MLKit [Face] metadata + raw image luminance.
  ///
  /// [faces]       — detected faces from MLKit FaceDetector.
  /// [imageWidth]  — width of the camera frame in pixels.
  /// [imageHeight] — height of the camera frame in pixels.
  /// [imageBytes]  — raw NV21/YUV luminance plane bytes (Y channel only).
  ///                 Pass null to skip brightness and blur checks.
  FaceQualityResult check({
    required List<Face> faces,
    required int imageWidth,
    required int imageHeight,
    Uint8List? imageBytes,
  }) {
    // ── 1. Face count ────────────────────────────────────────────────────────
    if (faces.isEmpty) return FaceQualityResult.noFace;
    if (faces.length > 1) return FaceQualityResult.multipleFaces;

    final face = faces.first;
    final bbox = face.boundingBox;

    // ── 2. Face area ratio ───────────────────────────────────────────────────
    final frameArea = imageWidth * imageHeight;
    final faceArea = bbox.width * bbox.height;
    final areaRatio = faceArea / frameArea;

    if (areaRatio < ModelConfig.minFaceAreaRatio) return FaceQualityResult.tooSmall;
    if (areaRatio > ModelConfig.maxFaceAreaRatio) return FaceQualityResult.tooLarge;

    // ── 3. Face centering ────────────────────────────────────────────────────
    final frameCx = imageWidth / 2;
    final frameCy = imageHeight / 2;
    final faceCx = bbox.left + bbox.width / 2;
    final faceCy = bbox.top + bbox.height / 2;
    final centerDeviationX = ((faceCx - frameCx) / imageWidth).abs();
    final centerDeviationY = ((faceCy - frameCy) / imageHeight).abs();
    if (centerDeviationX > 0.25 || centerDeviationY > 0.25) {
      return FaceQualityResult.offCenter;
    }

    // ── 4. Pose angles (from MLKit head euler angles) ────────────────────────
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;
    if (yaw.abs() > ModelConfig.maxYawDegrees ||
        pitch.abs() > ModelConfig.maxPitchDegrees ||
        roll.abs() > ModelConfig.maxRollDegrees) {
      return FaceQualityResult.badPose;
    }

    // ── 5. Brightness & blur (if luminance bytes are available) ─────────────
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final bboxLeft = bbox.left.clamp(0.0, imageWidth - 1.0).toInt();
      final bboxTop = bbox.top.clamp(0.0, imageHeight - 1.0).toInt();
      final bboxRight = (bbox.right).clamp(0.0, imageWidth.toDouble()).toInt();
      final bboxBottom = (bbox.bottom).clamp(0.0, imageHeight.toDouble()).toInt();

      final brightnessResult = _computeBrightness(
        imageBytes, imageWidth, bboxLeft, bboxTop, bboxRight, bboxBottom,
      );
      if (brightnessResult < ModelConfig.minBrightness) return FaceQualityResult.tooDark;
      if (brightnessResult > ModelConfig.maxBrightness) return FaceQualityResult.tooBright;

      final blurScore = _computeBlur(
        imageBytes, imageWidth, bboxLeft, bboxTop, bboxRight, bboxBottom,
      );
      if (blurScore < ModelConfig.maxBlurLaplacian) return FaceQualityResult.tooBlurry;
    }

    // ── 6. Occlusion — check eye probability ─────────────────────────────────
    final leftEyeOpenProb = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpenProb = face.rightEyeOpenProbability ?? 1.0;
    // If both eyes have very low probability they may be occluded/covered
    if (leftEyeOpenProb < 0.1 && rightEyeOpenProb < 0.1) {
      return const FaceQualityResult(
        passed: false,
        issue: QualityIssue.occluded,
        userInstruction: 'Remove any obstruction from your face.',
      );
    }

    return FaceQualityResult(
      passed: true,
      faceAreaRatio: areaRatio,
      blurScore: 0.0, // populated above if bytes provided
      faceCount: 1,
    );
  }

  /// Compute mean luminance of the face region.
  double _computeBrightness(
    Uint8List yPlane,
    int width,
    int left,
    int top,
    int right,
    int bottom,
  ) {
    double sum = 0;
    int count = 0;
    for (int y = top; y < bottom; y++) {
      for (int x = left; x < right; x++) {
        final idx = y * width + x;
        if (idx < yPlane.length) {
          sum += yPlane[idx] & 0xFF;
          count++;
        }
      }
    }
    return count > 0 ? sum / count : 128.0;
  }

  /// Approximate Laplacian variance (blur metric) over the face region.
  /// Higher value = sharper image. Below threshold = too blurry.
  double _computeBlur(
    Uint8List yPlane,
    int width,
    int left,
    int top,
    int right,
    int bottom,
  ) {
    // Sample every 4th pixel for performance.
    double sum = 0;
    double sumSq = 0;
    int count = 0;
    for (int y = top + 1; y < bottom - 1; y += 2) {
      for (int x = left + 1; x < right - 1; x += 2) {
        final idx = y * width + x;
        if (idx + width + 1 < yPlane.length && idx - width - 1 >= 0) {
          final center = (yPlane[idx] & 0xFF).toDouble();
          final n = (yPlane[(y - 1) * width + x] & 0xFF).toDouble();
          final s = (yPlane[(y + 1) * width + x] & 0xFF).toDouble();
          final e = (yPlane[y * width + (x + 1)] & 0xFF).toDouble();
          final w = (yPlane[y * width + (x - 1)] & 0xFF).toDouble();
          final lap = (4 * center - n - s - e - w).abs();
          sum += lap;
          sumSq += lap * lap;
          count++;
        }
      }
    }
    if (count == 0) return 100.0;
    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    return math.max(0, variance);
  }
}
