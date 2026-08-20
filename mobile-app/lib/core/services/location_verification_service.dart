import '../../data/models/app_models.dart';

// ─────────────────────────────────────────
// ABSTRACT INTERFACE
// ─────────────────────────────────────────

abstract interface class LocationVerificationService {
  /// Verifies the user's current GPS location against their assigned site geofence.
  Future<LocationVerificationResult> verify();
}

// ─────────────────────────────────────────
// MOCK IMPLEMENTATION
// ─────────────────────────────────────────

class MockLocationVerificationService implements LocationVerificationService {
  @override
  Future<LocationVerificationResult> verify() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return const LocationVerificationResult(
      verified: true,
      assignedSite: 'Sector 17',
      distanceMeters: 23,
      gpsAccuracyMeters: 4,
      latitude: 28.5901,
      longitude: 77.0479,
    );
  }
}

class MockLocationFailureService implements LocationVerificationService {
  @override
  Future<LocationVerificationResult> verify() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const LocationVerificationResult(
      verified: false,
      assignedSite: 'Sector 17',
      distanceMeters: 1400,
      gpsAccuracyMeters: 18,
      latitude: 28.6012,
      longitude: 77.0620,
      failureReason: 'Current location is outside the assigned geofence (Sector 17, 150m radius). Distance: 1.4 km.',
    );
  }
}
