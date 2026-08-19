class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String type;
  final Map<String, Object?> payload;
  final DateTime createdAt;
}

class SyncQueue {
  final List<SyncQueueItem> _items = [];

  List<SyncQueueItem> get items => List.unmodifiable(_items);

  void add(String type, Map<String, Object?> payload) {
    _items.add(
      SyncQueueItem(
        id: 'SYNC-${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
  }

  void clear() => _items.clear();
}

