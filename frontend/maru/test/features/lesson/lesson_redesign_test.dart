import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lesson/models/agglutinative_quiz_model.dart';
import 'package:maru/features/lesson/models/lesson_model.dart';
import 'package:maru/features/lesson/models/step_model.dart';
import 'package:maru/features/lesson/providers/lesson_provider.dart';
import 'package:maru/features/lesson/screens/lesson_list_screen.dart';
import 'package:maru/features/lesson/screens/lesson_screen.dart';
import 'package:maru/features/lesson/screens/unit_selection_screen.dart';
import 'package:maru/features/lesson/widgets/agglutinative_step_widget.dart';
import 'package:maru/features/lesson/widgets/completion_step_widget.dart';
import 'package:maru/features/lesson/widgets/introduction_step_widget.dart';
import 'package:maru/features/lesson/widgets/practice_step_widget.dart';
import 'package:maru/features/progress/models/user_progress_model.dart';
import 'package:maru/features/progress/providers/user_progress_provider.dart';
import 'package:maru/features/progress/repositories/user_progress_repository.dart';

/// Characters loop forever; reduced motion lets pumpAndSettle finish.
Widget _app(Widget home, {bool reduceMotion = true}) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: home,
    );

/// A small phone: any RenderFlex overflow fails the test.
void _phone(WidgetTester tester, {Size size = const Size(320, 568)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

LessonModel _lesson(String id, {int order = 1, int unit = 1, List<StepModel>? steps}) => LessonModel(
      lessonId: id,
      unitId: unit,
      unitTitle: 'Introduce Yourself',
      orderNum: order,
      title: 'Lesson $order',
      description: 'Description of lesson $order',
      difficultyLevel: 1,
      estimatedMinutes: 5,
      isPublished: true,
      steps: steps ?? [StepModel(stepId: 's', orderNum: 1, stepType: 'intro', contentObj: const {})],
    );

UserProgressResponseModel _record(String id, String status, {int step = 0, int stars = 0}) => UserProgressResponseModel(
      lessonId: id,
      status: status,
      currentStep: step,
      score: 90,
      starsEarned: stars,
      attempts: 1,
    );

final _fillBlank = {
  'exercises': [
    {
      'type': 'fill_blank',
      'instruction': 'I like apples.',
      'sentence': '저는 사과 [ ? ] 좋아해요.',
      'options': ['을', '를'],
      'answer': '를',
      'feedback': {'correct': 'Correct! 사과 ends in a vowel.'},
    },
  ],
};

/// Lesson text carries WORD JOINERs for word-level line breaks: match with them removed.
Finder _ko(String text) => find.byWidgetPredicate(
      (w) => w is Text && w.data?.replaceAll('\u2060', '') == text,
    );

class _FakeProgressService extends UserProgressService {
  int? submittedScore;
  bool submitted = false;

  _FakeProgressService() : super(_NoRepository());

  @override
  Future<UserProgressResponseModel> submitCompletion({
    required String lessonId,
    required int? score,
    required int timeSpentSeconds,
    required int stepCount,
  }) async {
    submitted = true;
    submittedScore = score;
    return _record(lessonId, 'completed', stars: 1);
  }
}

class _NoRepository extends Fake implements UserProgressRepository {}

void main() {
  group('unit and lesson list', () {
    testWidgets('unit cards show real progress, and a unit with no lessons is locked', (tester) async {
      _phone(tester);
      await tester.pumpWidget(ProviderScope(
        retry: (_, __) => null, // show the failed unit at once
        overrides: [
          unitLessonsProvider(0).overrideWith((ref) async => [_lesson('a', unit: 0), _lesson('b', order: 2, unit: 0)]),
          unitLessonsProvider(1).overrideWith((ref) async => []),
          unitLessonsProvider(2).overrideWith((ref) async => throw Exception('network')),
          unitLessonsProvider(3).overrideWith((ref) async => [_lesson('c', unit: 3)]),
          unitProgressProvider(0).overrideWith((ref) async => {'a': _record('a', 'completed', step: 1, stars: 2)}),
          unitProgressProvider(1).overrideWith((ref) async => {}),
          unitProgressProvider(2).overrideWith((ref) async => {}),
          unitProgressProvider(3).overrideWith((ref) async => {'c': _record('c', 'in_progress', step: 0)}),
        ],
        child: _app(const UnitSelectionScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 lessons complete'), findsOneWidget);
      expect(find.text('2 / 6'), findsOneWidget); // stars
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      await tester.scrollUntilVisible(find.text("Couldn't load lessons. Tap to retry."), 100);
      expect(find.text("Couldn't load lessons. Tap to retry."), findsOneWidget);
      await tester.scrollUntilVisible(find.text('1 lesson · 1 in progress'), 100);
      expect(find.text('1 lesson · 1 in progress'), findsOneWidget);
      // The raw exception never reaches the screen
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('lesson list marks completed, continue and in-progress lessons', (tester) async {
      _phone(tester, size: const Size(320, 900));
      final steps = List.generate(9, (i) => StepModel(stepId: '$i', orderNum: i, stepType: 'intro', contentObj: const {}));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          unitLessonsProvider(1).overrideWith((ref) async => [
                _lesson('a', steps: steps),
                _lesson('b', order: 2, steps: steps),
                _lesson('c', order: 3, steps: steps),
              ]),
          unitProgressProvider(1).overrideWith((ref) async => {
                'a': _record('a', 'completed', step: 9, stars: 3),
                'b': _record('b', 'in_progress', step: 6),
                'c': _record('c', 'in_progress', step: 2),
              }),
        ],
        child: _app(const LessonListScreen(unitId: 1)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 of 3 lessons complete'), findsOneWidget);
      expect(find.text('Continue · step 7 of 9'), findsOneWidget);
      expect(find.text('In progress · step 3 of 9'), findsOneWidget);

      // Resume dialog still offers both choices with the same numbers
      await tester.tap(find.text('Lesson 2'));
      await tester.pumpAndSettle();
      expect(find.text('You stopped at step 7 of 9.'), findsOneWidget);
      expect(find.text('Start over'), findsOneWidget);
    });
  });

  group('practice step', () {
    testWidgets('wrong answer: character feedback, Try Again, and the first try stays wrong', (tester) async {
      (int, int)? score;
      var finished = false;
      await tester.pumpWidget(_app(Scaffold(
        body: PracticeStepWidget(
          content: _fillBlank,
          onNext: () => finished = true,
          onScore: (c, t) => score = (c, t),
        ),
      )));
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull); // nothing selected

      await tester.tap(find.text('을'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      expect(find.text('Try again.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('를'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      expect(_ko('Correct! 사과 ends in a vowel.'), findsOneWidget);

      await tester.tap(find.text('Finish Practice'));
      await tester.pumpAndSettle();
      expect(score, (0, 1));
      expect(finished, isTrue);
    });

    testWidgets('listen_match: every item once, score counts right answers only', (tester) async {
      (int, int)? score;
      await tester.pumpWidget(_app(Scaffold(
        body: PracticeStepWidget(
          content: const {
            'quizType': 'listen_match',
            'items': ['ㅏ', 'ㅓ'],
          },
          onNext: () {},
          onScore: (c, t) => score = (c, t),
        ),
      )));
      // The quiz says its first target after a short delay
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Always pick ㅏ: right on exactly one of the two questions, whatever the order
      for (var q = 0; q < 2; q++) {
        await tester.tap(find.text('ㅏ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Check'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(RegExp(r'^(Correct! That was|Not quite — you heard)')),
          findsOneWidget,
        );
        await tester.tap(find.textContaining(RegExp(r'^(Next|Finish Quiz)')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
      }
      expect(score, (1, 2));
    });

    testWidgets('user_input keeps its checks and fits a small phone', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(Scaffold(
        body: PracticeStepWidget(
          content: const {
            'exercises': [
              {
                'type': 'user_input',
                'instruction': 'Introduce yourself.',
                'template': '저는 {input}입니다.',
                'feedback': {'correct': 'Nice to meet you!'},
              },
            ],
          },
          onNext: () {},
        ),
      )));
      await tester.pumpAndSettle();
      expect(_ko('저는 ____입니다.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '저는');
      await tester.pumpAndSettle();
      expect(find.textContaining('Type only the missing part'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '하도윤');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(find.text('Nice to meet you!'), findsOneWidget);
      expect(_ko('저는 하도윤입니다.'), findsOneWidget);
    });
  });

  group('introduction step', () {
    final sentence = {
      'korean': '저는 커피를 좋아해요.',
      'english': 'I like coffee.',
      'tts': false,
      'chunks': [
        {
          'display': '커피를',
          'tokens': [
            {'text': '커피', 'meaning': 'coffee'},
            {'text': '를', 'meaning': 'object marker'},
          ],
        },
        {'display': '=', 'tokens': <dynamic>[]},
      ],
    };

    testWidgets('tap analysis opens, switches off, and non-analyzable chunks do nothing', (tester) async {
      _phone(tester);
      var nexted = false;
      await tester.pumpWidget(_app(Scaffold(
        body: IntroductionStepWidget(
          content: {
            'explanation': {'title': 'I like ...'},
            'sentences': [sentence, sentence],
          },
          onNext: () => nexted = true,
        ),
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('=').first);
      await tester.pumpAndSettle();
      expect(find.text('object marker'), findsNothing);

      await tester.tap(find.text('커피를').first);
      await tester.pumpAndSettle();
      expect(find.text('object marker'), findsOneWidget);

      // Same word in another sentence moves the panel instead of opening two
      await tester.tap(find.text('커피를').last);
      await tester.pumpAndSettle();
      expect(find.text('object marker'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('object marker'), findsNothing);

      await tester.tap(find.text('Continue'));
      expect(nexted, isTrue);
    });

    testWidgets('letter cards page through to Continue; a long word fits the card', (tester) async {
      _phone(tester);
      var nexted = false;
      await tester.pumpWidget(_app(Scaffold(
        body: IntroductionStepWidget(
          content: const {
            'items': [
              {'jamo': 'ㅏ', 'romanization': 'a'},
              {'jamo': '안녕하세요감사합니다', 'romanization': 'annyeonghaseyo'},
            ],
          },
          onNext: () => nexted = true,
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      expect(nexted, isTrue);
    });
  });

  group('sentence building touch feel', () {
    final content = {
      'sentence': '저는 커피를',
      'translation': 'I, coffee',
      'elements': [
        {'id': 'e1', 'isTarget': true, 'correct_rabbit': ['저는'], 'correct_turtle': ['저는']},
        {'id': 'e2', 'isTarget': true, 'correct_rabbit': ['커피를'], 'correct_turtle': ['커피', '를']},
      ],
      'options': [
        {'id': 'o1', 'mode': 'rabbit', 'text': '저는'},
        {'id': 'o2', 'mode': 'rabbit', 'text': '커피를'},
        {'id': 'o3', 'mode': 'turtle', 'text': '저는'},
        {'id': 'o4', 'mode': 'turtle', 'text': '커피'},
        {'id': 'o5', 'mode': 'turtle', 'text': '를'},
      ],
    };

    Finder option(String text) => find
        .descendant(of: find.byType(Draggable<AgglutinativeOption>), matching: find.text(text))
        .first;

    // Runs a block flight (and the rest of a short animation) to its end
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    testWidgets('with animations on: blocks fly, land, return, and the phase advances', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(
        Scaffold(body: AgglutinativeStepWidget(content: content, onNext: () {})),
        reduceMotion: false,
      ));
      await settle(tester);

      await tester.tap(option('저는'));
      await tester.pump(); // layout
      await tester.pump(const Duration(milliseconds: 100)); // mid-flight
      // The flying copy is on screen while the slot's own text is hidden
      expect(find.text('저는'), findsNWidgets(2));
      await settle(tester);
      expect(find.text('저는'), findsOneWidget);

      // Tap the placed block: it goes home to the tray
      await tester.tap(find.text('저는'));
      await tester.pump();
      await settle(tester);
      expect(option('저는'), findsOneWidget);
      expect(find.text('...'), findsNWidgets(2));

      await tester.tap(option('저는'));
      await settle(tester);
      await tester.tap(option('커피를'));
      await settle(tester);
      await tester.tap(find.text('Check'));
      await tester.pump(const Duration(milliseconds: 400)); // right answers show green
      await settle(tester);
      await settle(tester);

      // 🐢 phase, with 저는 stays-whole pre-placed
      expect(find.text('?'), findsNWidgets(2));
      expect(find.text('Check & Finish'), findsOneWidget);

      // Leaving the step while a block is in the air must clean up after itself
      await tester.tap(option('커피'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(_app(const SizedBox(), reduceMotion: false));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('many blocks fit a small phone', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(Scaffold(
        body: AgglutinativeStepWidget(
          content: {
            'sentence': '민수는 어제 집에 있었어요.',
            'translation': 'Minsu was at home yesterday, and it is a long translation.',
            'elements': [
              for (final (i, w) in ['민수는', '어제', '집에', '있었어요'].indexed)
                {'id': 'e$i', 'isTarget': true, 'correct_rabbit': [w], 'correct_turtle': [w]},
            ],
            'options': [
              for (final (i, w) in ['민수는', '어제', '집에', '있었어요', '있았어요', '있습니다요', '민수가'].indexed)
                {'id': 'o$i', 'mode': 'rabbit', 'text': w},
            ],
          },
          onNext: () {},
        ),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('completion and the lesson frame', () {
    testWidgets('completion shows the real score only when there is one', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(Scaffold(
        body: CompletionStepWidget(
          content: const {
            'text': 'You learned something.',
            'highlights': ['을', '를'],
          },
          title: 'Lesson 3 Mastered!',
          scorePercent: 80,
          onNext: () {},
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Score: 80%'), findsOneWidget);
      expect(find.text('What you learned'.toUpperCase()), findsOneWidget);

      await tester.pumpWidget(_app(Scaffold(
        body: CompletionStepWidget(content: const {}, onNext: () {}),
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('Score'), findsNothing);
      expect(find.text('Lesson Complete!'), findsOneWidget);
    });

    testWidgets('a full lesson submits first-try accuracy, and the bar is not purple', (tester) async {
      _phone(tester, size: const Size(390, 844));
      final service = _FakeProgressService();
      final lesson = _lesson('u1-l3', steps: [
        StepModel(stepId: '1', orderNum: 1, stepType: 'practice', title: 'Pattern Practice', contentObj: _fillBlank),
        StepModel(stepId: '2', orderNum: 2, stepType: 'completion', title: 'Done!', contentObj: const {}),
      ]);

      await tester.pumpWidget(ProviderScope(
        overrides: [progressServiceProvider.overrideWithValue(service)],
        child: _app(Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
              ),
              child: const Text('open'),
            ),
          ),
        )),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsOneWidget);
      final context = tester.element(find.byType(LessonScreen));
      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.backgroundColor, isNot(Theme.of(context).colorScheme.primary));

      await tester.tap(find.text('을'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('를'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish Practice'));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('Score: 0%'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(service.submitted, isTrue);
      expect(service.submittedScore, 0);
      expect(find.text('open'), findsOneWidget); // back on the list
    });
  });
}
