import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:facevault_mobile/core/services/ml/model_config.dart';

void main() {
  group('ML Model Validation', () {
    test('MobileFaceNet conforms to exact contract', () async {
      try {
        final interpreter = await Interpreter.fromAsset(ModelConfig.embeddingModelAsset);
        
        final inputTensors = interpreter.getInputTensors();
        final outputTensors = interpreter.getOutputTensors();

        expect(inputTensors.length, 1, reason: 'Expected exactly 1 input tensor');
        expect(outputTensors.length, 1, reason: 'Expected exactly 1 output tensor');

        final inputShape = inputTensors.first.shape;
        expect(inputShape, [1, ModelConfig.embeddingInputSize, ModelConfig.embeddingInputSize, 3],
            reason: 'Input shape mismatch');

        final outputShape = outputTensors.first.shape;
        expect(outputShape, [1, ModelConfig.embeddingDimension],
            reason: 'Output shape mismatch');

        interpreter.close();
      } catch (e) {
        if (e is ArgumentError || e.toString().contains('Unable to create interpreter')) {
          fail('BLOCKED: Model file is invalid or missing. Expected valid MobileFaceNet TFLite model at ${ModelConfig.embeddingModelAsset}. Error: $e');
        } else {
          rethrow;
        }
      }
    });

    test('AntiSpoof model conforms to exact contract', () async {
      try {
        final interpreter = await Interpreter.fromAsset(ModelConfig.antiSpoofModelAsset);
        
        final inputTensors = interpreter.getInputTensors();
        final outputTensors = interpreter.getOutputTensors();

        expect(inputTensors.length, 1, reason: 'Expected exactly 1 input tensor');
        expect(outputTensors.length, 1, reason: 'Expected exactly 1 output tensor');

        final inputShape = inputTensors.first.shape;
        expect(inputShape, [1, ModelConfig.antiSpoofInputSize, ModelConfig.antiSpoofInputSize, 3],
            reason: 'Input shape mismatch');

        final outputShape = outputTensors.first.shape;
        expect(outputShape, [1, 2], reason: 'Output shape mismatch (expected [1, 2] for real/spoof probs)');

        interpreter.close();
      } catch (e) {
        if (e is ArgumentError || e.toString().contains('Unable to create interpreter')) {
          fail('BLOCKED: Model file is invalid or missing. Expected valid AntiSpoof TFLite model at ${ModelConfig.antiSpoofModelAsset}. Error: $e');
        } else {
          rethrow;
        }
      }
    });
  });
}
