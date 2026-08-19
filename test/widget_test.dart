import 'package:facevault_mobile/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('FaceVault app builds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FaceVaultApp()));
    expect(find.text('FaceVault'), findsOneWidget);
  });
}

