# FaceVault ML Models

## Required Models

Place the following TFLite model files in this directory before building:

### 1. mobilefacenet.tflite
- **Source**: https://github.com/sirius-ai/MobileFaceNet_TF (converted to TFLite)
- **Input**: 96×96×3 float32 normalized to [-1, 1]
- **Output**: 192-dimensional float32 embedding vector
- **Size**: ~5MB
- **License**: Apache 2.0

### 2. anti_spoof.tflite
- **Source**: Silent-Face-Anti-Spoofing by minivision-ai (TFLite export)
- **Input**: 128×128×3 float32 normalized to [0, 1]
- **Output**: 2-class softmax [real_prob, spoof_prob]
- **Size**: ~1.2MB
- **License**: MIT

## Model Registry (model_config.json)
Configuration is embedded in ModelConfig class in:
  lib/core/services/ml/model_config.dart

## Download Script
Run from project root:
  dart run scripts/download_models.dart

## Security Note
Models are bundled in the APK/IPA and never downloaded at runtime.
This ensures offline operation in airplane mode.
