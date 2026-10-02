import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lab/screens/lab_menu_screen.dart';
import 'package:maru/features/lab/screens/lab_screen.dart';

void main() {
  // Feedback R5: lab-mood menu, UI name "Sentence Lab" (D-24) with the AI-powered note kept.
  testWidgets('Lab menu: two benches fit a small screen and Sentence Lab opens the lab', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          // Characters and bubbles loop forever; reduced motion stops them so pumpAndSettle can settle.
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
          home: const LabMenuScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hangeul Lab'), findsOneWidget);
    expect(find.text('Sentence Lab'), findsOneWidget);
    expect(find.text('AI Grammar Lab'), findsNothing);
    expect(find.text('AI-powered'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Sentence Lab'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sentence Lab'));
    await tester.pumpAndSettle();
    expect(find.byType(LabScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Sentence Lab'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
