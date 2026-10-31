import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lesson/models/lesson_model.dart';
import 'package:maru/features/lesson/models/step_model.dart';
import 'package:maru/features/lesson/screens/lesson_screen.dart';
import 'package:maru/features/lesson/widgets/introduction_step_widget.dart';
import 'package:maru/features/lesson/widgets/practice_step_widget.dart';

Widget _app(Widget home) => MaterialApp(
      // Characters loop forever; reduced motion lets pumpAndSettle finish.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: home,
    );

Map<String, dynamic> _threeOptions() => {
      'exercises': [
        {
          'type': 'fill_blank',
          'instruction': 'Pick one.',
          'sentence': '저는 사과 [ ? ] 좋아해요.',
          'options': ['은', '을', '를'],
          'answer': '를',
          'feedback': {'correct': 'Yes!', 'incorrect': 'Look at the last sound.'},
        },
        {
          'type': 'fill_blank',
          'instruction': 'Pick again.',
          'sentence': '저는 빵 [ ? ] 좋아해요.',
          'options': ['은', '을'],
          'answer': '을',
        },
      ],
    };

final _buildContent = {
  'sentence': '저는 커피',
  'translation': 'I, coffee',
  'elements': [
    {'id': 'e1', 'isTarget': true, 'correct_rabbit': ['저는'], 'correct_turtle': ['저', '는']},
  ],
  'options': [
    {'id': 'o1', 'mode': 'rabbit', 'text': '저는'},
    {'id': 'o2', 'mode': 'rabbit', 'text': '저도'},
    {'id': 'o3', 'mode': 'turtle', 'text': '저'},
    {'id': 'o4', 'mode': 'turtle', 'text': '는'},
    {'id': 'o5', 'mode': 'turtle', 'text': '도'},
  ],
};

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pick(WidgetTester tester, String option) async {
  await _tap(tester, find.text(option));
  await _tap(tester, find.text('Check Answer'));
}

void main() {
  group('small lesson fixes', () {
    Color? tileBorder(WidgetTester tester, String text) {
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(of: find.text(text), matching: find.byType(AnimatedContainer)).first,
      );
      return ((container.decoration as BoxDecoration).border as Border?)?.top.color;
    }

    testWidgets('a first miss hides the answer, a second miss shows it, and the score only counts the first try',
        (tester) async {
      (int, int)? score;
      await tester.pumpWidget(_app(Scaffold(
        body: PracticeStepWidget(content: _threeOptions(), onNext: () {}, onScore: (c, t) => score = (c, t)),
      )));
      await tester.pumpAndSettle();
      final green = Colors.green.shade700;

      await _pick(tester, '을');
      expect(find.text('Look at the last sound.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(tileBorder(tester, '를'), isNot(green));

      // Nothing can be picked until Try Again, as before
      await _tap(tester, find.text('Try Again'));
      await _pick(tester, '은');
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(tileBorder(tester, '를'), green);

      await _tap(tester, find.text('Try Again'));
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      await _pick(tester, '를');
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Yes!'), findsOneWidget);

      // The next question starts counting misses again
      await _tap(tester, find.text('Next'));
      await _pick(tester, '은');
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      await _tap(tester, find.text('Try Again'));
      await _pick(tester, '을');
      await _tap(tester, find.text('Finish Practice'));
      expect(score, (0, 2));
    });

    testWidgets('listen_match has no retry, so a miss still shows what was heard', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: PracticeStepWidget(
          content: const {
            'quizType': 'listen_match',
            'items': ['ㅏ', 'ㅓ'],
          },
          onNext: () {},
        ),
      )));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      await _tap(tester, find.text('ㅏ'));
      await _tap(tester, find.text('Check'));
      if (find.text('Next').evaluate().isNotEmpty && find.byIcon(Icons.cancel_rounded).evaluate().isEmpty) {
        // ㅏ was right: answer ㅏ again, which is now wrong
        await _tap(tester, find.text('Next'));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        await _tap(tester, find.text('ㅏ'));
        await _tap(tester, find.text('Check'));
      }
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    Map<String, dynamic> sentenceOf(List<Map<String, dynamic>> chunks) =>
        {'korean': '커피', 'english': 'Coffee', 'tts': false, 'chunks': chunks};

    testWidgets('"Tap a word" only where a word really splits', (tester) async {
      Future<void> show(Map<String, dynamic> sentence) async {
        await tester.pumpWidget(_app(Scaffold(
          body: IntroductionStepWidget(
            key: UniqueKey(),
            content: {
              'sentences': [sentence],
            },
            onNext: () {},
          ),
        )));
        await tester.pumpAndSettle();
      }

      await show(sentenceOf([
        {
          'display': '커피',
          'tokens': [
            {'text': '커피', 'meaning': 'coffee'},
          ],
        },
      ]));
      expect(find.text('Tap a word to see its parts'), findsNothing);

      // A vocabulary card can still be tapped for its meaning
      await _tap(tester, find.text('커피').first);
      expect(find.text('coffee'), findsOneWidget);

      await show(sentenceOf([
        {
          'display': '커피를',
          'tokens': [
            {'text': '커피', 'meaning': 'coffee'},
            {'text': '를', 'meaning': 'object marker'},
          ],
        },
      ]));
      expect(find.text('Tap a word to see its parts'), findsOneWidget);
    });

    testWidgets('sentence building says "Build the sentence" and its translation once', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      StepModel step(String id, String instruction) => StepModel(
            stepId: id,
            orderNum: 1,
            stepType: 'agglutinative_quiz',
            title: 'Sentence Building #1',
            instruction: instruction,
            contentObj: _buildContent,
          );
      Future<void> show(StepModel step) async {
        await tester.pumpWidget(ProviderScope(
          child: _app(LessonScreen(
            key: UniqueKey(),
            lesson: LessonModel(
              lessonId: 'x',
              unitId: 1,
              unitTitle: 'U',
              orderNum: 1,
              title: 'L',
              description: '',
              difficultyLevel: 1,
              estimatedMinutes: 5,
              isPublished: true,
              steps: [step],
            ),
          )),
        ));
        await tester.pumpAndSettle();
      }

      await show(step('1', 'Build the sentence: "I, coffee"'));
      expect(find.text('Build the sentence'), findsOneWidget);
      expect(find.text('I, coffee'), findsOneWidget);
      expect(find.textContaining('Build the sentence:'), findsNothing);

      // What follows the repeated part stays in the header
      await show(step('2', 'Build the sentence: "I, coffee" Split 은/는.'));
      expect(find.textContaining('Split 은/'), findsOneWidget);
      expect(find.textContaining('Build the sentence:'), findsNothing);

      // Any other instruction is left alone
      await show(step('3', 'Put the blocks in order.'));
      expect(find.text('Put the blocks in order.'), findsOneWidget);
    });
  });
}
