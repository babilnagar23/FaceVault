import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ATTENDANCE OUTBOX  (offline queue)
// ─────────────────────────────────────────────────────────────────────────────

/// SQLite-backed outbox that queues attendance events when the device is offline.
///
/// Events are stored with idempotency keys so the server can safely deduplicate
/// if the same event is submitted multiple times.
///
/// Call [init] once at app startup.
/// Call [enqueue] after every verification (online or offline).
/// Call [flush] whenever connectivity is restored.
class AttendanceOutbox {
  AttendanceOutbox({Database? db}) : _db = db;

  Database? _db;
  static const String _tableName = 'attendance_outbox';
  static const _uuid = Uuid();

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_db != null) return;
    _db = await openDatabase(
      'facevault_outbox.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            event_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');
      },
    );
  }

  // ── Enqueue ───────────────────────────────────────────────────────────────

  /// Add an attendance event to the outbox.
  ///
  /// Returns the generated [clientEventId] which doubles as the idempotency key.
  Future<String> enqueue({
    required String eventType,
    required AttendanceOutboxEvent event,
  }) async {
    _assertInit();
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db!.insert(_tableName, {
      'id': id,
      'event_type': eventType,
      'payload': jsonEncode(event.toJson()),
      'created_at': now,
      'retry_count': 0,
    });
    return id;
  }

  // ── List Pending ──────────────────────────────────────────────────────────

  Future<List<PendingOutboxEntry>> pendingEntries() async {
    _assertInit();
    final rows = await _db!.query(
      _tableName,
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => PendingOutboxEntry.fromRow(r)).toList();
  }

  // ── Mark Sent ────────────────────────────────────────────────────────────

  Future<void> markSent(String id) async {
    _assertInit();
    await _db!.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // ── Mark Failed ───────────────────────────────────────────────────────────

  Future<void> markFailed(String id, String error) async {
    _assertInit();
    await _db!.update(
      _tableName,
      {
        'retry_count': 1, // Will be incremented via SQL in real use
        'last_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    // Use raw SQL for proper increment
    await _db!.rawUpdate(
      'UPDATE $_tableName SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  // ── Count ─────────────────────────────────────────────────────────────────

  Future<int> pendingCount() async {
    _assertInit();
    final result = await _db!.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_tableName',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── Prune stale (> 7 days) ────────────────────────────────────────────────

  Future<void> pruneStale() async {
    _assertInit();
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    await _db!.delete(
      _tableName,
      where: 'created_at < ?',
      whereArgs: [cutoff],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _assertInit() {
    if (_db == null) {
      throw StateError('AttendanceOutbox.init() must be called before use.');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA CLASSES
// ─────────────────────────────────────────────────────────────────────────────

/// The serialisable payload for an attendance event.
class AttendanceOutboxEvent {
  const AttendanceOutboxEvent({
    required this.clientEventId,
    required this.eventType,
    required this.clientTimestamp,
    required this.faceVerified,
    required this.faceScore,
    required this.livenessVerified,
    required this.livenessScore,
    required this.locationVerified,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracyMeters,
    required this.assignedSite,
    required this.distanceMeters,
    required this.offlineCreated,
  });

  final String clientEventId;
  final String eventType;
  final DateTime clientTimestamp;
  final bool faceVerified;
  final double faceScore;
  final bool livenessVerified;
  final double livenessScore;
  final bool locationVerified;
  final double latitude;
  final double longitude;
  final double gpsAccuracyMeters;
  final String assignedSite;
  final int distanceMeters;
  final bool offlineCreated;

  Map<String, dynamic> toJson() => {
        'client_event_id': clientEventId,
        'event_type': eventType,
        'client_timestamp': clientTimestamp.toUtc().toIso8601String(),
        'face_verified': faceVerified,
        'face_score': faceScore,
        'liveness_verified': livenessVerified,
        'liveness_score': livenessScore,
        'location_verified': locationVerified,
        'latitude': latitude,
        'longitude': longitude,
        'gps_accuracy_meters': gpsAccuracyMeters,
        'assigned_site': assignedSite,
        'distance_meters': distanceMeters,
        'offline_created': offlineCreated,
      };

  factory AttendanceOutboxEvent.fromJson(Map<String, dynamic> m) =>
      AttendanceOutboxEvent(
        clientEventId: m['client_event_id'] as String,
        eventType: m['event_type'] as String,
        clientTimestamp: DateTime.parse(m['client_timestamp'] as String),
        faceVerified: m['face_verified'] as bool,
        faceScore: (m['face_score'] as num).toDouble(),
        livenessVerified: m['liveness_verified'] as bool,
        livenessScore: (m['liveness_score'] as num).toDouble(),
        locationVerified: m['location_verified'] as bool,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        gpsAccuracyMeters: (m['gps_accuracy_meters'] as num).toDouble(),
        assignedSite: m['assigned_site'] as String,
        distanceMeters: (m['distance_meters'] as num).toInt(),
        offlineCreated: m['offline_created'] as bool,
      );
}

class PendingOutboxEntry {
  const PendingOutboxEntry({
    required this.id,
    required this.eventType,
    required this.event,
    required this.createdAt,
    required this.retryCount,
    this.lastError,
  });

  final String id;
  final String eventType;
  final AttendanceOutboxEvent event;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  factory PendingOutboxEntry.fromRow(Map<String, dynamic> row) {
    final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    return PendingOutboxEntry(
      id: row['id'] as String,
      eventType: row['event_type'] as String,
      event: AttendanceOutboxEvent.fromJson(payload),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      retryCount: row['retry_count'] as int,
      lastError: row['last_error'] as String?,
    );
  }
}
