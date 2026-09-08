import 'package:dio/dio.dart';
import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class RemoteHelpApi implements HelpApi {
  RemoteHelpApi(this._dio);
  final Dio _dio;

  @override
  Future<List<String>> issueTypes() async {
    final res = await _dio.get('/help/categories');
    return (res.data as List).cast<String>();
  }

  @override
  Future<HelpTicket> createTicket({required String issueType, required String description}) async {
    final res = await _dio.post('/help/tickets', data: {'issue_type': issueType, 'description': description});
    return _parse(res.data as Map<String, dynamic>);
  }

  @override
  Future<HelpTicket> detail(String id) async {
    final res = await _dio.get('/help/tickets/$id');
    return _parse(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<HelpTicket>> myTickets() async {
    final res = await _dio.get('/help/tickets');
    return (res.data as List).map((e) => _parse(e as Map<String, dynamic>)).toList();
  }

  HelpTicket _parse(Map<String, dynamic> d) => HelpTicket(
        id: d['id'] as String,
        issueType: d['issue_type'] as String,
        description: d['description'] as String,
        status: d['status'] as String,
        createdAt: DateTime.tryParse(d['created_at'] as String? ?? '') ?? DateTime.now(),
        employeeId: d['employee_id'] as String?,
        employeeName: d['employee_name'] as String?,
      );
}

class RemoteFaceEnrollmentApi implements FaceEnrollmentApi {
  RemoteFaceEnrollmentApi(this._dio);
  final Dio _dio;

  @override
  Future<bool> isEnrolled() async {
    final res = await _dio.get('/biometrics/status');
    return (res.data as Map<String, dynamic>)['enrolled'] as bool? ?? false;
  }

  @override
  Future<void> startEnrollment() async => await _dio.post('/biometrics/enroll/start');

  @override
  Future<void> completeEnrollment() async {
    await _dio.post('/biometrics/enroll/complete', data: {
      'model_version': '1.0',
      'quality_score': 0.90,
      'liveness_score': 0.95,
    });
  }
}

class RemoteSyncApi implements SyncApi {
  RemoteSyncApi(this._dio);
  final Dio _dio;

  @override
  Future<SyncState> status() async {
    try {
      final res = await _dio.get('/sync/pull');
      final pending = (res.data as Map<String, dynamic>)['pending_count'] as int? ?? 0;
      return pending > 0 ? SyncState.pending : SyncState.synced;
    } catch (_) {
      return SyncState.offline;
    }
  }

  @override
  Future<void> enqueue(String type, Map<String, Object?> payload) async {
    // Store locally — flushed on next flush() call
    _queue.add(_QueueItem(type: type, payload: payload));
  }

  @override
  Future<void> flush() async {
    if (_queue.isEmpty) return;
    final events = _queue.map((item) => {
      'client_event_id': item.id,
      'entity_type': item.type,
      'operation': 'create',
      'payload': item.payload,
    }).toList();

    await _dio.post('/sync/push', data: {'device_id': 'device-1', 'events': events});
    _queue.clear();
  }

  @override
  Future<List<SyncItem>> pendingItems() async {
    return _queue.map((item) => SyncItem(
      id: item.id, type: item.type, payload: item.payload, createdAt: item.createdAt,
    )).toList();
  }

  final List<_QueueItem> _queue = [];
}

class _QueueItem {
  final String id = DateTime.now().millisecondsSinceEpoch.toString();
  final String type;
  final Map<String, Object?> payload;
  final DateTime createdAt = DateTime.now();
  _QueueItem({required this.type, required this.payload});
}
