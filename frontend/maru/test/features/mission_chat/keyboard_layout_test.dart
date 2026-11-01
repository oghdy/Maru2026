import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/core/demo/web_keyboard_insets.dart';
import 'package:maru/features/mission_chat/models/chat_message_model.dart';
import 'package:maru/features/mission_chat/models/chat_turn_response.dart';
import 'package:maru/features/mission_chat/models/mission_clearance_model.dart';
import 'package:maru/features/mission_chat/models/mission_scenario.dart';
import 'package:maru/features/mission_chat/models/mission_setup_response.dart';
import 'package:maru/features/mission_chat/models/suggestion_response.dart';
import 'package:maru/features/mission_chat/providers/mission_chat_provider.dart';
import 'package:maru/features/mission_chat/repositories/mission_chat_repository.dart';
import 'package:maru/features/mission_chat/screens/mission_chat_screen.dart';
import 'package:maru/features/mission_chat/widgets/chat_correction_card.dart';
import 'package:maru/features/mission_chat/widgets/chat_mission_panel.dart';

// WEB-5.17.6: with the keyboard up the reply box stays visible and the messages get the room.

const _description = 'You are at a small cafe and the worker loves to talk.';
const _goal = 'Order one drink.';

MissionSetupResponse _setup() => MissionSetupResponse.fromJson({
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
        'description': _description,
        'clearCondition': {'goalCondition': _goal, 'languageCondition': 'Use -요.'},
        'minTurns': 4,
      },
      'adjustmentNotice': null,
      'difficulty': 'easy',
      'steps': ['Greet', 'Order', 'Say thanks'],
      'learnerSpeechLevel': '존댓말',
      'scenarioId': 'cafe',
    });

ChatTurnResponse _redCard() => ChatTurnResponse.fromJson({
      'rabbitReply': null,
      'rabbitReplyEn': null,
      'correction': {
        'severity': 'immediate',
        'issueType': 'grammar_error',
        'correctExpression': '커피 주세요.',
        'turtleFeedback': '이렇게 말해 봐요.',
        'turtleFeedbackEn': 'Try saying it like this.',
      },
      'missionStatus': 'in_progress',
      'userTurn': 1,
      'minTurns': 4,
      'maxTurns': 7,
      'zone': 'A',
    });

