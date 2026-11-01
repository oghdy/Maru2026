import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

// Replies when the test says so, to look at the screen while one is on its way.
class _WaitingRepo extends _FakeRepo {
  final List<Completer<ChatTurnResponse>> pending = [];
  final List<String> sent = [];

  @override
  Future<ChatTurnResponse> sendChat({
    required String userMessage,
    required List<ChatMessage> history,
    required MissionSetupResponse setup,
    List<int> completedSteps = const [],
  }) {
    sent.add(userMessage);
    final reply = Completer<ChatTurnResponse>();
    pending.add(reply);
    return reply.future;
  }

  // Stays on "Preparing your feedback...", the screen right after a mission ends.
  @override
  Future<MissionClearanceModel> issueClearance({required List<ChatMessage> history, required MissionSetupResponse setup, String? missionStatus}) =>
      Completer<MissionClearanceModel>().future;
}

ChatTurnResponse _reply({String status = 'in_progress', int userTurn = 1}) => ChatTurnResponse.fromJson({
      'rabbitReply': '네, 알겠어요.',
      'rabbitReplyEn': 'Okay.',
      'correction': {'severity': 'none', 'issueType': 'none'},
      'missionStatus': status,
      'userTurn': userTurn,
      'minTurns': 4,
      'maxTurns': 7,
      'zone': 'A',
    });

void _setKeyboard(WidgetTester tester, Size page, double keyboard) {
  tester.view.physicalSize = page * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
}

