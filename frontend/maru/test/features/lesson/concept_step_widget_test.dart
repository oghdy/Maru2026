import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lesson/models/agglutinative_quiz_model.dart';
import 'package:maru/features/lesson/models/lesson_model.dart';
import 'package:maru/features/lesson/models/step_model.dart';
import 'package:maru/features/lesson/screens/lesson_screen.dart';
import 'package:maru/features/lesson/widgets/agglutinative_step_widget.dart';
import 'package:maru/features/lesson/widgets/concept_step_widget.dart';
import 'package:maru/features/lesson/widgets/lesson_style.dart';
import 'package:maru/features/lesson/widgets/practice_step_widget.dart';
import 'package:maru/features/progress/models/user_progress_model.dart';
import 'package:maru/features/progress/providers/user_progress_provider.dart';
import 'package:maru/features/progress/repositories/user_progress_repository.dart';
import 'package:maru/shared/characters/maru_character.dart';

Widget _app(Widget home, {bool reduceMotion = true}) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: home,
    );

void _phone(WidgetTester tester, {Size size = const Size(320, 568)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Map<String, dynamic> _part(String text, String meaning, {bool highlight = false}) =>
    {'text': text, 'meaning': meaning, 'highlight': highlight};

Map<String, dynamic> _concept({Map<String, dynamic>? example}) => {
      'character': 'turtle',
      'mood': 'happy',
      'explanation': 'To talk about the past, put 었 in the middle.',
      'example': example,
      'tap_to_assemble': example != null,
    };

final _ate = {
  'sentence': '먹었어요.',
  'translation': 'ate',
  'tts': true,
  'words': [
    {
      'parts': [_part('먹', 'eat'), _part('었', 'past', highlight: true), _part('어요', 'polite ending')],
    },
  ],
};

final _longExample = {
  'sentence': '유미는 도서관에서 책을 읽었어요.',
  'translation': 'Yumi read a book at the library, and this translation is long on purpose.',
  'tts': true,
  'words': [
    {'parts': [_part('유미는', 'Yumi (topic)')]},
    {'parts': [_part('도서관에서', 'at the library (action place)')]},
    {'parts': [_part('책을', 'book (object)')]},
    {
      'parts': [_part('읽', 'read'), _part('었', 'past', highlight: true), _part('어요', 'polite ending')],
    },
  ],
};

FilledButton _continue(WidgetTester tester) => tester.widget<FilledButton>(
      find.ancestor(of: find.text('Continue'), matching: find.byType(FilledButton)),
    );

Finder _bubbleText(String text) => find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().replaceAll('⁠', '').contains(text),
    );

Finder _ko(String text) => find.byWidgetPredicate(
      (w) => w is Text && w.data?.replaceAll('⁠', '') == text,
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
    return UserProgressResponseModel(
      lessonId: lessonId,
      status: 'completed',
      currentStep: stepCount,
      score: score ?? 0,
      starsEarned: 3,
      attempts: 1,
    );
  }
}

class _NoRepository extends Fake implements UserProgressRepository {}

final _check = {
  'graded': false,
  'character': 'turtle',
  'exercises': [
    {
      'type': 'fill_blank',
      'instruction': 'I ate bread.',
      'sentence': '저는 빵을 [ ? ].',
      'options': ['먹어요', '먹었어요'],
      'answer': '먹었어요',
      'feedback': {'correct': 'Yes! 었 makes it past.', 'incorrect': 'Look for the 었 block.'},
    },
  ],
};

LessonModel _lesson(List<StepModel> steps) => LessonModel(
      lessonId: 'u3-l2-learn',
      unitId: 3,
      unitTitle: 'Say More',
      orderNum: 2,
      title: 'Learn: Past tense',
      description: 'Slowly learn.',
      difficultyLevel: 1,
      estimatedMinutes: 5,
      isPublished: true,
      steps: steps,
    );

StepModel _step(String type, Map<String, dynamic> content, {int order = 1, String title = 'Title'}) =>
    StepModel(stepId: '$order', orderNum: order, stepType: type, title: title, contentObj: content);

Future<_FakeProgressService> _open(WidgetTester tester, LessonModel lesson, {int start = 0}) async {
  _phone(tester, size: const Size(390, 844));
  final service = _FakeProgressService();
  await tester.pumpWidget(ProviderScope(
    overrides: [progressServiceProvider.overrideWithValue(service)],
    child: _app(Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson, initialStepIndex: start)),
          ),
          child: const Text('open'),
        ),
      ),
    )),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return service;
}

