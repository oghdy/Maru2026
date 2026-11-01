import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lesson/widgets/lesson_style.dart' show LessonText;
import 'package:maru/features/mission_chat/models/chat_message_model.dart';
import 'package:maru/features/mission_chat/models/chat_turn_response.dart';
import 'package:maru/features/mission_chat/models/korean_text.dart';
import 'package:maru/features/mission_chat/models/mission_clearance_model.dart';
import 'package:maru/features/mission_chat/models/mission_scenario.dart';
import 'package:maru/features/mission_chat/models/mission_setup_response.dart';
import 'package:maru/features/mission_chat/models/suggestion_response.dart';
import 'package:maru/features/mission_chat/providers/mission_chat_provider.dart';
import 'package:maru/features/mission_chat/repositories/mission_chat_repository.dart';
import 'package:maru/features/mission_chat/screens/mission_clearance_screen.dart';
import 'package:maru/features/mission_chat/widgets/chat_bubble_widget.dart';
import 'package:maru/features/mission_chat/widgets/chat_correction_card.dart';
import 'package:maru/features/mission_chat/widgets/chat_mission_panel.dart';

// WEB-5.17.4: steps, praise, "Say it again" and the report comparison (web-demo API_CONTRACT 7).

MissionSetupResponse _setup({List<String>? steps}) => MissionSetupResponse.fromJson({
      'persona': {
        'role': '카페 직원',
        'personality': '친절한',
        'speechStyle': '해요체',
        'honorificLevel': '존댓말',
        'firstMessage': '어서 오세요!',
        'firstMessageEn': 'Welcome!',
      },
      'mission': {
        'title': 'Order a drink',
        'description': 'Order one drink.',
        'clearCondition': {'goalCondition': 'Order one drink.', 'languageCondition': 'Use -요.'},
        'minTurns': 4,
      },
      'adjustmentNotice': null,
      'difficulty': 'easy',
      if (steps != null) 'steps': steps,
      'learnerSpeechLevel': '존댓말',
      'scenarioId': 'cafe',
    });

ChatTurnResponse _turn({
  String severity = 'none',
  String? correct,
  List<int>? completedSteps,
  String? praise,
  int userTurn = 1,
}) =>
    ChatTurnResponse.fromJson({
      'rabbitReply': severity == 'immediate' ? null : '네, 알겠어요.',
      'rabbitReplyEn': severity == 'immediate' ? null : 'Okay.',
      'correction': {
        'severity': severity,
        'issueType': severity == 'none' ? 'none' : 'grammar_error',
        'correctExpression': correct,
        'turtleFeedback': severity == 'none' ? null : '고쳐 봐요.',
        'turtleFeedbackEn': severity == 'none' ? null : 'Try this.',
      },
      'missionStatus': 'in_progress',
      'userTurn': userTurn,
      'minTurns': 4,
      'maxTurns': 7,
      'zone': 'A',
      'completedSteps': completedSteps,
      'praise': praise,
      'praiseEn': praise == null ? null : 'Nice job.',
    });

class _FakeRepo implements MissionChatRepository {
  final List<ChatTurnResponse> replies;
  final List<List<int>> sentSteps = [];
  int chatCalls = 0;

  _FakeRepo(this.replies);

  @override
  Future<MissionSetupResponse> setupMission(Map<String, dynamic> request) async => _setup(steps: ['One', 'Two', 'Three']);

  @override
  Future<ChatTurnResponse> sendChat({
    required String userMessage,
    required List<ChatMessage> history,
    required MissionSetupResponse setup,
    List<int> completedSteps = const [],
  }) async {
    sentSteps.add(completedSteps);
    return replies[chatCalls++];
  }

  @override
  Future<List<MissionScenario>> getScenarios() => throw UnimplementedError();
  @override
  Future<MissionClearanceModel> issueClearance({required List<ChatMessage> history, required MissionSetupResponse setup, String? missionStatus}) =>
      throw UnimplementedError();
  @override
  Future<List<MissionClearanceModel>> getClearances() => throw UnimplementedError();
  @override
  Future<SuggestionResponse> getSuggestion({required List<ChatMessage> history, required MissionSetupResponse setup}) =>
      throw UnimplementedError();
}

Future<(ProviderContainer, _FakeRepo)> _started(List<ChatTurnResponse> replies) async {
  final repo = _FakeRepo(replies);
  final container = ProviderContainer(overrides: [missionChatRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(container.dispose);
  await container.read(missionChatProvider.notifier).setupMission({'scenarioId': 'cafe', 'difficulty': 'easy'});
  return (container, repo);
}

Future<void> _pumpBody(WidgetTester tester, Widget child, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B4EFF))),
    home: MediaQuery(
      data: MediaQueryData(size: size, disableAnimations: true),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 300));
}

