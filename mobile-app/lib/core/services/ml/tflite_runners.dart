import 'dart:math' as math;
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import 'model_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EMBEDDING GENERATOR  (MobileFaceNet)
// ─────────────────────────────────────────────────────────────────────────────

/// Runs the MobileFaceNet TFLite model to generate a 192-dim face embedding.
///
/// The returned vector is L2-normalised so cosine similarity == dot product.
///
/// Call [load] once before use. Call [dispose] when done.
class EmbeddingGenerator {
  EmbeddingGenerator._();

  static EmbeddingGenerator? _instance;
  static EmbeddingGenerator get instance {
    _instance ??= EmbeddingGenerator._();
    return _instance!;
  }

  Interpreter? _interpreter;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Load the TFLite model from assets.
  /// Uses GPU/NNAPI delegate on Android, Core ML on iOS where available.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final options = InterpreterOptions();

      // Try GPU delegate for performance; fall back to CPU if unavailable.
      try {
        // Android GPU delegate
        options.addDelegate(GpuDelegateV2());
      } catch (_) {
        // GPU not available — CPU fallback is fine for a 5MB model
      }

      _interpreter = await Interpreter.fromAsset(
        ModelConfig.embeddingModelAsset,
        options: options,
      );
      _loaded = true;
    } catch (e) {
      throw ModelLoadException(
        'Failed to load embedding model '
        '${ModelConfig.embeddingModelAsset}: $e',
      );
    }
  }

  /// Generate a 192-dim L2-normalised embedding from a pre-processed tensor.
  ///
  /// [inputTensor] must be a [Float32List] of length
  /// [ModelConfig.embeddingInputSize]² × 3, normalised to [-1, 1].
  ///
  /// Throws [StateError] if [load] has not been called.
  Float32List generateEmbedding(Float32List inputTensor) {
    if (!_loaded || _interpreter == null) {
      throw StateError('EmbeddingGenerator: call load() first.');
    }

    const size = ModelConfig.embeddingInputSize;
    // Shape: [1, 96, 96, 3]
    final input = inputTensor.reshape([1, size, size, 3]);
    // Output: [1, 192]
    final outputBuffer =
        List.generate(1, (_) => List<double>.filled(ModelConfig.embeddingDimension, 0.0));

    _interpreter!.run(input, outputBuffer);

    final raw = Float32List.fromList(outputBuffer[0].map((v) => v.toDouble()).toList());
    return _l2Normalize(raw);
  }

  /// L2-normalise a vector so ||v|| == 1.
  Float32List _l2Normalize(Float32List v) {
    double norm = 0;
    for (final x in v) { norm += x * x; }
    norm = math.sqrt(norm);
    if (norm < 1e-10) return v;
    final result = Float32List(v.length);
    for (int i = 0; i < v.length; i++) { result[i] = v[i] / norm; }
    return result;
  }

  /// Compute cosine similarity between two L2-normalised embeddings.
  /// Both vectors must have the same length and be L2-normalised.
  static double cosineSimilarity(Float32List a, Float32List b) {
    assert(a.length == b.length, 'Embedding dimension mismatch');
    double dot = 0;
    for (int i = 0; i < a.length; i++) { dot += a[i] * b[i]; }
    // Clamp to [-1, 1] to handle floating-point rounding
    return dot.clamp(-1.0, 1.0);
  }

  void dispose() {
    _interpreter?.close();
    _loaded = false;
    _instance = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANTI-SPOOF RUNNER  (Silent-Face)
// ─────────────────────────────────────────────────────────────────────────────

/// Runs the anti-spoofing TFLite model.
/// Output: [real_prob, spoof_prob] 2-class softmax.
///
/// Call [load] once before use. Call [dispose] when done.
class AntiSpoofRunner {
  AntiSpoofRunner._();

  static AntiSpoofRunner? _instance;
  static AntiSpoofRunner get instance {
    _instance ??= AntiSpoofRunner._();
    return _instance!;
  }

  Interpreter? _interpreter;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final options = InterpreterOptions();
      try {
        options.addDelegate(GpuDelegateV2());
      } catch (_) {}

      _interpreter = await Interpreter.fromAsset(
        ModelConfig.antiSpoofModelAsset,
        options: options,
      );
      _loaded = true;
    } catch (e) {
      throw ModelLoadException(
        'Failed to load anti-spoof model '
        '${ModelConfig.antiSpoofModelAsset}: $e',
      );
    }
  }

  /// Run anti-spoof inference.
  ///
  /// [inputTensor] must be Float32List of length
  /// [ModelConfig.antiSpoofInputSize]² × 3, normalised to [0, 1].
  ///
  /// Returns the probability that the face is REAL (not a spoof).
  double predictRealProbability(Float32List inputTensor) {
    if (!_loaded || _interpreter == null) {
      throw StateError('AntiSpoofRunner: call load() first.');
    }

    const size = ModelConfig.antiSpoofInputSize;
    final input = inputTensor.reshape([1, size, size, 3]);
    // 2-class softmax output: [real_prob, spoof_prob]
    final outputBuffer = List.generate(1, (_) => List<double>.filled(2, 0.0));
    _interpreter!.run(input, outputBuffer);

    final realProb = outputBuffer[0][0].toDouble();
    return realProb.clamp(0.0, 1.0);
  }

  void dispose() {
    _interpreter?.close();
    _loaded = false;
    _instance = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL LOAD EXCEPTION
// ─────────────────────────────────────────────────────────────────────────────

class ModelLoadException implements Exception {
  const ModelLoadException(this.message);
  final String message;

  @override
  String toString() => 'ModelLoadException: $message';
}
