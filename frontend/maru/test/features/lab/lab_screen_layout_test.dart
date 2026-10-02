import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lab/screens/lab_screen.dart';

void main() {
  // iPhone SE (1st gen) logical size with the on-screen keyboard open.
  testWidgets('Grammar Lab does not overflow on a small screen with keyboard + Combine mode open', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          // Characters loop forever; reduced motion stops the loops so pumpAndSettle can settle.
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: LabScreen(),
        ),
      ),
    );
    // Below the fold at this height — the page must scroll to reach it.
    await tester.ensureVisible(find.text('Combine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Combine'));
    await tester.pumpAndSettle();
    // Single run button stays on screen, labelled for the mode.
    expect(find.text('Pick rules to combine'), findsOneWidget);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Sentence type', findRichText: true), findsOneWidget);
    await tester.ensureVisible(find.textContaining('Sentence type', findRichText: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
