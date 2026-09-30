import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lesson/models/agglutinative_quiz_model.dart';
import 'package:maru/features/lesson/widgets/agglutinative_step_widget.dart';

/// "친구는 … 저는 …": '는' is needed twice in the 🐢 phase. Two options share the
/// text '는' but have different ids — both must be placeable.
final _content = {
  'sentence': '친구는 저는',
  'translation': 'My friend, me',
  'elements': [
    {'id': 'e1', 'isTarget': true, 'correct_rabbit': ['친구는'], 'correct_turtle': ['친구', '는']},
    {'id': 'e2', 'isTarget': true, 'correct_rabbit': ['저는'], 'correct_turtle': ['저', '는']},
  ],
  'options': [
    {'id': 'o1', 'mode': 'rabbit', 'text': '친구는'},
    {'id': 'o2', 'mode': 'rabbit', 'text': '저는'},
    {'id': 'o3', 'mode': 'turtle', 'text': '친구'},
    {'id': 'o4', 'mode': 'turtle', 'text': '는'},
    {'id': 'o5', 'mode': 'turtle', 'text': '저'},
    {'id': 'o6', 'mode': 'turtle', 'text': '는'},
  ],
};

Finder _option(String text) => find
    .descendant(of: find.byType(Draggable<AgglutinativeOption>), matching: find.text(text))
    .first;

Future<void> _drag(WidgetTester tester, Finder from, Finder to) async {
  final g = await tester.startGesture(tester.getCenter(from));
  await tester.pump(const Duration(milliseconds: 50));
  await g.moveBy(const Offset(0, -20));
  await tester.pump(const Duration(milliseconds: 50));
  await g.moveTo(tester.getCenter(to));
  await tester.pump(const Duration(milliseconds: 50));
  await g.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('same-text options are tracked by id (morpheme needed twice)', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var finished = false;
    (int, int)? score;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AgglutinativeStepWidget(
          content: _content,
          onNext: () => finished = true,
          onScore: (c, t) => score = (c, t),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 🐰 phase
    await _drag(tester, _option('친구는'), find.text('...').first);
    await _drag(tester, _option('저는'), find.text('...').first);
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    // 🐢 phase: both '는' options must be usable
    expect(find.descendant(of: find.byType(Draggable<AgglutinativeOption>), matching: find.text('는')), findsNWidgets(2));
    await _drag(tester, _option('친구'), find.text('?').first);
    await _drag(tester, _option('는'), find.text('?').first);
    await _drag(tester, _option('저'), find.text('?').first);
    expect(find.descendant(of: find.byType(Draggable<AgglutinativeOption>), matching: find.text('는')), findsOneWidget);
    await _drag(tester, _option('는'), find.text('?').first);

    await tester.tap(find.text('Check & Finish'));
    await tester.pump();
    expect(find.textContaining('Correct!'), findsOneWidget); // shown before moving on
    await tester.pump(const Duration(milliseconds: 1300));
    expect(finished, isTrue);
    expect(score, (2, 2));
  });

  testWidgets('tapping a block places it in the first empty slot; wrong turtle answer shows hint', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var finished = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AgglutinativeStepWidget(
          content: {
            ..._content,
            'elements': [
              {'id': 'e1', 'isTarget': true, 'correct_rabbit': ['친구는'], 'correct_turtle': ['친구', '는'],
               'turtle_explanation': '친구 (friend) + 는 (topic marker)'},
              {'id': 'e2', 'isTarget': true, 'correct_rabbit': ['저는'], 'correct_turtle': ['저', '는']},
            ],
          },
          onNext: () => finished = true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(_option('친구는'));
    await tester.pump();
    await tester.tap(_option('저는'));
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    // wrong order in the 🐢 phase: 는 before 친구
    await tester.tap(_option('는'));
    await tester.pump();
    await tester.tap(_option('친구'));
    await tester.pump();
    await tester.tap(_option('저'));
    await tester.pump();
    await tester.tap(_option('는'));
    await tester.pump();
    await tester.tap(find.text('Check & Finish'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hint: 친구 (friend) + 는 (topic marker)'), findsOneWidget);
    expect(finished, isFalse);
  });

  testWidgets('chunks that stay whole are pre-placed in the turtle phase', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AgglutinativeStepWidget(
          content: {
            'sentence': '저는 학생이에요.',
            'translation': 'I am a student.',
            'elements': [
              {'id': 'e1', 'isTarget': true, 'correct_rabbit': ['저는'], 'correct_turtle': ['저는']},
              {'id': 'e2', 'isTarget': true, 'correct_rabbit': ['학생이에요'], 'correct_turtle': ['학생', '이에요']},
            ],
            'options': [
              {'id': 'o1', 'mode': 'rabbit', 'text': '저는'},
              {'id': 'o2', 'mode': 'rabbit', 'text': '학생이에요'},
              {'id': 'o3', 'mode': 'turtle', 'text': '저는'},
              {'id': 'o4', 'mode': 'turtle', 'text': '학생'},
              {'id': 'o5', 'mode': 'turtle', 'text': '이에요'},
            ],
          },
          onNext: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await _drag(tester, _option('저는'), find.text('...').first);
    await _drag(tester, _option('학생이에요'), find.text('...').first);
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    // Only the two slots of 학생이에요 are open; 저는 is already in place and not in the tray
    expect(find.text('?'), findsNWidgets(2));
    expect(find.descendant(of: find.byType(Draggable<AgglutinativeOption>), matching: find.text('저는')), findsNothing);
  });
}
