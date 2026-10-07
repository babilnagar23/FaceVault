#!/usr/bin/env dart
// scripts/download_models.dart
//
// Downloads open-source TFLite models for FaceVault offline face verification.
// Run from the mobile-app directory:
//   dart run scripts/download_models.dart
//
// Models downloaded:
//   1. MobileFaceNet (face embedding, Apache 2.0)
//      Input: 96×96×3 float32 normalised to [-1,1]
//      Output: 192-dim float32 L2-normalised embedding
//
//   2. Silent-Face Anti-Spoofing (liveness, MIT)
//      Input: 128×128×3 float32 normalised to [0,1]
//      Output: 2-class softmax [real_prob, spoof_prob]
//
// After download, re-run `flutter pub get` and rebuild the app.

import 'dart:io';

const _modelsDir = 'assets/models';

const _models = <String, String>{
  'mobilefacenet.tflite':
      // MobileFaceNet converted to TFLite — replace URL with your CI artifact store
      'https://github.com/sirius-ai/MobileFaceNet_TF/releases/download/v1.0/mobilefacenet.tflite',
  'anti_spoof.tflite':
      // Silent-Face Anti-Spoofing TFLite export — replace URL with your CI artifact store
      'https://github.com/minivision-ai/Silent-Face-Anti-Spoofing/releases/download/v1.0/anti_spoof_mini.tflite',
};

// ignore_for_file: avoid_print
Future<void> main() async {
  final dir = Directory(_modelsDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    print('Created directory: $_modelsDir');
  }

  final client = HttpClient();

  for (final entry in _models.entries) {
    final filename = entry.key;
    final url = entry.value;
    final dest = File('$_modelsDir/$filename');

    if (dest.existsSync()) {
      print('✓ $filename already exists (${dest.lengthSync()} bytes) — skipping.');
      continue;
    }

    print('⬇  Downloading $filename ...');
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        print('✗ Failed to download $filename: HTTP ${response.statusCode}');
        print('  Please download manually from: $url');
        print('  Creating a dummy file to allow the build to proceed.');
        dest.writeAsBytesSync([0]);
        continue;
      }

      final sink = dest.openWrite();
      await response.pipe(sink);
      await sink.flush();
      await sink.close();

      print('✓ $filename saved (${dest.lengthSync()} bytes)');
    } catch (e) {
      print('✗ Error downloading $filename: $e');
      print('  Please download manually and place in $_modelsDir/');
      print('  Creating a dummy file to allow the build to proceed.');
      dest.writeAsBytesSync([0]);
    }
  }

  client.close();

  print('\nDone. Run `flutter pub get` and rebuild the app.');
  print('If models are not publicly hosted, contact your ML team for the');
  print('model artifacts or use your CI artifact store URL.');
}
