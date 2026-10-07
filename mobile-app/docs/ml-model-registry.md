# ML Model Registry

This registry tracks the provenances of all machine learning models used in the FaceVault mobile application.

## 1. Face Embedding Model
- **Filename:** `mobilefacenet.tflite`
- **Version:** `1.0.0`
- **Status:** **MISSING / INVALID** (Currently a 1-byte placeholder)
- **Source:** TBD
- **License:** TBD
- **SHA-256:** TBD
- **Input Shape:** `[1, 96, 96, 3]`
- **Input DType:** `Float32`
- **Preprocessing:** Normalization to `[-1, 1]`
- **Output Shape:** `[1, 192]`
- **Output DType:** `Float32`
- **Expected Semantics:** 192-dimensional embedding vector representing face features.

## 2. Anti-Spoofing (Liveness) Model
- **Filename:** `anti_spoof.tflite`
- **Version:** `1.0.0`
- **Status:** **MISSING / INVALID** (Currently a 1-byte placeholder)
- **Source:** TBD
- **License:** TBD
- **SHA-256:** TBD
- **Input Shape:** `[1, 128, 128, 3]`
- **Input DType:** `Float32`
- **Preprocessing:** Normalization to `[0, 1]`
- **Output Shape:** `[1, 2]`
- **Output DType:** `Float32`
- **Expected Semantics:** 2-class softmax where index 0 is REAL probability and index 1 is SPOOF probability.
