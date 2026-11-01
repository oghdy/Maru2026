import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/mission_chat/models/chat_message_model.dart';
import 'package:maru/features/mission_chat/models/chat_turn_response.dart';
import 'package:maru/features/mission_chat/models/mission_clearance_model.dart';
import 'package:maru/features/mission_chat/models/mission_scenario.dart';
import 'package:maru/features/mission_chat/models/mission_setup_response.dart';
import 'package:maru/features/mission_chat/models/suggestion_response.dart';
import 'package:maru/features/mission_chat/repositories/mission_chat_repository.dart';
import 'package:maru/features/mission_chat/screens/mission_setup_screen.dart';

// MSN-1.8.4: difficulty picker defaults to Easy and the choice goes into the /setup request.
// WEB-5.17.4: all three levels show, scenario cards are a shortcut, free input survives their failure.

const _roommate = MissionScenario(
  id: 'roommate',
  icon: 'roommate',
  title: 'The Roommate Problem',
  description: 'Your neat roommate has a complaint.',
  roleEn: 'Roommate',
  personalityEn: 'A neat, nagging softie',
);

class _CapturingRepo implements MissionChatRepository {
  Map<String, dynamic>? lastSetupRequest;
  // Never completes, so the screen stays on the loading view (no navigation in the test).
  final _pending = Completer<MissionSetupResponse>();
  Object? scenariosError;
  int scenarioLoads = 0;

  @override
  Future<List<MissionScenario>> getScenarios() async {
    scenarioLoads++;
    if (scenariosError != null) throw scenariosError!;
    return const [_roommate];
  }

  @override
  Future<MissionSetupResponse> setupMission(Map<String, dynamic> request) {
    lastSetupRequest = request;
    return _pending.future;
  }

  @override
  Future<ChatTurnResponse> sendChat({required String userMessage, required List<ChatMessage> history, required MissionSetupResponse setup, List<int> completedSteps = const []}) =>
      throw UnimplementedError();
  @override
  Future<MissionClearanceModel> issueClearance({required List<ChatMessage> history, required MissionSetupResponse setup, String? missionStatus}) =>
      throw UnimplementedError();
  @override
  Future<List<MissionClearanceModel>> getClearances() => throw UnimplementedError();
  @override
  Future<SuggestionResponse> getSuggestion({required List<ChatMessage> history, required MissionSetupResponse setup}) =>
      throw UnimplementedError();
}

Future<_CapturingRepo> _pump(WidgetTester tester, {Object? scenariosError}) async {
  final repo = _CapturingRepo()..scenariosError = scenariosError;
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [missionChatRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(
      home: MediaQuery(data: MediaQueryData(size: Size(393, 852), disableAnimations: true), child: MissionSetupScreen()),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  return repo;
}

Future<void> _start(WidgetTester tester) async {
  await _tapVisible(tester, 'Start Mission 🐰');
}

Future<void> _tapVisible(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  testWidgets('defaults to easy', (tester) async {
    final repo = await _pump(tester);
    expect(find.text('How hard should it be?'), findsOneWidget);
    await _start(tester);
    expect(repo.lastSetupRequest?['difficulty'], 'easy');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sends the picked difficulty', (tester) async {
    final repo = await _pump(tester);
    await _tapVisible(tester, 'Hard');
    await _start(tester);
    expect(repo.lastSetupRequest?['difficulty'], 'hard');
    // Existing fields are still sent unchanged.
    expect(repo.lastSetupRequest?['intimacy'], 'Acquaintance');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('all three levels are offered', (tester) async {
    await _pump(tester);
    for (final label in ['Easy', 'Normal', 'Hard']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a scenario card starts with only its id and the picked level', (tester) async {
    final repo = await _pump(tester);
    await _tapVisible(tester, 'Normal');
    await _tapVisible(tester, 'The Roommate Problem');
    expect(repo.lastSetupRequest, {'scenarioId': 'roommate', 'difficulty': 'normal'});
    // No transform animation for an instant start: the form stays up.
    expect(find.text('Make your own situation'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('free input still works when the cards fail to load', (tester) async {
    final repo = await _pump(tester, scenariosError: Exception('boom'));
    expect(find.text('The Roommate Problem'), findsNothing);
    expect(find.textContaining("Couldn't load these"), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
    await _tapVisible(tester, 'Retry');
    await tester.pump(const Duration(milliseconds: 50));
    expect(repo.scenarioLoads, 2);

    await _tapVisible(tester, 'Professor');
    await _start(tester);
    expect(repo.lastSetupRequest?['role'], 'Professor');
    expect(repo.lastSetupRequest?.containsKey('scenarioId'), isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
