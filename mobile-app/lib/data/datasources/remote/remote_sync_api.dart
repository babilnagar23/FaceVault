import 'package:dio/dio.dart';

import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

/// Remote sync API implementation.
/// Delegates periodic sync of the offline attendance outbox to the backend.
class RemoteSyncApi implements SyncApi {
  RemoteSyncApi(this._dio);
  final Dio _dio;

  final List<_QueueItem> _queue = [];

  @override
  Future<SyncState> status() async {
    try {
      final response = await _dio.get('/sync/status');
      final pending = response.data['pending'] as bool? ?? false;
      return pending ? SyncState.pending : SyncState.synced;
    } catch (_) {
      return SyncState.offline;
    }
  }

  @override
  Future<void> enqueue(String type, Map<String, Object?> payload) async {
    _queue.add(_QueueItem(type: type, payload: payload));
  }

  @override
  Future<void> flush() async {
    if (_queue.isEmpty) return;
    final events = _queue
        .map((item) => {
              'client_event_id': item.id,
              'entity_type': item.type,
              'operation': 'create',
              'payload': item.payload,
            })
        .toList();

    await _dio.post('/sync/push', data: {'device_id': 'device-1', 'events': events});
    _queue.clear();
  }

  @override
  Future<List<SyncItem>> pendingItems() async {
    return _queue
        .map((item) => SyncItem(
              id: item.id,
              type: item.type,
              payload: item.payload,
              createdAt: item.createdAt,
            ))
        .toList();
  }
}

class _QueueItem {
  final String id = DateTime.now().millisecondsSinceEpoch.toString();
  final String type;
  final Map<String, Object?> payload;
  final DateTime createdAt = DateTime.now();
  _QueueItem({required this.type, required this.payload});
}
