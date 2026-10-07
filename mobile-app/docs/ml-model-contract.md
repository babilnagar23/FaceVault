# ML Model Contract

This document defines the EXACT expectations for the TFLite models used in the FaceVault mobile application. Any model provided to the application must strictly adhere to this contract.

## MobileFaceNet (Face Embedding)
- **File Name:** `mobilefacenet.tflite`
- **Input Shape:** `[1, 96, 96, 3]` (Batch=1, Height=96, Width=96, Channels=3 RGB)
- **Input DType:** `Float32`
- **Input Normalization:** `[-1, 1]` (e.g., `(pixel - 127.5) / 128.0`)
- **Output Shape:** `[1, 192]`
- **Output DType:** `Float32`
- **Embedding Dimension:** `192`
- **Semantics:** Outputs a 192-dimensional vector. The application will L2-normalize the output before computing cosine similarity.

## AntiSpoof (Liveness Detection)
- **File Name:** `anti_spoof.tflite`
- **Input Shape:** `[1, 128, 128, 3]` (Batch=1, Height=128, Width=128, Channels=3 RGB)
- **Input DType:** `Float32`
- **Input Normalization:** `[0, 1]` (e.g., `pixel / 255.0`)
- **Output Shape:** `[1, 2]`
- **Output DType:** `Float32`
- **Class Mapping:** 
  - `Index 0`: Probability that the face is REAL (Live).
  - `Index 1`: Probability that the face is SPOOF (Fake/Printed/Screen).
- **Semantics:** Outputs a 2-class softmax probability distribution.
