import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

enum PermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited
}

class PermissionService {
  Future<PermissionState> requestCameraPermission() async {
    return _mapStatus(await Permission.camera.request());
  }

  Future<PermissionState> checkCameraPermission() async {
    return _mapStatus(await Permission.camera.status);
  }

  Future<PermissionState> requestLocationPermission() async {
    return _mapStatus(await Permission.locationWhenInUse.request());
  }

  Future<PermissionState> checkLocationPermission() async {
    return _mapStatus(await Permission.locationWhenInUse.status);
  }

  Future<PermissionState> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      return _mapStatus(await Permission.notification.request());
    }
    return PermissionState.granted;
  }

  Future<PermissionState> checkNotificationPermission() async {
    if (Platform.isAndroid) {
      return _mapStatus(await Permission.notification.status);
    }
    return PermissionState.granted;
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  PermissionState _mapStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return PermissionState.granted;
      case PermissionStatus.denied:
        return PermissionState.denied;
      case PermissionStatus.permanentlyDenied:
        return PermissionState.permanentlyDenied;
      case PermissionStatus.restricted:
        return PermissionState.restricted;
      case PermissionStatus.limited:
        return PermissionState.limited;
      case PermissionStatus.provisional:
        return PermissionState.granted; // Treat provisional as granted for now
    }
  }
}
