import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lab/screens/hangeul_lab_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // flutter_tts has no platform side in tests — answer every call with success.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );
  });

  testWidgets('Hangeul Lab: ㅎ+ㅏ+ㄴ → 한 on a small screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          // Characters loop forever; reduced motion stops the loops so pumpAndSettle can settle.
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: HangeulLabScreen(),
        ),
      ),
    );

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

    // Main button turned into "Try another"; changing a slot would turn it back.
    expect(find.text('Combine!'), findsNothing);
    await tester.ensureVisible(find.text('Try another'));
    await tester.tap(find.text('Try another'));
    await tester.pumpAndSettle();
    expect(find.text('한'), findsNothing);
    expect(find.text('Consonants'), findsOneWidget);
    expect(find.text('Combine!'), findsOneWidget);
  });
}
