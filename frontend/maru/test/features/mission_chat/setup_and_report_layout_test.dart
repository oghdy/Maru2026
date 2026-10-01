import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/mission_chat/models/mission_clearance_model.dart';
import 'package:maru/features/mission_chat/providers/mission_chat_provider.dart';
import 'package:maru/features/mission_chat/screens/mission_clearance_list_screen.dart';
import 'package:maru/features/mission_chat/screens/mission_clearance_screen.dart';
import 'package:maru/features/mission_chat/screens/mission_setup_screen.dart';

// Layout smoke tests (MSN-1.7.9): every screen renders at phone widths without overflow.

MissionClearanceModel _clearance(bool? cleared) => MissionClearanceModel(
      id: 1,
      missionTitle: 'Coffee Preference Confession',
      persona: '카페 직원',
      totalTurns: 5,
      goodExpressions: [ExpressionModel(expression: '아이스티 주세요', reason: 'Polite and natural request.')],
      incorrectExpressions: [
        IncorrectExpressionModel(wrong: '주세요ㅛ', correct: '주세요', explanation: 'The final ㅛ is a typo.'),
      ],
      turtleComment: 'You kept the conversation going well. Try asking a follow-up question next time.',
      nextPractice: 'Ask the barista about drink recommendations.',
      clearedAt: DateTime(2026, 10, 1),
      cleared: cleared,
      resultReason: cleared == null ? null : 'You revealed the secret but did not discuss other drinks.',
      goalCondition: cleared == null ? null : "Reveal that you don't like coffee and discuss alternatives.",
    );

Future<void> _pump(WidgetTester tester, Widget screen, {Size size = const Size(393, 852), List overrides = const []}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [...overrides],
    child: MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B4EFF))),
      home: MediaQuery(
        data: MediaQueryData(size: size, disableAnimations: true),
        child: screen,
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 600));
}

String _allText(WidgetTester tester) =>
    tester.widgetList<RichText>(find.byType(RichText)).map((t) => t.text.toPlainText()).join('\n');

void main() {
  for (final size in const [Size(393, 852), Size(320, 640)]) {
    testWidgets('setup form renders at ${size.width.toInt()}w', (tester) async {
      await _pump(tester, const MissionSetupScreen(), size: size);
      expect(tester.takeException(), isNull);
      final text = _allText(tester);
      expect(text, contains("They're older or higher status"));
      expect(text, contains('Use respectful Korean'));
      // Quick-pick chip fills the role field.
      await tester.ensureVisible(find.text('Professor'));
      await tester.tap(find.text('Professor'));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'Professor'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    for (final cleared in const [true, false, null]) {
      testWidgets('report (cleared=$cleared) renders at ${size.width.toInt()}w', (tester) async {
        await _pump(tester, MissionClearanceScreen(clearance: _clearance(cleared)), size: size);
        expect(tester.takeException(), isNull);
        final text = _allText(tester);
        if (cleared == false) {
          expect(text, contains('Almost there!'));
          expect(text, isNot(contains('try again')));
        }
        for (var page = 0; page < 3; page++) {
          await tester.drag(find.byType(PageView), Offset(-size.width, 0));
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
        }
        expect(_allText(tester), contains('Back to Certificates'));
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('certificate list renders at ${size.width.toInt()}w', (tester) async {
      await _pump(
        tester,
        const MissionClearanceListScreen(),
        size: size,
        overrides: [clearancesProvider.overrideWith((ref) async => [_clearance(true), _clearance(false), _clearance(null)])],
      );
      expect(tester.takeException(), isNull);
      expect(_allText(tester), contains('3 missions · 1 cleared'));
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('empty certificate list shows the rabbit message', (tester) async {
    await _pump(tester, const MissionClearanceListScreen(),
        overrides: [clearancesProvider.overrideWith((ref) async => <MissionClearanceModel>[])]);
    expect(_allText(tester), contains('No missions yet'));
    await tester.pumpWidget(const SizedBox());
  });
}
