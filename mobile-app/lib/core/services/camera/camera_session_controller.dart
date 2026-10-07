import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'camera_frame_bus.dart';

class CameraSessionController {
  CameraController? _controller;
  final CameraFrameBus _frameBus;
  
  bool _isInitialized = false;
  bool _isStreaming = false;

  CameraSessionController(this._frameBus);

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isStreaming => _isStreaming;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => throw Exception('No front camera available'),
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    _isInitialized = true;
  }

  Future<void> startImageStream() async {
    if (!_isInitialized || _controller == null || _isStreaming) return;
    
    await _controller!.startImageStream((CameraImage image) {
      _frameBus.publish(image);
    });
    _isStreaming = true;
  }

  Future<void> stopImageStream() async {
    if (!_isStreaming || _controller == null) return;
    await _controller!.stopImageStream();
    _isStreaming = false;
  }

  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
