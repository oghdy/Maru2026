import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lesson/models/agglutinative_quiz_model.dart';
import 'package:maru/features/lesson/utils/lesson_sounds.dart';
import 'package:maru/features/lesson/widgets/agglutinative_step_widget.dart';
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

Finder _block(String text) =>
    find.descendant(of: find.byType(Draggable<AgglutinativeOption>), matching: find.text(text)).first;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pick(WidgetTester tester, String option) async {
  await _tap(tester, find.text(option));
  await _tap(tester, find.text('Check Answer'));
}

void main() {
  late int chimes;

  setUp(() {
    chimes = 0;
    LessonSounds.onCorrectForTest = () => chimes++;
  });
  tearDown(() => LessonSounds.onCorrectForTest = null);

  group('when the chime plays', () {
    testWidgets('practice: right on the first try and on a retry, never on a wrong answer', (tester) async {
      await tester.pumpWidget(_app(Scaffold(body: PracticeStepWidget(content: _threeOptions(), onNext: () {}))));
      await tester.pumpAndSettle();

      await _pick(tester, '을');
      expect(chimes, 0);
      await _tap(tester, find.text('Try Again'));
      await _pick(tester, '를');
      expect(chimes, 1);

      await _tap(tester, find.text('Next'));
      await _pick(tester, '을');
      expect(chimes, 2);
    });

    testWidgets('an ungraded check in a Learn lesson also rewards a right answer', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: PracticeStepWidget(content: {..._threeOptions(), 'graded': false}, onNext: () {}),
      )));
      await tester.pumpAndSettle();

      await _pick(tester, '를');
      expect(chimes, 1);
    });

    testWidgets('listen_match: only the right answers', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: PracticeStepWidget(
          content: const {
            'quizType': 'listen_match',
            'items': ['ㅏ', 'ㅓ'],
          },
          onNext: () {},
        ),
      )));
      await tester.pump(const Duration(milliseconds: 600)); // first question's auto-play delay
      await tester.pumpAndSettle();

      // Always answering ㅏ is right once and wrong once, whatever the order
      for (var question = 0; question < 2; question++) {
        await _tap(tester, find.text('ㅏ'));
        await _tap(tester, find.text('Check'));
        if (question == 0) {
          await _tap(tester, find.text('Next'));
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pumpAndSettle();
        }
      }
      expect(chimes, 1);
    });

    testWidgets('typed answer: once, when it passes the checks', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: PracticeStepWidget(
          content: const {
            'exercises': [
              {'type': 'user_input', 'instruction': 'Your name', 'template': '저는 {input}입니다.'},
            ],
          },
          onNext: () {},
        ),
      )));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '사라');
      await tester.pumpAndSettle();
      expect(chimes, 0);
      await _tap(tester, find.text('Check'));
      expect(chimes, 1);
    });

    testWidgets('sentence building: both phases when right, not when wrong', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(Scaffold(body: AgglutinativeStepWidget(content: _buildContent, onNext: () {}))));
      await tester.pumpAndSettle();

      // 🐰 wrong, then right
      await _tap(tester, _block('저도'));
      await _tap(tester, find.text('Check'));
      expect(chimes, 0);
      await _tap(tester, find.text('저도').first); // back to the tray
      await _tap(tester, _block('저는'));
      await _tap(tester, find.text('Check'));
      expect(chimes, 1);

      // 🐢 right
      await _tap(tester, _block('저'));
      await _tap(tester, _block('는'));
      await _tap(tester, find.text('Check & Finish'));
      expect(chimes, 2);
      await tester.pump(const Duration(seconds: 2)); // the step's closing delay
    });
  });

  group('the real player', () {
    testWidgets('without the audio plugin (tests) nothing throws and nothing is left running', (tester) async {
      LessonSounds.onCorrectForTest = null;
      LessonSounds.hold();
      await tester.pump(const Duration(milliseconds: 50));
      LessonSounds.playCorrect();
      await tester.pump(const Duration(milliseconds: 50));
      LessonSounds.hold(); // the next lesson's screen opens before this one closes
      LessonSounds.release();
      LessonSounds.playCorrect();
      await tester.pump(const Duration(milliseconds: 50));
      LessonSounds.release();
      LessonSounds.release(); // an extra release is harmless
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });
  });

  test('the bundled chime is short, 16-bit PCM, loud enough, and starts and ends at silence', () {
    expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/sounds/'));
    final bytes = File('assets/sounds/correct.wav').readAsBytesSync();
    final data = ByteData.sublistView(bytes);

    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(data.getUint16(20, Endian.little), 1, reason: 'PCM');
    expect(data.getUint16(22, Endian.little), 1, reason: 'mono');
    expect(data.getUint16(34, Endian.little), 16, reason: '16-bit');
    final rate = data.getUint32(24, Endian.little);
    final byteCount = data.getUint32(40, Endian.little);
    final seconds = byteCount / 2 / rate;
    expect(seconds, inInclusiveRange(0.25, 0.45));
    expect(bytes.length, lessThan(64 * 1024));

    final samples = [for (var i = 0; i < byteCount ~/ 2; i++) data.getInt16(44 + i * 2, Endian.little)];
    final peak = samples.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
    expect(peak, inInclusiveRange(16000, 32000), reason: 'audible and not clipped');
    expect(samples.first.abs(), lessThan(8));
    expect(samples.last.abs(), lessThan(8));
  });
}
