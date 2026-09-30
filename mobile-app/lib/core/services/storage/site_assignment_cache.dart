import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SITE ASSIGNMENT CACHE
// ─────────────────────────────────────────────────────────────────────────────

/// Locally caches the employee's assigned work-site data for offline geofencing.
///
/// Data is fetched from the backend during the online sync window and stored
/// in [FlutterSecureStorage] so it is available when the device is offline.
///
/// Schema: {
///   "site_code": "DEL-MR-02",
///   "site_name": "Sector 17",
///   "latitude": 28.5901,
///   "longitude": 77.0479,
///   "radius_meters": 150,
///   "cached_at": "2026-09-01T08:00:00Z"
/// }
class SiteAssignmentCache {
  SiteAssignmentCache({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;
  static const String _key = 'fv_site_assignment_v1';

  /// Cache assignment data fetched from the server.
  Future<void> storeAssignment(SiteAssignment assignment) async {
    final json = jsonEncode({
      'site_code': assignment.siteCode,
      'site_name': assignment.siteName,
      'latitude': assignment.latitude,
      'longitude': assignment.longitude,
      'radius_meters': assignment.radiusMeters,
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    });
    await _storage.write(key: _key, value: json);
  }

  /// Load the cached site assignment.
  ///
  /// Returns null if no data is cached.
  Future<SiteAssignment?> loadAssignment() async {
    final json = await _storage.read(key: _key);
    if (json == null) return null;
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return SiteAssignment(
        siteCode: m['site_code'] as String,
        siteName: m['site_name'] as String,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        radiusMeters: (m['radius_meters'] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAssignment() => _storage.delete(key: _key);
}

/// Immutable value object for a work-site assignment.
class SiteAssignment {
  const SiteAssignment({
    required this.siteCode,
    required this.siteName,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String siteCode;
  final String siteName;
  final double latitude;
  final double longitude;
  final int radiusMeters;
}