Future<ProviderContainer> _pumpChat(WidgetTester tester, Size page, {MissionChatRepository? repo}) async {
  _setKeyboard(tester, page, 0);
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [missionChatRepositoryProvider.overrideWithValue(repo ?? _FakeRepo())]);
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

  group('chat screen with the keyboard up', () {
    // Page height is what a phone browser leaves under its address bar; the keyboard inset includes the
    // iOS 26 bar because visualViewport ends above it (measured, LOG WEB-5.17.7).
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

    testWidgets('typing layout: thin panel, no subtitle, small turtle button, field right above the inset', (tester) async {
      const page = Size(402, 714);
      const keyboard = 337.0;
      await _pumpChat(tester, page);
      expect(find.text('Help me Turtle'), findsOneWidget);
      expect(find.text('Tokki as 카페 직원'), findsOneWidget);
      final normalBar = tester.getSize(find.byType(AppBar)).height;

      _setKeyboard(tester, page, keyboard);
      await _settle(tester);

      expect(find.text('Help me Turtle'), findsNothing);
      expect(find.byKey(const ValueKey('compactTurtleHelp')), findsOneWidget);
      expect(find.text('Tokki as 카페 직원'), findsNothing);
      expect(tester.getSize(find.byType(AppBar)).height, lessThan(normalBar));
      expect(tester.getSize(find.byType(ChatMissionPanel)).height, lessThanOrEqualTo(40));

      final bottom = tester.getBottomLeft(find.byType(TextField)).dy;
      expect(page.height - keyboard - bottom, inInclusiveRange(0, 4), reason: 'no spare gap above the keyboard');
      // The messages keep most of what is left.
      expect(tester.getSize(find.byType(ListView)).height, greaterThan(200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the small turtle button opens the same help, and the normal layout comes back', (tester) async {
      const page = Size(402, 714);
      await _pumpChat(tester, page);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      _setKeyboard(tester, page, 337);
      await _settle(tester);
      expect(FocusManager.instance.primaryFocus?.hasPrimaryFocus, isTrue);
      final focusBefore = FocusManager.instance.primaryFocus;

      _setKeyboard(tester, page, 0);
      await _settle(tester);
      expect(find.text('Help me Turtle'), findsOneWidget);
      expect(find.byKey(const ValueKey('compactTurtleHelp')), findsNothing);
      expect(find.text('Tokki as 카페 직원'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, focusBefore, reason: 'the field survives the layout change');

      _setKeyboard(tester, page, 337);
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('compactTurtleHelp')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('a long reply stops growing at three lines and the messages stay', (tester) async {
      const page = Size(402, 714);
      await _pumpChat(tester, page);
      _setKeyboard(tester, page, 337);
      await _settle(tester);
      final oneLine = tester.getSize(find.byType(TextField)).height;
      await tester.enterText(find.byType(TextField), List.filled(40, '안녕하세요').join(' '));
      await _settle(tester);
      final grown = tester.getSize(find.byType(TextField)).height;
      expect(grown, greaterThan(oneLine));
      expect(grown, lessThanOrEqualTo(oneLine + 2 * 26));
      expect(tester.getSize(find.byType(ListView)).height, greaterThan(150));
      expect(tester.takeException(), isNull);
    });
  });

  group('the keyboard stays up between turns', () {
    const page = Size(402, 714);
    const keyboard = 337.0;

    EditableTextState field(WidgetTester tester) => tester.state<EditableTextState>(find.byType(EditableText));
    bool isFocused(WidgetTester tester) => field(tester).widget.focusNode.hasPrimaryFocus;
    bool isEnabled(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).enabled ?? true;

    Future<_WaitingRepo> typing(WidgetTester tester, String text) async {
      final repo = _WaitingRepo();
      await _pumpChat(tester, page, repo: repo);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      _setKeyboard(tester, page, keyboard);
      await _settle(tester);
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      return repo;
    }

    testWidgets('send button: focus stays while waiting and after the reply, the latest message in view', (tester) async {
      final repo = await typing(tester, '커피 주세요');
      // Mouse: outside taps close the keyboard for it here, as touch does in a phone browser (kIsWeb is false in tests).
      await tester.tap(find.byTooltip('Send'), kind: PointerDeviceKind.mouse);
      await _settle(tester);
      expect(repo.sent, ['커피 주세요']);
      expect(field(tester).widget.controller.text, isEmpty);
      expect(isFocused(tester), isTrue);
      expect(isEnabled(tester), isTrue);
      expect(field(tester).widget.readOnly, isFalse, reason: 'read-only also closes a phone keyboard');
      expect(tester.testTextInput.isVisible, isTrue);

      repo.pending.single.complete(_reply());
      await _settle(tester);
      expect(isFocused(tester), isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      final position = tester.widget<ListView>(find.byType(ListView)).controller!.position;
      expect(position.pixels, closeTo(position.maxScrollExtent, 1));
    });

    testWidgets('keyboard send key: same, two turns in a row', (tester) async {
      final repo = await typing(tester, '안녕하세요');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await _settle(tester);
      expect(repo.sent, ['안녕하세요']);
      expect(isFocused(tester), isTrue);
      repo.pending.last.complete(_reply());
      await _settle(tester);

      await tester.enterText(find.byType(TextField), '커피 주세요');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await _settle(tester);
      expect(repo.sent, ['안녕하세요', '커피 주세요']);
      expect(isFocused(tester), isTrue);
      repo.pending.last.complete(_reply(userTurn: 2));
      await _settle(tester);
      expect(isFocused(tester), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('typing during a reply: the send key sends nothing and keeps the text', (tester) async {
      final repo = await typing(tester, '안녕하세요');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await _settle(tester);
      await tester.enterText(find.byType(TextField), '다음 말');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await _settle(tester);
      expect(repo.sent, ['안녕하세요']);
      expect(field(tester).widget.controller.text, '다음 말');

      repo.pending.single.complete(_reply());
      await _settle(tester);
      expect(field(tester).widget.controller.text, '다음 말');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await _settle(tester);
      expect(repo.sent, ['안녕하세요', '다음 말']);
    });

    for (final status in ['cleared', 'failed']) {
      testWidgets('mission $status: the keyboard closes and half-typed text goes', (tester) async {
        final repo = await typing(tester, '감사합니다');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await _settle(tester);
        await tester.enterText(find.byType(TextField), '다음 말');
        repo.pending.single.complete(_reply(status: status, userTurn: 4));
        await tester.pump();
        await tester.pump();
        expect(isFocused(tester), isFalse);
        expect(isEnabled(tester), isFalse);
        expect(tester.testTextInput.isVisible, isFalse);
        expect(field(tester).widget.controller.text, isEmpty);
        await _settle(tester);
      });
    }

    testWidgets('a tap outside still closes the keyboard', (tester) async {
      await typing(tester, '안녕');
      await tester.tapAt(tester.getCenter(find.byType(ListView)), kind: PointerDeviceKind.mouse);
      await _settle(tester);
      expect(isFocused(tester), isFalse);
    });

    testWidgets('red card: Say it again fills the box with the focus kept, and the send goes through', (tester) async {
      final repo = await typing(tester, '커피');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await _settle(tester);
      repo.pending.single.complete(_redCard());
      await _settle(tester);
      expect(isFocused(tester), isTrue);

      await tester.tap(find.text('Say it again'), kind: PointerDeviceKind.mouse);
      await _settle(tester);
      expect(isFocused(tester), isTrue);
      expect(field(tester).widget.controller.text, '커피 주세요.');

      await tester.testTextInput.receiveAction(TextInputAction.send);
      await _settle(tester);
      expect(repo.sent, ['커피', '커피 주세요.']);
      expect(find.byType(ChatCorrectionCard), findsNothing);
    });
  });
}
