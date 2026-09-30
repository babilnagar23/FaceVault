import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Wraps [FaceDetector] from google_mlkit_face_detection.
///
/// Works entirely on-device — no network call required.
/// Dispose [FaceDetectorService] when the camera session ends.
class FaceDetectorService {
  FaceDetectorService._();

  static FaceDetectorService? _instance;
  static FaceDetectorService get instance {
    _instance ??= FaceDetectorService._();
    return _instance!;
  }

  late final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // eye-open probability for occlusion check
      enableLandmarks: true,      // landmarks for alignment
      enableTracking: false,      // not needed for single-shot verification
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.10,          // ignore tiny faces < 10% of image width
    ),
  );

  bool _disposed = false;

  /// Detect faces in a [CameraImage].
  ///
  /// Returns an empty list if no face is found.
  /// Throws [FaceDetectionException] on unrecoverable error.
  Future<List<Face>> detectFaces(CameraImage image) async {
    if (_disposed) throw StateError('FaceDetectorService has been disposed.');

    final inputImage = _buildInputImage(image);
    if (inputImage == null) return [];

    try {
      return await _detector.processImage(inputImage);
    } catch (e) {
      throw FaceDetectionException('MLKit face detection failed: $e');
    }
  }

  /// Convert [CameraImage] to MLKit [InputImage].
  ///
  /// Handles NV21 (Android) and BGRA8888 (iOS).
  InputImage? _buildInputImage(CameraImage image) {
    final format = image.format.group;

    if (format == ImageFormatGroup.nv21) {
      return InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } else if (format == ImageFormatGroup.bgra8888) {
      return InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } else if (format == ImageFormatGroup.yuv420) {
      final y = image.planes[0].bytes;
      final u = image.planes[1].bytes;
      final v = image.planes[2].bytes;
      final nv21 = _yuv420ToNv21(y, u, v, image.width, image.height);
      return InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    }

    return null;
  }

  /// Convert YUV420 planes to NV21 byte array.
  Uint8List _yuv420ToNv21(
    Uint8List y,
    Uint8List u,
    Uint8List v,
    int width,
    int height,
  ) {
    final nv21 = Uint8List(
      width * height + 2 * ((width + 1) ~/ 2) * ((height + 1) ~/ 2),
    );
    nv21.setAll(0, y);
    int uvIndex = width * height;
    for (int i = 0; i < u.length; i++) {
      nv21[uvIndex++] = v[i];
      nv21[uvIndex++] = u[i];
    }
    return nv21;
  }

  /// Extracts the raw Y (luminance) plane bytes from a [CameraImage].
  /// Returns null if the format doesn't expose a clear Y plane.
  Uint8List? extractLuminancePlane(CameraImage image) {
    final format = image.format.group;
    if (format == ImageFormatGroup.nv21 || format == ImageFormatGroup.yuv420) {
      return image.planes.first.bytes;
    }
    return null;
  }

  void dispose() {
    if (!_disposed) {
      _detector.close();
      _disposed = true;
      _instance = null;
    }
  }
}

class FaceDetectionException implements Exception {
  const FaceDetectionException(this.message);
  final String message;

  @override
  String toString() => 'FaceDetectionException: $message';
}
