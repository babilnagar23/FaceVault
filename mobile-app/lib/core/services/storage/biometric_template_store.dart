import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../ml/model_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BIOMETRIC TEMPLATE STORE
// ─────────────────────────────────────────────────────────────────────────────

/// Persists face embedding templates using [FlutterSecureStorage].
///
/// On Android: stored in EncryptedSharedPreferences (AES-256-GCM via Keystore).
/// On iOS: stored in Keychain (always-on hardware encryption).
///
/// The embedding is serialised as a Base64-encoded JSON object containing:
///   - "v"   : embedding vector as a list of doubles
///   - "dim" : embedding dimension (sanity check)
///   - "model": model version string
///   - "ts"  : enrollment timestamp (ISO 8601)
///
/// Raw embedding vectors are NEVER logged or exposed in UI state.
class BiometricTemplateStore {
  BiometricTemplateStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: false,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const String _keyPrefix = 'fv_biometric_template_';
  static const String _enrolledFlagPrefix = 'fv_enrolled_flag_';

  // ── Write ────────────────────────────────────────────────────────────────

  /// Securely store the [embedding] for [employeeId].
  ///
  /// Overwrites any previously stored template.
  Future<void> storeTemplate({
    required String employeeId,
    required Float32List embedding,
  }) async {
    assert(embedding.length == ModelConfig.embeddingDimension);

    final payload = {
      'v': embedding.toList(),
      'dim': embedding.length,
      'model': ModelConfig.embeddingModelVersion,
      'ts': DateTime.now().toUtc().toIso8601String(),
    };
    final json = jsonEncode(payload);
    // Double-encode: JSON → UTF-8 bytes → Base64 makes key/value opaque in logs
    final encoded = base64Encode(utf8.encode(json));

    await _storage.write(key: _templateKey(employeeId), value: encoded);
    await _storage.write(key: _enrolledKey(employeeId), value: 'true');
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Load the stored embedding for [employeeId].
  ///
  /// Returns null if no template is stored or the stored data is corrupt.
  Future<Float32List?> loadTemplate(String employeeId) async {
    final encoded = await _storage.read(key: _templateKey(employeeId));
    if (encoded == null) return null;

    try {
      final json = utf8.decode(base64Decode(encoded));
      final payload = jsonDecode(json) as Map<String, dynamic>;

      final dim = payload['dim'] as int?;
      if (dim != ModelConfig.embeddingDimension) {
        // Dimension mismatch — template is from an old model; treat as missing.
        return null;
      }

      final rawList = (payload['v'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList();
      return Float32List.fromList(rawList);
    } catch (_) {
      // Corrupt data — clear it
      await _clearTemplate(employeeId);
      return null;
    }
  }

  // ── Status ───────────────────────────────────────────────────────────────

  /// Returns true if a valid template is stored for [employeeId].
  Future<bool> isEnrolled(String employeeId) async {
    final flag = await _storage.read(key: _enrolledKey(employeeId));
    if (flag != 'true') return false;
    // Also verify the actual template is present and parseable.
    final template = await loadTemplate(employeeId);
    return template != null;
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  /// Removes the stored template and enrollment flag for [employeeId].
  Future<void> deleteTemplate(String employeeId) async {
    await _clearTemplate(employeeId);
    await _storage.delete(key: _enrolledKey(employeeId));
  }

  /// Remove all biometric templates from secure storage.
  Future<void> deleteAllTemplates() async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      if (key.startsWith(_keyPrefix) || key.startsWith(_enrolledFlagPrefix)) {
        await _storage.delete(key: key);
      }
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────

  Future<void> _clearTemplate(String employeeId) async {
    await _storage.delete(key: _templateKey(employeeId));
  }

  String _templateKey(String employeeId) => '$_keyPrefix$employeeId';
  String _enrolledKey(String employeeId) => '$_enrolledFlagPrefix$employeeId';
}
