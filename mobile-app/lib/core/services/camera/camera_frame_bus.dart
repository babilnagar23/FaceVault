import 'dart:async';
import 'package:camera/camera.dart';

class CameraFrameBus {
  final _streamController = StreamController<CameraImage>.broadcast();
  CameraImage? _latestFrame;

  Stream<CameraImage> get stream => _streamController.stream;
  CameraImage? get latestFrame => _latestFrame;

  void publish(CameraImage image) {
    _latestFrame = image;
    if (!_streamController.isClosed) {
      _streamController.add(image);
    }
  }

  void dispose() {
    _streamController.close();
    _latestFrame = null;
  }
}
