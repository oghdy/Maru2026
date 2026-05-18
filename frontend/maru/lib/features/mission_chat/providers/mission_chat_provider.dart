import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message_model.dart';
import '../models/mission_clearance_model.dart';
import '../models/suggestion_response.dart';
import '../models/mission_setup_response.dart';
import '../models/chat_turn_response.dart';
import '../repositories/mission_chat_repository.dart';

enum MissionChatStatus { idle, settingUp, chatting, clearing, cleared, error }

class MissionChatState {
  final MissionChatStatus status;
  final MissionSetupResponse? setup;
  final List<ChatMessage> messages;
  final MissionClearanceModel? clearance;
  final String? errorMessage;
  final CorrectionModel? immediateCorrection;

  MissionChatState({
    this.status = MissionChatStatus.idle,
    this.setup,
    this.messages = const [],
    this.clearance,
    this.errorMessage,
    this.immediateCorrection,
  });

  MissionChatState copyWith({
    MissionChatStatus? status,
    MissionSetupResponse? setup,
    List<ChatMessage>? messages,
    MissionClearanceModel? clearance,
    String? errorMessage,
    CorrectionModel? immediateCorrection,
    bool clearImmediateCorrection = false,
  }) {
    return MissionChatState(
      status: status ?? this.status,
      setup: setup ?? this.setup,
      messages: messages ?? this.messages,
      clearance: clearance ?? this.clearance,
      errorMessage: errorMessage ?? this.errorMessage,
      immediateCorrection: clearImmediateCorrection ? null : (immediateCorrection ?? this.immediateCorrection),
    );
  }
}

class MissionChatNotifier extends Notifier<MissionChatState> {
  @override
  MissionChatState build() {
    return MissionChatState();
  }

  MissionChatRepository get _repository => ref.read(missionChatRepositoryProvider);

  Future<void> setupMission(Map<String, dynamic> request) async {
    state = state.copyWith(status: MissionChatStatus.settingUp);
    try {
      final setupResponse = await _repository.setupMission(request);
      
      final messages = [
        ChatMessage(
          role: 'assistant',
          content: setupResponse.persona.firstMessage,
          contentEn: setupResponse.persona.firstMessageEn,
        )
      ];

      state = state.copyWith(
        status: MissionChatStatus.chatting,
        setup: setupResponse,
        messages: messages,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: MissionChatStatus.error,
        errorMessage: 'Failed to setup mission: $e',
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (state.setup == null || text.trim().isEmpty) return;

    final userMsg = ChatMessage(role: 'user', content: text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      clearImmediateCorrection: true,
    );

    try {
      final response = await _repository.sendChat(
        userMessage: text,
        history: state.messages.where((m) => m.role != 'system').toList(),
        setup: state.setup!,
      );

      final isImmediate = response.correction.severity == 'immediate';
      final isSide = response.correction.severity == 'side';

      if (isImmediate) {
        state = state.copyWith(
          immediateCorrection: response.correction,
        );
      } else {
        if (response.rabbitReply != null) {
          final assistMsg = ChatMessage(
            role: 'assistant',
            content: response.rabbitReply!,
            contentEn: response.rabbitReplyEn,
            isTurtleIntervention: isSide,
            turtleFeedback: isSide ? response.correction.turtleFeedback : null,
            turtleFeedbackEn: isSide ? response.correction.turtleFeedbackEn : null,
          );
          state = state.copyWith(
            messages: [...state.messages, assistMsg],
          );
        }

        // LLM 판정: cleared 반환 시 즉시 클리어
        if (response.missionStatus == 'cleared') {
          issueClearance();
          return;
        }

        // 프론트 보조 판정: minTurns + 2턴 초과 시 강제 클리어 트리거
        final setup = state.setup;
        if (setup != null) {
          final userTurnCount = state.messages
              .where((m) => m.role == 'user')
              .length;
          final minTurns = setup.mission.minTurns;
          if (userTurnCount >= minTurns + 2) {
            issueClearance();
          }
        }
      }
    } catch (e) {
      state = state.copyWith(
        status: MissionChatStatus.error,
        errorMessage: 'Failed to send message: $e',
      );
    }
  }

  Future<void> issueClearance() async {
    if (state.setup == null) return;
    
    state = state.copyWith(status: MissionChatStatus.clearing);
    try {
      final clearanceResponse = await _repository.issueClearance(
        history: state.messages,
        setup: state.setup!,
      );

      state = state.copyWith(
        status: MissionChatStatus.cleared,
        clearance: clearanceResponse,
      );
    } catch (e) {
      state = state.copyWith(
        status: MissionChatStatus.error,
        errorMessage: 'Failed to issue clearance: $e',
      );
    }
  }

  Future<List<SuggestionDto>?> getSuggestion() async {
    if (state.setup == null) return null;
    try {
      final response = await _repository.getSuggestion(
        history: state.messages.where((m) => m.role != 'system').toList(),
        setup: state.setup!,
      );
      return response.suggestions;
    } catch (e) {
      // Return null or handle error silently since it's just a bottom sheet
      return null;
    }
  }

  void reset() {
    state = MissionChatState();
  }
}

final missionChatProvider = NotifierProvider<MissionChatNotifier, MissionChatState>(() {
  return MissionChatNotifier();
});

final clearancesProvider = FutureProvider<List<MissionClearanceModel>>((ref) async {
  final repository = ref.read(missionChatRepositoryProvider);
  return await repository.getClearances();
});
