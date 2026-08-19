import 'sync_queue.dart';
import 'sync_service.dart';

class SyncManager {
  SyncManager() : queue = SyncQueue() {
    service = SyncService(queue);
  }

  final SyncQueue queue;
  late final SyncService service;

  void enqueueAttendance(Map<String, Object?> payload) {
    queue.add('attendance_attempt', payload);
  }
}


