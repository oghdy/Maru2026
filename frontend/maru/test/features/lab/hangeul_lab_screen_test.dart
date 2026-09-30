import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lab/screens/hangeul_lab_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // flutter_tts has no platform side in tests — answer every call with success.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async => 1);
  });

  testWidgets('Hangeul Lab: ㅎ+ㅏ+ㄴ → 한 on a small screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HangeulLabScreen())));

    Future<void> tapKey(String jamo) async {
      final key = find.text(jamo).last; // last = keyboard key (slots show the same letter)
      await tester.ensureVisible(key);
      await tester.pumpAndSettle();
      await tester.tap(key);
      await tester.pumpAndSettle();
    }

    await tapKey('ㅎ');
    await tapKey('ㅏ');
    await tapKey('ㄴ');
    await tester.ensureVisible(find.text('Combine!'));
    await tester.tap(find.text('Combine!'));
    await tester.pumpAndSettle();

    expect(find.text('한'), findsOneWidget);
    expect(find.text('[han]'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.text('한'), findsNothing);
    expect(find.text('Consonants'), findsOneWidget);
  });
}
