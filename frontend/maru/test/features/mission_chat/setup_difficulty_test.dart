import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/mission_chat/models/chat_message_model.dart';
import 'package:maru/features/mission_chat/models/chat_turn_response.dart';
import 'package:maru/features/mission_chat/models/mission_clearance_model.dart';
import 'package:maru/features/mission_chat/models/mission_setup_response.dart';
import 'package:maru/features/mission_chat/models/suggestion_response.dart';
import 'package:maru/features/mission_chat/repositories/mission_chat_repository.dart';
import 'package:maru/features/mission_chat/screens/mission_setup_screen.dart';

// MSN-1.8.4: difficulty picker defaults to Easy and the choice goes into the /setup request.

class _CapturingRepo implements MissionChatRepository {
  Map<String, dynamic>? lastSetupRequest;
  // Never completes, so the screen stays on the loading view (no navigation in the test).
  final _pending = Completer<MissionSetupResponse>();

  @override
  Future<MissionSetupResponse> setupMission(Map<String, dynamic> request) {
    lastSetupRequest = request;
    return _pending.future;
  }

  @override
  Future<ChatTurnResponse> sendChat({required String userMessage, required List<ChatMessage> history, required MissionSetupResponse setup}) =>
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

Future<_CapturingRepo> _pump(WidgetTester tester) async {
  final repo = _CapturingRepo();
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
  await tester.ensureVisible(find.text('Start Mission 🐰'));
  await tester.tap(find.text('Start Mission 🐰'));
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
    await tester.tap(find.text('Hard'));
    await tester.pump();
    await _start(tester);
    expect(repo.lastSetupRequest?['difficulty'], 'hard');
    // Existing fields are still sent unchanged.
    expect(repo.lastSetupRequest?['intimacy'], 'Acquaintance');
    await tester.pumpWidget(const SizedBox());
  });
}