// LessonText shows Korean with invisible line-break marks, so find it by its original text.
Finder _lessonText(String text) => find.byWidgetPredicate((w) => w is LessonText && w.text == text);

Finder _semantics(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);

void main() {
  group('normalizeForMatch', () {
    test('ignores spaces, punctuation and case', () {
      expect(isSameSentence('여기서 멀어요?', '여기서멀어요'), isTrue);
      expect(isSameSentence('네, 감사합니다!', '네 감사합니다.'), isTrue);
      expect(isSameSentence('Coffee 주세요', 'coffee주세요'), isTrue);
    });

    test('decomposed Hangul equals composed Hangul', () {
      expect(isSameSentence('멀어요', '멀어요'), isTrue);
    });

    test('a different word is different', () {
      expect(isSameSentence('먼어요', '멀어요'), isFalse);
    });
  });

  group('setup steps', () {
    test('steps come from the echoed fields and go back unchanged', () {
      final setup = _setup(steps: ['Say what you want', 'Say thanks']);
      expect(setup.steps, ['Say what you want', 'Say thanks']);
      expect(setup.toJson()['steps'], ['Say what you want', 'Say thanks']);
      expect(setup.toJson()['scenarioId'], 'cafe');
    });

    test('old setups have no steps', () {
      expect(_setup().steps, isEmpty);
    });
  });

  group('provider', () {
    test('maxTurns comes only from the server', () async {
      final (container, _) = await _started([_turn()]);
      expect(container.read(missionChatProvider).maxTurns, isNull);
      await container.read(missionChatProvider.notifier).sendMessage('커피 주세요');
      expect(container.read(missionChatProvider).maxTurns, 7);
    });

    test('completedSteps go back with the next message', () async {
      final (container, repo) = await _started([_turn(completedSteps: [1]), _turn(completedSteps: [1, 2])]);
      final notifier = container.read(missionChatProvider.notifier);
      await notifier.sendMessage('커피 주세요');
      await notifier.sendMessage('따뜻한 걸로요');
      expect(repo.sentSteps, [[], [1]]);
      expect(container.read(missionChatProvider).completedSteps, [1, 2]);
    });

    test('an immediate correction leaves the steps alone and keeps its sentence', () async {
      final (container, repo) = await _started([
        _turn(completedSteps: [1]),
        _turn(severity: 'immediate', correct: '주세요', completedSteps: [1, 2, 3]),
        _turn(completedSteps: [1, 2]),
      ]);
      final notifier = container.read(missionChatProvider.notifier);
      await notifier.sendMessage('커피 주세요');
      await notifier.sendMessage('줘');
      expect(container.read(missionChatProvider).completedSteps, [1]);
      expect(container.read(missionChatProvider).immediateCorrection?.correctExpression, '주세요');
      await notifier.sendMessage('주세요');
      expect(repo.sentSteps.last, [1]);
    });

    test('a side correction offers the practice, unless it only differs in punctuation', () async {
      final (container, _) = await _started([
        _turn(severity: 'side', correct: '여기서 멀어요?'),
        _turn(severity: 'side', correct: '네, 맞아요.'),
      ]);
      final notifier = container.read(missionChatProvider.notifier);
      await notifier.sendMessage('여기서 먼어요?');
      expect(container.read(missionChatProvider).messages.last.sayAgainTarget, '여기서 멀어요?');
      await notifier.sendMessage('네 맞아요');
      expect(container.read(missionChatProvider).messages.last.sayAgainTarget, isNull);
    });

    test('praise stays on the reply and is not sent as history', () async {
      final (container, _) = await _started([_turn(praise: '잘했어요.')]);
      await container.read(missionChatProvider.notifier).sendMessage('커피 주세요');
      final reply = container.read(missionChatProvider).messages.last;
      expect(reply.praise, '잘했어요.');
      expect(reply.toJson().keys, unorderedEquals(['role', 'content']));
    });

    test('trying the same mission again clears the steps', () async {
      final (container, _) = await _started([_turn(completedSteps: [1, 2])]);
      final notifier = container.read(missionChatProvider.notifier);
      await notifier.sendMessage('커피 주세요');
      notifier.retrySameMission();
      expect(container.read(missionChatProvider).completedSteps, isEmpty);
    });
  });

  group('Say it again', () {
    Future<void> open(WidgetTester tester) async {
      await _pumpBody(
        tester,
        const ChatCorrectionCard(
          type: CorrectionCardType.yellow,
          message: '고쳐 봐요.',
          sayAgainTarget: '여기서 멀어요?',
        ),
      );
      await tester.tap(find.text('Say it again'));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('the same sentence gets praise, spaces and punctuation aside', (tester) async {
      await open(tester);
      expect(_lessonText('여기서 멀어요?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '여기서멀어요');
      await tester.tap(find.byTooltip('Check'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Nice! That sounds natural.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a miss is gentle, and can be retried or skipped', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), '여기서 먼어요');
      await tester.tap(find.byTooltip('Check'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Have another go'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Say it again'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('red card hands the sentence to the reply box', (tester) async {
      var tapped = 0;
      await _pumpBody(
        tester,
        ChatCorrectionCard(type: CorrectionCardType.red, message: '고쳐 봐요.', onSayAgain: () => tapped++),
      );
      await tester.tap(find.text('Say it again'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tapped, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no target, no button', (tester) async {
      await _pumpBody(tester, const ChatCorrectionCard(type: CorrectionCardType.yellow, message: '고쳐 봐요.'));
      expect(find.text('Say it again'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('chat widgets', () {
    testWidgets('praise shows under the reply, and only when there is one', (tester) async {
      await _pumpBody(tester, ChatBubbleWidget(message: ChatMessage(role: 'assistant', content: '네.', praise: '잘했어요.', praiseEn: 'Well done.')));
      expect(_lessonText('잘했어요.'), findsOneWidget);
      expect(_lessonText('Well done.'), findsOneWidget);
      await _pumpBody(tester, ChatBubbleWidget(message: ChatMessage(role: 'assistant', content: '네.')));
      expect(_lessonText('잘했어요.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    Widget panel({List<String> steps = const [], List<int> completed = const [], int? maxTurns = 7}) => ChatMissionPanel(
          mission: _setup().mission,
          userTurn: 1,
          maxTurns: maxTurns,
          steps: steps,
          completedSteps: completed,
        );

    testWidgets('steps: dots when closed, labels when opened', (tester) async {
      await _pumpBody(tester, panel(steps: ['Say hello', 'Say thanks'], completed: [1]));
      expect(_semantics('1 of 2 conversation steps done'), findsOneWidget);
      expect(find.text('Say hello'), findsNothing);
      await tester.tap(find.text('Order a drink'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Say hello'), findsOneWidget);
      expect(find.text('Say thanks'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no steps, nothing shown', (tester) async {
      await _pumpBody(tester, panel());
      expect(_semantics('0 of 0 conversation steps done'), findsNothing);
      expect(find.byType(Wrap), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no turn counter before the server has sent maxTurns', (tester) async {
      await _pumpBody(tester, panel(maxTurns: null));
      expect(find.textContaining('Turn '), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('report comparison', () {
    MissionClearanceModel report(List<IncorrectExpressionModel> fixes) => MissionClearanceModel(
          missionTitle: 'Order',
          persona: '카페 직원',
          totalTurns: 4,
          goodExpressions: const [],
          incorrectExpressions: fixes,
          turtleComment: 'Good.',
          nextPractice: 'More.',
          cleared: true,
        );

    Future<void> toPage3(WidgetTester tester, MissionClearanceModel clearance, Size size) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size, disableAnimations: true),
            child: MissionClearanceScreen(clearance: clearance),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      for (var page = 0; page < 2; page++) {
        await tester.drag(find.byType(PageView), Offset(-size.width, 0));
        await tester.pump(const Duration(milliseconds: 600));
      }
    }

    for (final size in const [Size(390, 844), Size(320, 640)]) {
      testWidgets('shows both sentences at ${size.width.toInt()}w', (tester) async {
        await toPage3(
          tester,
          report([
            IncorrectExpressionModel(
              wrong: '시청역에 가고 싶은데요. 여기서 먼어요?',
              correct: '시청역에 가고 싶은데요. 여기서 멀어요?',
              explanation: "Use the conjugated form of the adjective meaning 'far'.",
            ),
          ]),
          size,
        );
        expect(find.text('YOU SAID'), findsOneWidget);
        expect(find.text('MORE NATURAL'), findsOneWidget);
        expect(find.textContaining('먼', findRichText: true), findsOneWidget);
        expect(find.textContaining('멀', findRichText: true), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('empty list says so', (tester) async {
      await toPage3(tester, report(const []), const Size(390, 844));
      expect(find.text('No corrections needed this time. Nice work!'), findsOneWidget);
      expect(find.text('YOU SAID'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sentences with nothing in common still show', (tester) async {
      await toPage3(
        tester,
        report([IncorrectExpressionModel(wrong: '가', correct: '나', explanation: '')]),
        const Size(390, 844),
      );
      expect(find.text('가'), findsOneWidget);
      expect(find.text('나'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
