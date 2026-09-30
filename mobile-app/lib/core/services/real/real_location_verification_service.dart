import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../../data/models/app_models.dart';
import '../location_verification_service.dart';
import '../storage/site_assignment_cache.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REAL LOCATION VERIFICATION SERVICE
// ─────────────────────────────────────────────────────────────────────────────

/// Verifies the employee's current GPS position against their assigned site
/// geofence using cached assignment data.
///
/// Works fully offline — reads the cached [SiteAssignment] from secure storage
/// and computes the Haversine distance locally. No server call is made.
///
/// If no cached assignment exists, the service returns an unverified result
/// with an appropriate message.
class RealLocationVerificationService implements LocationVerificationService {
  RealLocationVerificationService({
    required SiteAssignmentCache assignmentCache,
    Duration locationTimeout = const Duration(seconds: 10),
  })  : _assignmentCache = assignmentCache,
        _locationTimeout = locationTimeout;

  final SiteAssignmentCache _assignmentCache;
  final Duration _locationTimeout;

  // ── LocationVerificationService implementation ────────────────────────────

  @override
  Future<LocationVerificationResult> verify() async {
    // 1. Check permissions
    final permissionResult = await _checkPermissions();
    if (permissionResult != null) return permissionResult;

    // 2. Load cached site assignment
    final assignment = await _assignmentCache.loadAssignment();
    if (assignment == null) {
      return const LocationVerificationResult(
        verified: false,
        assignedSite: 'Unknown',
        distanceMeters: 0,
        gpsAccuracyMeters: 0,
        latitude: 0,
        longitude: 0,
        failureReason:
            'No site assignment found. Please sync while connected to re-download your assignment.',
      );
    }

    // 3. Get current position
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: _locationTimeout,
        ),
      );
    } on TimeoutException {
      return LocationVerificationResult(
        verified: false,
        assignedSite: assignment.siteName,
        distanceMeters: 0,
        gpsAccuracyMeters: 0,
        latitude: 0,
        longitude: 0,
        failureReason: 'GPS timed out. Please ensure you have clear sky visibility.',
      );
    } catch (e) {
      return LocationVerificationResult(
        verified: false,
        assignedSite: assignment.siteName,
        distanceMeters: 0,
        gpsAccuracyMeters: 0,
        latitude: 0,
        longitude: 0,
        failureReason: 'GPS error: $e',
      );
    }

    // 4. Calculate Haversine distance from assigned site
    final distanceMeters = _haversineDistance(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: assignment.latitude,
      lon2: assignment.longitude,
    );

    final withinGeofence = distanceMeters <= assignment.radiusMeters;
    final accuracyMeters = position.accuracy.round();

    return LocationVerificationResult(
      verified: withinGeofence,
      assignedSite: assignment.siteName,
      distanceMeters: distanceMeters.round(),
      gpsAccuracyMeters: accuracyMeters,
      latitude: position.latitude,
      longitude: position.longitude,
      failureReason: withinGeofence
          ? null
          : 'Current location is outside the assigned geofence '
              '(${assignment.siteName}, ${assignment.radiusMeters}m radius). '
              'Distance: ${(distanceMeters / 1000).toStringAsFixed(1)} km.',
    );
  }

  // ── Permission helpers ────────────────────────────────────────────────────

  Future<LocationVerificationResult?> _checkPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationVerificationResult(
        verified: false,
        assignedSite: 'Unknown',
        distanceMeters: 0,
        gpsAccuracyMeters: 0,
        latitude: 0,
        longitude: 0,
        failureReason: 'Location services are disabled. Please enable GPS.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const LocationVerificationResult(
        verified: false,
        assignedSite: 'Unknown',
        distanceMeters: 0,
        gpsAccuracyMeters: 0,
        latitude: 0,
        longitude: 0,
        failureReason: 'Location permission is required for attendance verification.',
      );
    }

    return null; // permissions OK
  }

  // ── Haversine formula ─────────────────────────────────────────────────────

  /// Calculate the great-circle distance in metres between two GPS coordinates.
  double _haversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusM = 6371000.0; // metres
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  double _toRad(double deg) => deg * math.pi / 180.0;
}
