import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';

import '../camera/camera_frame_bus.dart';

import '../../../data/models/app_models.dart';
import '../face_recognition_service.dart';
import '../ml/face_aligner.dart';
import '../ml/face_detector_service.dart';
import '../ml/face_quality_checker.dart';
import '../ml/model_config.dart';
import '../ml/tflite_runners.dart';
import '../storage/biometric_template_store.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REAL FACE RECOGNITION SERVICE
// ─────────────────────────────────────────────────────────────────────────────

/// Full on-device face verification pipeline:
///
///   Camera frame
///     → MLKit face detection
///     → quality checks
///     → face alignment + crop
///     → MobileFaceNet embedding
///     → secure template load
///     → cosine similarity comparison
///     → [FaceVerificationResult]
///
/// Network is NEVER accessed during this flow.
///
/// The service is wired through [FaceRecognitionService] abstraction so the
/// UI layer is decoupled from the implementation.
class RealFaceRecognitionService implements FaceRecognitionService {
  RealFaceRecognitionService({
    required EmbeddingGenerator embeddingGenerator,
    required FaceDetectorService faceDetector,
    required FaceAligner aligner,
    required FaceQualityChecker qualityChecker,
    required BiometricTemplateStore templateStore,
    required CameraFrameBus frameBus,
    required String employeeId,
  })  : _embeddingGenerator = embeddingGenerator,
        _faceDetector = faceDetector,
        _aligner = aligner,
        _qualityChecker = qualityChecker,
        _templateStore = templateStore,
        _frameBus = frameBus,
        _employeeId = employeeId;

  final EmbeddingGenerator _embeddingGenerator;
  final FaceDetectorService _faceDetector;
  final FaceAligner _aligner;
  final FaceQualityChecker _qualityChecker;
  final BiometricTemplateStore _templateStore;
  final CameraFrameBus _frameBus;
  final String _employeeId;



  // ── FaceRecognitionService implementation ─────────────────────────────────

  @override
  Future<FaceVerificationResult> verifyLiveFace() async {
    // 1. Capture a fresh frame
    final frame = _frameBus.latestFrame;
    if (frame == null) {
      return const FaceVerificationResult(
        verified: false,
        score: 0.0,
        reason: 'Camera is not ready. Please wait and try again.',
      );
    }

    // 2. Check models are loaded
    if (!_embeddingGenerator.isLoaded) {
      return const FaceVerificationResult(
        verified: false,
        score: 0.0,
        reason: 'Face recognition model is not available on this device.',
      );
    }

    try {
      // 3. Detect faces
      final faces = await _faceDetector.detectFaces(frame);

      // 4. Quality checks (before expensive ML inference)
      final yPlane = _faceDetector.extractLuminancePlane(frame);
      final quality = _qualityChecker.check(
        faces: faces,
        imageWidth: frame.width,
        imageHeight: frame.height,
        imageBytes: yPlane,
      );

      if (!quality.passed) {
        return FaceVerificationResult(
          verified: false,
          score: 0.0,
          reason: quality.userInstruction ?? 'Face quality check failed.',
        );
      }

      // 5. Convert frame to BGRA8888 for aligner
      final argbBytes = _toArgbBytes(frame);
      if (argbBytes == null) {
        return const FaceVerificationResult(
          verified: false,
          score: 0.0,
          reason: 'Camera format not supported on this device.',
        );
      }

      // 6. Align face and generate embedding
      final inputTensor = _aligner.alignFaceFromBgra(
        argbBytes,
        imageWidth: frame.width,
        imageHeight: frame.height,
        face: faces.first,
      );

      if (inputTensor == null) {
        return const FaceVerificationResult(
          verified: false,
          score: 0.0,
          reason: 'Face is partially out of frame. Please center your face.',
        );
      }

      // 7. Generate L2-normalised embedding (native thread via TFLite)
      final liveEmbedding = _embeddingGenerator.generateEmbedding(inputTensor);

      // 8. Load enrolled template
      final enrolledEmbedding = await _templateStore.loadTemplate(_employeeId);

      if (enrolledEmbedding == null) {
        return const FaceVerificationResult(
          verified: false,
          score: 0.0,
          reason: 'No enrolled face template found. Please complete face enrollment first.',
        );
      }

      // 9. Compute cosine similarity
      final score = EmbeddingGenerator.cosineSimilarity(
        liveEmbedding,
        enrolledEmbedding,
      );

      // 10. Apply threshold
      final verified = score >= ModelConfig.verificationThreshold;

      return FaceVerificationResult(
        verified: verified,
        score: score,
        reason: verified
            ? null
            : 'Face not recognised. Ensure adequate lighting and face the camera directly.',
      );
    } on ModelLoadException catch (e) {
      return FaceVerificationResult(
        verified: false,
        score: 0.0,
        reason: 'Model error: ${e.message}',
      );
    } catch (e) {
      return const FaceVerificationResult(
        verified: false,
        score: 0.0,
        reason: 'An unexpected error occurred during face verification.',
      );
    }
  }

  // ── Format conversion ─────────────────────────────────────────────────────

  /// Convert a [CameraImage] to a flat BGRA8888 byte array for the aligner.
  ///
  /// On iOS, the camera produces BGRA8888 natively.
  /// On Android (NV21/YUV420), we convert to BGRA.
  Uint8List? _toArgbBytes(CameraImage image) {
    final format = image.format.group;

    if (format == ImageFormatGroup.bgra8888) {
      return image.planes.first.bytes;
    }

    if (format == ImageFormatGroup.nv21 ||
        format == ImageFormatGroup.yuv420) {
      return _yuv420ToBgra(image);
    }

    return null;
  }

  /// Fast YUV420/NV21 → BGRA8888 conversion.
  Uint8List _yuv420ToBgra(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final Uint8List out = Uint8List(width * height * 4);

    final yPlane = image.planes[0].bytes;
    final uvPlane = image.planes.length > 1 ? image.planes[1].bytes : null;
    final vuPlane = image.planes.length > 2 ? image.planes[2].bytes : null;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yVal = (yPlane[y * image.planes[0].bytesPerRow + x] & 0xFF).toDouble();

        double u = 128.0, v = 128.0;
        if (uvPlane != null) {
          // NV21: VUVUVU layout in plane 1 (or separate planes)
          final uvRow = (y ~/ 2) * (image.planes[1].bytesPerRow);
          final uvCol = (x ~/ 2) * 2;
          final uvIdx = uvRow + uvCol;
          if (uvIdx < uvPlane.length) {
            if (image.format.group == ImageFormatGroup.nv21) {
              v = (uvPlane[uvIdx] & 0xFF).toDouble();
              u = uvIdx + 1 < uvPlane.length
                  ? (uvPlane[uvIdx + 1] & 0xFF).toDouble()
                  : 128.0;
            } else {
              // YUV420: separate U/V planes
              u = (uvPlane[uvIdx ~/ 2] & 0xFF).toDouble();
              v = vuPlane != null ? (vuPlane[uvIdx ~/ 2] & 0xFF).toDouble() : 128.0;
            }
          }
        }

        // BT.601 YUV → RGB
        final r = (yVal + 1.402 * (v - 128)).clamp(0, 255).toInt();
        final g = (yVal - 0.344136 * (u - 128) - 0.714136 * (v - 128)).clamp(0, 255).toInt();
        final b = (yVal + 1.772 * (u - 128)).clamp(0, 255).toInt();

        final idx = (y * width + x) * 4;
        out[idx] = b;       // B
        out[idx + 1] = g;   // G
        out[idx + 2] = r;   // R
        out[idx + 3] = 255; // A
      }
    }
    return out;
  }
}
