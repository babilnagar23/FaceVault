import 'sync_queue.dart';
import 'sync_status.dart';

class SyncService {
  SyncService(this.queue);

  final SyncQueue queue;
  OfflineSyncStatus status = OfflineSyncStatus.pending;

  Future<void> sync() async {
    if (queue.items.isEmpty) {
      status = OfflineSyncStatus.synced;
      return;
    }
    status = OfflineSyncStatus.syncing;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    queue.clear();
    status = OfflineSyncStatus.synced;
  }
}

