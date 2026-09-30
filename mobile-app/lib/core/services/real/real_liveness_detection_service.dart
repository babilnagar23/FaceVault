import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';

import '../../../data/models/app_models.dart';
import '../liveness_detection_service.dart';
import '../ml/face_aligner.dart';
import '../ml/face_detector_service.dart';
import '../ml/face_quality_checker.dart';
import '../ml/model_config.dart';
import '../ml/tflite_runners.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REAL LIVENESS DETECTION SERVICE
// ─────────────────────────────────────────────────────────────────────────────

/// Runs genuine on-device anti-spoof inference using the Silent-Face TFLite
/// model via [AntiSpoofRunner].
///
/// Usage:
///   1. Call [prepareFromRawBytes] with a live camera frame bytes + dimensions.
///   2. Call [checkLiveness] to get the result.
///
/// The service is designed to be used once per attendance session.
/// It does NOT access the network.
class RealLivenessDetectionService implements LivenessDetectionService {
  RealLivenessDetectionService({
    required AntiSpoofRunner antiSpoofRunner,
    required FaceDetectorService faceDetector,
    required FaceAligner aligner,
    required FaceQualityChecker qualityChecker,
    Duration timeout = const Duration(seconds: 15),
  })  : _antiSpoofRunner = antiSpoofRunner,
        _faceDetector = faceDetector,
        _aligner = aligner,
        _timeout = timeout;

  final AntiSpoofRunner _antiSpoofRunner;
  final FaceDetectorService _faceDetector;
  final FaceAligner _aligner;
  final Duration _timeout;

  // The camera image set by [prepareFromCameraImage].
  CameraImage? _cameraImage;
  Uint8List? _imageBytesArgb;
  int _imageWidth = 0;
  int _imageHeight = 0;

  // ── Session setup ─────────────────────────────────────────────────────────

  /// Prime the service with a captured camera frame for next [checkLiveness] call.
  void prepareFromCameraImage({
    required CameraImage cameraImage,
    required Uint8List argbBytes,
    required int width,
    required int height,
  }) {
    _cameraImage = cameraImage;
    _imageBytesArgb = argbBytes;
    _imageWidth = width;
    _imageHeight = height;
  }

  // ── LivenessDetectionService implementation ───────────────────────────────

  @override
  Future<LivenessResult> checkLiveness() async {
    if (_cameraImage == null || _imageBytesArgb == null) {
      return const LivenessResult(
        passed: false,
        score: 0.0,
        reason: 'No camera frame prepared. Please try again.',
        status: LivenessStatus.error,
      );
    }

    if (!_antiSpoofRunner.isLoaded) {
      return const LivenessResult(
        passed: false,
        score: 0.0,
        reason: 'Anti-spoofing model is not available on this device.',
        status: LivenessStatus.unsupported,
      );
    }

    try {
      return await Future.any([
        _runLiveness(),
        Future<LivenessResult>.delayed(
          _timeout,
          () => const LivenessResult(
            passed: false,
            score: 0.0,
            reason: 'Liveness check timed out. Please try again.',
            status: LivenessStatus.timeout,
          ),
        ),
      ]);
    } catch (e) {
      return LivenessResult(
        passed: false,
        score: 0.0,
        reason: 'Liveness check error: $e',
        status: LivenessStatus.error,
      );
    }
  }

  Future<LivenessResult> _runLiveness() async {
    // 1. Re-detect face in the prepared frame for accurate bounding box
    final faces = await _faceDetector.detectFaces(_cameraImage!);

    if (faces.isEmpty) {
      return const LivenessResult(
        passed: false,
        score: 0.0,
        reason: 'No face detected during liveness check.',
        status: LivenessStatus.failed,
      );
    }
    if (faces.length > 1) {
      return const LivenessResult(
        passed: false,
        score: 0.0,
        reason: 'Multiple faces detected. Only one person should be visible.',
        status: LivenessStatus.failed,
      );
    }

    // 2. Align face for anti-spoof model (128×128, [0,1])
    final tensor = _aligner.alignFaceForAntiSpoof(
      _imageBytesArgb!,
      imageWidth: _imageWidth,
      imageHeight: _imageHeight,
      face: faces.first,
    );

    if (tensor == null) {
      return const LivenessResult(
        passed: false,
        score: 0.0,
        reason: 'Face region is out of frame. Please center your face.',
        status: LivenessStatus.failed,
      );
    }

    // 3. Run anti-spoof inference
    final realProb = _antiSpoofRunner.predictRealProbability(tensor);
    final passed = realProb >= ModelConfig.livenessThreshold;

    return LivenessResult(
      passed: passed,
      score: realProb,
      status: passed ? LivenessStatus.passed : LivenessStatus.failed,
      reason: passed
          ? null
          : 'Liveness check failed. Please look directly at the camera and ensure you are a real person.',
    );
  }
}
