import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class RemoteAttendanceApi implements AttendanceApi {
  RemoteAttendanceApi(this._dio);
  final Dio _dio;

  static const _uuid = Uuid();

  @override
  Future<AttendanceVerificationResult> runVerification() async {
    // On-device face/liveness/GPS — results posted to backend
    // This is called by the UI to show the verification flow.
    // The actual submission happens in markAttendance().
    return AttendanceVerificationResult(
      faceVerified: false,
      faceScore: 0.0,
      livenessVerified: false,
      livenessScore: 0.0,
      locationVerified: false,
      distanceMeters: 0,
      gpsAccuracyMeters: 0,
      assignedSite: '',
      timestamp: DateTime.now(),
      attendanceStatus: AttendanceStatus.pendingSync,
      syncStatus: SyncState.pending,
    );
  }

  @override
  Future<AttendanceRecord> markAttendance() async {
    final clientEventId = _uuid.v4();
    final now = DateTime.now().toUtc();

    final res = await _dio.post('/attendance/attempt', data: {
      'client_event_id': clientEventId,
      'event_type': 'CHECK_IN',
      'client_timestamp': now.toIso8601String(),
      // face/liveness results would come from on-device biometric service
      'face_verified': true,
      'face_score': 0.99,
      'liveness_verified': true,
      'liveness_score': 0.97,
      // GPS from location service
      'latitude': null,
      'longitude': null,
      'gps_accuracy_meters': null,
      'offline_created': false,
    });

    return _parseRecord(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<AttendanceRecord>> history() async {
    final res = await _dio.get('/attendance/history');
    final list = res.data as List<dynamic>;
    return list.map((e) => _parseRecord(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AttendanceRecord> detail(String id) async {
    final res = await _dio.get('/attendance/$id');
    return _parseRecord(res.data as Map<String, dynamic>);
  }

  AttendanceRecord _parseRecord(Map<String, dynamic> d) {
    return AttendanceRecord(
      id: d['id'] as String,
      date: DateTime.tryParse(d['attendance_date'] as String? ?? '') ?? DateTime.now(),
      status: _parseStatus(d['status'] as String? ?? 'ABSENT'),
      checkInTime: _formatTime(d['check_in_time'] as String?),
      checkOutTime: _formatTime(d['check_out_time'] as String?),
      assignedSite: d['assigned_site'] as String? ?? '',
      distanceMeters: (d['distance_meters'] as int?) ?? 0,
      faceStatus: d['face_status'] as String? ?? 'Unknown',
      livenessStatus: d['liveness_status'] as String? ?? 'Unknown',
      locationStatus: d['location_status'] as String? ?? 'Unknown',
      syncStatus: SyncState.synced,
      remarks: d['remarks'] as String? ?? '',
      faceScore: (d['face_score'] as num?)?.toDouble(),
      livenessScore: (d['liveness_score'] as num?)?.toDouble(),
    );
  }

  AttendanceStatus _parseStatus(String s) {
    switch (s) {
      case 'PRESENT': return AttendanceStatus.present;
      case 'ABSENT': return AttendanceStatus.absent;
      case 'LATE': return AttendanceStatus.late;
      case 'LEAVE': return AttendanceStatus.leave;
      case 'PENDING_REVIEW': return AttendanceStatus.pendingReview;
      case 'PENDING_SYNC': return AttendanceStatus.pendingSync;
      case 'FACE_FAILED': return AttendanceStatus.faceFailed;
      case 'LIVENESS_FAILED': return AttendanceStatus.livenessFailed;
      default: return AttendanceStatus.absent;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
