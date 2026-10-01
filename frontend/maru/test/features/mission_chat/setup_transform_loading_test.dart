import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/mission_chat/widgets/setup_transform_loading.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    );

String _allText(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .map((t) => t.text.toPlainText())
    .join('\n');

void main() {
  testWidgets('uses the role the learner typed', (tester) async {
    await tester.pumpWidget(_wrap(const SetupTransformLoading(role: ' Cafe Staff ')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_allText(tester), contains('Tokki is transforming into\n“Cafe Staff”'));
    expect(_allText(tester), contains('Waving the magic wand...'));
    // Step line moves on each transformation cycle.
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_allText(tester), contains('Picking the right costume...'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('blank role falls back to a generic partner', (tester) async {
    await tester.pumpWidget(_wrap(const SetupTransformLoading(role: ''), reduceMotion: true));
    await tester.pump();
    expect(_allText(tester), contains('your conversation partner'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
