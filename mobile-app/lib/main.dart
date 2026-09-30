import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'core/services/ml/tflite_runners.dart';
import 'core/services/sync/attendance_outbox.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive ─────────────────────────────────────────────────────────────────
  await Hive.initFlutter();

  // ── Offline attendance outbox ─────────────────────────────────────────────
  final outbox = AttendanceOutbox();
  await outbox.init();
  // Prune entries older than 7 days
  await outbox.pruneStale();

  // ── TFLite model warm-up (if using real services) ─────────────────────────
  if (kUseRealServices) {
    try {
      await EmbeddingGenerator.instance.load();
    } catch (e) {
      // Model may not be bundled yet in development; app falls back gracefully.
      debugPrint('[FaceVault] Embedding model unavailable: $e');
    }

    try {
      await AntiSpoofRunner.instance.load();
    } catch (e) {
      debugPrint('[FaceVault] Anti-spoof model unavailable: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        // Override outbox singleton with the already-initialised instance
        attendanceOutboxProvider.overrideWithValue(outbox),
      ],
      child: const FaceVaultApp(),
    ),
  );
}