class _FakeRepo implements MissionChatRepository {
  @override
  Future<MissionSetupResponse> setupMission(Map<String, dynamic> request) async => _setup();
  @override
  Future<ChatTurnResponse> sendChat({
    required String userMessage,
    required List<ChatMessage> history,
    required MissionSetupResponse setup,
    List<int> completedSteps = const [],
  }) async =>
      _redCard();
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

void _setKeyboard(WidgetTester tester, Size page, double keyboard) {
  tester.view.physicalSize = page * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
}

Future<ProviderContainer> _pumpChat(WidgetTester tester, Size page) async {
  _setKeyboard(tester, page, 0);
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [missionChatRepositoryProvider.overrideWithValue(_FakeRepo())]);
  addTearDown(container.dispose);
  await container.read(missionChatProvider.notifier).setupMission({'scenarioId': 'cafe', 'difficulty': 'easy'});
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: MissionChatScreen()),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('mission panel and the keyboard', () {
    Widget panel({required bool keyboardOpen}) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ChatMissionPanel(
                  mission: _setup().mission,
                  userTurn: 1,
                  maxTurns: 7,
                  steps: const ['Greet'],
                  keyboardOpen: keyboardOpen,
                ),
              ],
            ),
          ),
        );

    testWidgets('closes when the keyboard opens and can be opened again', (tester) async {
      await tester.pumpWidget(panel(keyboardOpen: false));
      await tester.tap(find.byType(ChatMissionPanel));
      await _settle(tester);
      expect(find.text(_description), findsOneWidget);

      await tester.pumpWidget(panel(keyboardOpen: true));
      await _settle(tester);
      expect(find.text(_description), findsNothing);
      expect(find.text('Order a drink'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing, reason: 'title line only while typing');

      // Opened by hand while typing: a rebuild doesn't close it again.
      await tester.tap(find.byType(ChatMissionPanel));
      await _settle(tester);
      expect(find.text(_description), findsOneWidget);
      await tester.pumpWidget(panel(keyboardOpen: true));
      await _settle(tester);
      expect(find.text(_description), findsOneWidget);

      // Keyboard closed: nothing changes on its own.
      await tester.pumpWidget(panel(keyboardOpen: false));
      await _settle(tester);
      expect(find.text(_description), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('stays closed by default on first entry', (tester) async {
      await tester.pumpWidget(panel(keyboardOpen: false));
      await _settle(tester);
      expect(find.text(_description), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('WebKeyboardInsets', () {
    Future<double> insetUnder(WidgetTester tester, {required Size page, required double keyboard, double bar = 58}) async {
      _setKeyboard(tester, page, keyboard);
      addTearDown(tester.view.reset);
      late double seen;
      await tester.pumpWidget(MaterialApp(
        home: WebKeyboardInsets(
          barHeight: bar,
          child: Builder(builder: (context) {
            seen = MediaQuery.viewInsetsOf(context).bottom;
            return const SizedBox();
          }),
        ),
      ));
      return seen;
    }

    testWidgets('adds the bar only with the keyboard up, in portrait, in a browser that needs it', (tester) async {
      expect(await insetUnder(tester, page: const Size(402, 760), keyboard: 307), 365);
      expect(await insetUnder(tester, page: const Size(402, 760), keyboard: 0), 0);
      expect(await insetUnder(tester, page: const Size(402, 760), keyboard: 40), 40);
      expect(await insetUnder(tester, page: const Size(800, 360), keyboard: 200), 200);
      expect(await insetUnder(tester, page: const Size(402, 760), keyboard: 307, bar: 0), 307);
    });

    testWidgets('outside the iPhone browser check the test build has no bar', (tester) async {
      _setKeyboard(tester, const Size(402, 760), 307);
      addTearDown(tester.view.reset);
      late double seen;
      await tester.pumpWidget(MaterialApp(
        home: WebKeyboardInsets(
          child: Builder(builder: (context) {
            seen = MediaQuery.viewInsetsOf(context).bottom;
            return const SizedBox();
          }),
        ),
      ));
      expect(seen, 307);
    });
  });

  group('chat screen with the keyboard up', () {
    // Page height is what a phone browser leaves under its address bar; keyboard includes the iOS 26 bar.
    const pages = {
      'iPhone 17 Safari': (page: Size(402, 760), keyboard: 365.0),
      'iPhone SE Safari': (page: Size(375, 553), keyboard: 318.0),
    };

    for (final entry in pages.entries) {
      testWidgets('${entry.key}: reply box above the keyboard, red card reachable', (tester) async {
        final page = entry.value.page;
        final keyboard = entry.value.keyboard;
        final container = await _pumpChat(tester, page);

        await tester.tap(find.byType(ChatMissionPanel));
        await _settle(tester);
        await tester.enterText(find.byType(TextField), 'wrong');
        _setKeyboard(tester, page, keyboard);
        await _settle(tester);

        final fieldBottom = tester.getBottomLeft(find.byType(TextField)).dy;
        expect(fieldBottom, lessThanOrEqualTo(page.height - keyboard));
        expect(find.text(_description), findsNothing);
        expect(tester.takeException(), isNull);

        await container.read(missionChatProvider.notifier).sendMessage('wrong');
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(tester.getBottomLeft(find.byType(TextField)).dy, lessThanOrEqualTo(page.height - keyboard));
        // The list scrolled to its last item, the card, without covering the reply box.
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(ChatCorrectionCard), findsOneWidget);
      });
    }

    testWidgets('a browser toolbar inset does not close the panel', (tester) async {
      await _pumpChat(tester, const Size(402, 760));
      await tester.tap(find.byType(ChatMissionPanel));
      await _settle(tester);
      _setKeyboard(tester, const Size(402, 760), 40);
      await _settle(tester);
      expect(find.text(_description), findsOneWidget);
    });

    testWidgets('a panel opened while typing can\'t push the reply box away', (tester) async {
      const page = Size(402, 760);
      await _pumpChat(tester, page);
      _setKeyboard(tester, page, 365);
      await _settle(tester);
      await tester.tap(find.byType(ChatMissionPanel));
      await _settle(tester);
      expect(find.text(_description), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.getBottomLeft(find.byType(TextField)).dy, lessThanOrEqualTo(page.height - 365));
    });

    testWidgets('the latest message comes into view when the keyboard opens', (tester) async {
      final container = await _pumpChat(tester, const Size(402, 760));
      for (var i = 0; i < 6; i++) {
        await container.read(missionChatProvider.notifier).sendMessage('message $i');
        await _settle(tester);
      }
      await tester.tap(find.byType(TextField));
      await tester.pump();
      _setKeyboard(tester, const Size(402, 760), 365);
      await _settle(tester);
      final list = tester.widget<ListView>(find.byType(ListView));
      final position = list.controller!.position;
      expect(position.pixels, closeTo(position.maxScrollExtent, 1));
    });
  });
}