void main() {
  group('concept card', () {
    testWidgets('Continue stays off until the example is tapped together', (tester) async {
      var nexted = false;
      await tester.pumpWidget(_app(Scaffold(
        body: ConceptStepWidget(content: _concept(example: _ate), onNext: () => nexted = true),
      )));
      await tester.pumpAndSettle();

      expect(_bubbleText('put 었 in the middle'), findsOneWidget);
      expect(find.text('polite ending'), findsOneWidget); // each loose block says what it means
      expect(find.text('Tap to join the blocks'), findsOneWidget);
      expect(find.text('ate'), findsNothing);
      expect(find.byType(LessonSpeakerButton), findsNothing);
      expect(_continue(tester).onPressed, isNull);

      // Three blocks: the first tap joins two of them and the card isn't done yet
      await tester.tap(find.text('먹'));
      await tester.pumpAndSettle();
      expect(find.text('ate'), findsNothing);
      expect(_continue(tester).onPressed, isNull);

      // A tap anywhere on the card counts, so nobody gets stuck looking for the right spot
      await tester.tap(find.text('Tap to join the blocks'));
      await tester.pumpAndSettle();
      expect(find.text('ate'), findsOneWidget);
      expect(find.text('었 = past'), findsOneWidget);
      expect(find.byType(LessonSpeakerButton), findsOneWidget);
      expect(find.text('Tap to join the blocks'), findsNothing);
      expect(_continue(tester).onPressed, isNotNull);

      await tester.tap(find.text('Continue'));
      expect(nexted, isTrue);
    });

    testWidgets('a card with no example can continue at once', (tester) async {
      var nexted = false;
      await tester.pumpWidget(_app(Scaffold(
        body: ConceptStepWidget(content: _concept(), onNext: () => nexted = true),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Tap to join the blocks'), findsNothing);
      await tester.tap(find.text('Continue'));
      expect(nexted, isTrue);
    });

    testWidgets('an example without tap_to_assemble starts built', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: ConceptStepWidget(
          content: {..._concept(example: _ate), 'tap_to_assemble': false},
          onNext: () {},
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('ate'), findsOneWidget);
      expect(_continue(tester).onPressed, isNotNull);
    });

    testWidgets('a sentence with nothing to join needs one tap', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: ConceptStepWidget(
          content: _concept(example: {
            'sentence': '어제',
            'translation': 'yesterday',
            'tts': false,
            'words': [
              {'parts': [_part('어제', 'yesterday', highlight: true)]},
            ],
          }),
          onNext: () {},
        ),
      )));
      await tester.pumpAndSettle();
      expect(_continue(tester).onPressed, isNull);
      await tester.tap(find.text('어제'));
      await tester.pumpAndSettle();
      expect(_continue(tester).onPressed, isNotNull);
      expect(find.byType(LessonSpeakerButton), findsNothing); // tts: false
    });

    testWidgets('fits a small phone before and after building, animations on', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
        Scaffold(body: ConceptStepWidget(content: _concept(example: _longExample), onNext: () {})),
        reduceMotion: false,
      ));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('읽'));
      await tester.pump(const Duration(milliseconds: 100)); // mid-join
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('읽'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(_continue(tester).onPressed, isNotNull);

      await tester.pumpWidget(_app(const SizedBox(), reduceMotion: false));
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('ungraded checks', () {
    testWidgets('graded false: no score, its own wrong-answer note, no counter, chosen character', (tester) async {
      (int, int)? score;
      var finished = false;
      await tester.pumpWidget(_app(Scaffold(
        body: PracticeStepWidget(content: _check, onNext: () => finished = true, onScore: (c, t) => score = (c, t)),
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('Practice 1 of'), findsNothing);

      await tester.tap(_ko('먹어요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      expect(_ko('Look for the 었 block.'), findsOneWidget);
      expect(find.text('Try again.'), findsNothing);
      expect(
        tester.widget<LessonFeedbackCard>(find.byType(LessonFeedbackCard)).character,
        MaruCharacterKind.turtle,
      );

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      await tester.tap(_ko('먹었어요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      expect(_ko('Yes! 었 makes it past.'), findsOneWidget);
      await tester.tap(find.text('Finish Practice'));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
      expect(score, isNull);
    });

    testWidgets('old lessons keep their counter, words, character and score', (tester) async {
      (int, int)? score;
      Map<String, dynamic> question(String answer) => {
            'type': 'fill_blank',
            'instruction': 'Pick one.',
            'sentence': '저는 [ ? ].',
            'options': ['가', '나'],
            'answer': answer,
            'feedback': {'correct': 'Good one.'},
          };
      await tester.pumpWidget(_app(Scaffold(
        body: PracticeStepWidget(
          content: {'exercises': [question('가'), question('나')]},
          onNext: () {},
          onScore: (c, t) => score = (c, t),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Practice 1 of 2'), findsOneWidget);

      await tester.tap(find.text('나'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      expect(find.text('Try again.'), findsOneWidget);
      expect(tester.widget<LessonFeedbackCard>(find.byType(LessonFeedbackCard)).character, isNull);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('가'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('나'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish Practice'));
      await tester.pumpAndSettle();
      expect(score, (1, 2));
    });
  });

  group('lesson score', () {
    List<StepModel> learn() => [
          _step('concept', _concept(), order: 1),
          _step('practice', _check, order: 2),
          _step('completion', const {'text': 'Done.'}, order: 3, title: 'Past Tense Learned!'),
        ];

    testWidgets('a Learn lesson finished by resuming: 100, no Score line', (tester) async {
      final service = await _open(tester, _lesson(learn()), start: 2);
      expect(find.textContaining('Score'), findsNothing);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(service.submittedScore, 100);
    });

    testWidgets('a full Learn run with a wrong answer still sends 100', (tester) async {
      final service = await _open(tester, _lesson(learn()));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(_ko('먹어요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      await tester.tap(_ko('먹었어요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish Practice'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Score'), findsNothing);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(service.submitted, isTrue);
      expect(service.submittedScore, 100);
    });

    testWidgets('a resumed lesson with graded steps and nothing graded since sends no score', (tester) async {
      final service = await _open(
        tester,
        _lesson([
          _step('practice', {
            'exercises': [
              {'type': 'fill_blank', 'sentence': 's', 'options': ['a', 'b'], 'answer': 'a'},
            ],
          }, order: 1),
          _step('completion', const {}, order: 2, title: 'Done'),
        ]),
        start: 1,
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(service.submitted, isTrue);
      expect(service.submittedScore, isNull);
    });
  });

  group('small fixes from the redesign review', () {
    testWidgets('Korean breaks between words only, and the marks are display-only', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(body: LessonText('고 싶어요 hello'))));
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, '고 싶⁠어⁠요 hello');
      expect(text.semanticsLabel, '고 싶어요 hello');

      await tester.pumpWidget(_app(const Scaffold(body: LessonText('hello'))));
      expect(tester.widget<Text>(find.byType(Text)).semanticsLabel, isNull);
    });

    testWidgets('the split instruction is on the card only, and a wrong answer still gets the hint bubble',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(Scaffold(
        body: AgglutinativeStepWidget(
          content: {
            'sentence': '저는 커피를',
            'translation': 'I, coffee',
            'elements': [
              {'id': 'e1', 'isTarget': true, 'correct_rabbit': ['저는'], 'correct_turtle': ['저는']},
              {
                'id': 'e2',
                'isTarget': true,
                'correct_rabbit': ['커피를'],
                'correct_turtle': ['커피', '를'],
                'turtle_explanation': '커피 (coffee) + 를 (object marker)',
              },
            ],
            'options': [
              {'id': 'o1', 'mode': 'rabbit', 'text': '저는'},
              {'id': 'o2', 'mode': 'rabbit', 'text': '커피를'},
              {'id': 'o3', 'mode': 'turtle', 'text': '커피'},
              {'id': 'o4', 'mode': 'turtle', 'text': '를'},
            ],
          },
          onNext: () {},
        ),
      )));
      await tester.pumpAndSettle();

      Finder option(String text) => find
          .descendant(of: find.byType(Draggable<AgglutinativeOption>), matching: find.text(text))
          .first;

      await tester.tap(option('저는'));
      await tester.pumpAndSettle();
      await tester.tap(option('커피를'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      // 🐰 praises and steps aside. No bubble repeats the instruction.
      expect(_bubbleText('Great! You built the sentence.'), findsOneWidget);
      expect(find.text('Now split the part this lesson teaches. Grey blocks stay whole.'), findsOneWidget);
      expect(_bubbleText('Now split'), findsOneWidget); // the card's own line
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
      expect(_bubbleText('Great! You built the sentence.'), findsNothing);
      expect(_bubbleText('Now split'), findsOneWidget);

      await tester.tap(option('를'));
      await tester.pumpAndSettle();
      await tester.tap(option('커피'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check & Finish'));
      await tester.pumpAndSettle();
      expect(_bubbleText('Hint: 커피 (coffee) + 를 (object marker)'), findsOneWidget);
    });
  });
}
