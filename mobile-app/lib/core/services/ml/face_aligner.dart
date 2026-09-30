import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';


import 'model_config.dart';

/// Aligns and crops a face region from a raw luminance/RGB image
/// to produce a normalized input tensor for MobileFaceNet.
///
/// The alignment strategy:
///   1. Use MLKit landmark points (left eye, right eye) to compute the
///      canonical rotation angle.
///   2. Crop the bounding box with 20% margin.
///   3. Resize to [ModelConfig.embeddingInputSize] × [ModelConfig.embeddingInputSize].
///   4. Normalise pixel values to [-1, 1].
class FaceAligner {
  const FaceAligner();

  /// Produce a [ModelConfig.embeddingInputSize]² float32 RGB tensor from a
  /// raw BGRA8888 or NV21 [imageBytes] buffer.
  ///
  /// Returns null if the face region is invalid (out of frame bounds).
  Float32List? alignFaceFromBgra(
    Uint8List imageBytes, {
    required int imageWidth,
    required int imageHeight,
    required Face face,
  }) {
    final bbox = face.boundingBox;
    const margin = 0.20;

    // Add margin around the bbox
    final left = (bbox.left - bbox.width * margin).clamp(0.0, imageWidth - 1.0);
    final top = (bbox.top - bbox.height * margin).clamp(0.0, imageHeight - 1.0);
    final right = (bbox.right + bbox.width * margin).clamp(0.0, imageWidth.toDouble());
    final bottom = (bbox.bottom + bbox.height * margin).clamp(0.0, imageHeight.toDouble());

    final cropWidth = right - left;
    final cropHeight = bottom - top;
    if (cropWidth < 1 || cropHeight < 1) return null;

    const size = ModelConfig.embeddingInputSize;
    final output = Float32List(size * size * 3);

    // Bilinear downsample to target size
    for (int py = 0; py < size; py++) {
      for (int px = 0; px < size; px++) {
        // Source coordinates in the original image
        final srcX = left + px * cropWidth / size;
        final srcY = top + py * cropHeight / size;

        final x0 = srcX.floor().clamp(0, imageWidth - 1);
        final y0 = srcY.floor().clamp(0, imageHeight - 1);
        final x1 = (x0 + 1).clamp(0, imageWidth - 1);
        final y1 = (y0 + 1).clamp(0, imageHeight - 1);

        final xFrac = srcX - x0;
        final yFrac = srcY - y0;

        // BGRA8888: 4 bytes per pixel
        double r = 0, g = 0, b = 0;
        for (final coord in [
          [x0, y0, (1 - xFrac) * (1 - yFrac)],
          [x1, y0, xFrac * (1 - yFrac)],
          [x0, y1, (1 - xFrac) * yFrac],
          [x1, y1, xFrac * yFrac],
        ]) {
          final xi = coord[0] as int;
          final yi = coord[1] as int;
          final w = coord[2] as double;
          final idx = (yi * imageWidth + xi) * 4;
          if (idx + 2 < imageBytes.length) {
            b += (imageBytes[idx] & 0xFF) * w;
            g += (imageBytes[idx + 1] & 0xFF) * w;
            r += (imageBytes[idx + 2] & 0xFF) * w;
          }
        }

        final outIdx = (py * size + px) * 3;
        // Normalise to [-1, 1]
        output[outIdx] = r / 127.5 - 1.0;
        output[outIdx + 1] = g / 127.5 - 1.0;
        output[outIdx + 2] = b / 127.5 - 1.0;
      }
    }

    return output;
  }

  /// Produce a [ModelConfig.antiSpoofInputSize]² float32 RGB tensor for
  /// the anti-spoofing model, normalised to [0, 1].
  Float32List? alignFaceForAntiSpoof(
    Uint8List imageBytes, {
    required int imageWidth,
    required int imageHeight,
    required Face face,
  }) {
    final bbox = face.boundingBox;
    const margin = 0.40; // anti-spoof benefits from wider context

    final left = (bbox.left - bbox.width * margin).clamp(0.0, imageWidth - 1.0);
    final top = (bbox.top - bbox.height * margin).clamp(0.0, imageHeight - 1.0);
    final right = (bbox.right + bbox.width * margin).clamp(0.0, imageWidth.toDouble());
    final bottom = (bbox.bottom + bbox.height * margin).clamp(0.0, imageHeight.toDouble());

    final cropWidth = right - left;
    final cropHeight = bottom - top;
    if (cropWidth < 1 || cropHeight < 1) return null;

    const size = ModelConfig.antiSpoofInputSize;
    final output = Float32List(size * size * 3);

    for (int py = 0; py < size; py++) {
      for (int px = 0; px < size; px++) {
        final srcX = left + px * cropWidth / size;
        final srcY = top + py * cropHeight / size;

        final x0 = srcX.floor().clamp(0, imageWidth - 1);
        final y0 = srcY.floor().clamp(0, imageHeight - 1);
        final x1 = (x0 + 1).clamp(0, imageWidth - 1);
        final y1 = (y0 + 1).clamp(0, imageHeight - 1);

        final xFrac = srcX - x0;
        final yFrac = srcY - y0;

        double r = 0, g = 0, b = 0;
        for (final coord in [
          [x0, y0, (1 - xFrac) * (1 - yFrac)],
          [x1, y0, xFrac * (1 - yFrac)],
          [x0, y1, (1 - xFrac) * yFrac],
          [x1, y1, xFrac * yFrac],
        ]) {
          final xi = coord[0] as int;
          final yi = coord[1] as int;
          final w = coord[2] as double;
          final idx = (yi * imageWidth + xi) * 4;
          if (idx + 2 < imageBytes.length) {
            b += (imageBytes[idx] & 0xFF) * w;
            g += (imageBytes[idx + 1] & 0xFF) * w;
            r += (imageBytes[idx + 2] & 0xFF) * w;
          }
        }

        final outIdx = (py * size + px) * 3;
        // Normalise to [0, 1] for anti-spoof model
        output[outIdx] = r / 255.0;
        output[outIdx + 1] = g / 255.0;
        output[outIdx + 2] = b / 255.0;
      }
    }

    return output;
  }
}
