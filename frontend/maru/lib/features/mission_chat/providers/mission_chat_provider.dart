import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message_model.dart';
import '../models/mission_clearance_model.dart';
import '../models/suggestion_response.dart';
import '../models/mission_setup_response.dart';
import '../models/chat_turn_response.dart';
import '../repositories/mission_chat_repository.dart';

// failed: the turtle judged the goal was not reached (server missionStatus == 'failed').
// Request errors are not a status: they live in errorMessage/failedAction so the chat stays usable.
enum MissionChatStatus { idle, settingUp, chatting, failed, clearing, cleared }

// Which request failed last, so the UI can offer the right Retry.
enum MissionChatAction { none, setup, clearance }

class MissionChatState {
  final MissionChatStatus status;
  final MissionSetupResponse? setup;
  final List<ChatMessage> messages;
  final MissionClearanceModel? clearance;
  final String? errorMessage;
  final MissionChatAction failedAction;
  final CorrectionModel? immediateCorrection;
  final bool isAwaitingReply;

  MissionChatState({
    this.status = MissionChatStatus.idle,
    this.setup,
    this.messages = const [],
    this.clearance,
    this.errorMessage,
    this.failedAction = MissionChatAction.none,
    this.immediateCorrection,
    this.isAwaitingReply = false,
  });

  bool get isChatOver =>
      status == MissionChatStatus.failed ||
      status == MissionChatStatus.clearing ||
      status == MissionChatStatus.cleared;

  MissionChatState copyWith({
    MissionChatStatus? status,
    MissionSetupResponse? setup,
    List<ChatMessage>? messages,
    MissionClearanceModel? clearance,
    String? errorMessage,
    bool clearError = false,
    MissionChatAction? failedAction,
    CorrectionModel? immediateCorrection,
    bool clearImmediateCorrection = false,
    bool? isAwaitingReply,
  }) {
    return MissionChatState(
      status: status ?? this.status,
      setup: setup ?? this.setup,
      messages: messages ?? this.messages,
      clearance: clearance ?? this.clearance,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failedAction: clearError ? MissionChatAction.none : (failedAction ?? this.failedAction),
      immediateCorrection: clearImmediateCorrection ? null : (immediateCorrection ?? this.immediateCorrection),
      isAwaitingReply: isAwaitingReply ?? this.isAwaitingReply,
    );
  }
}

/// Turns an exception into a short English sentence for learners (never the raw exception).
String missionErrorMessage(Object e) {
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server is taking too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return "Can't reach the server. Check your connection and try again.";
      default:
        break;
    }
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) return 'Your session has expired. Please log in again.';
    if (code != null && code >= 500) return 'The AI partner is not available right now. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}

class MissionChatNotifier extends Notifier<MissionChatState> {
  @override
  MissionChatState build() {
    return MissionChatState();
  }

  MissionChatRepository get _repository => ref.read(missionChatRepositoryProvider);

  Map<String, dynamic>? _lastSetupRequest;

  Future<void> setupMission(Map<String, dynamic> request) async {
    _lastSetupRequest = request;
    state = MissionChatState(status: MissionChatStatus.settingUp);
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
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: MissionChatStatus.idle,
        errorMessage: missionErrorMessage(e),
        failedAction: MissionChatAction.setup,
      );
    }
  }

  Future<void> retrySetup() async {
    final request = _lastSetupRequest;
    if (request != null) await setupMission(request);
  }

  Future<void> sendMessage(String text) async {
    if (state.setup == null || text.trim().isEmpty) return;
    if (state.isAwaitingReply || state.isChatOver) return;

    final userMsg = ChatMessage(role: 'user', content: text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      clearImmediateCorrection: true,
      clearError: true,
      isAwaitingReply: true,
    );

    try {
      // API_CONTRACT 1-2: history includes this turn's userMessage (server dedupes, MSN-1.2.5).
      final response = await _repository.sendChat(
        userMessage: text,
        history: state.messages.where((m) => m.countsAsHistory).toList(),
        setup: state.setup!,
      );

      final isImmediate = response.correction.severity == 'immediate';
      final isSide = response.correction.severity == 'side';

      if (isImmediate) {
        // The turtle stopped this message: keep it on screen, but leave it out of the conversation.
        state = state.copyWith(
          messages: _replaceMessage(userMsg, userMsg.copyWith(isRejected: true)),
          immediateCorrection: response.correction,
          isAwaitingReply: false,
        );
        return;
      }

      var messages = state.messages;
      if (response.rabbitReply != null) {
        messages = [
          ...messages,
          ChatMessage(
            role: 'assistant',
            content: response.rabbitReply!,
            contentEn: response.rabbitReplyEn,
            isTurtleIntervention: isSide,
            turtleFeedback: isSide ? response.correction.turtleFeedback : null,
            turtleFeedbackEn: isSide ? response.correction.turtleFeedbackEn : null,
          ),
        ];
      }
      state = state.copyWith(messages: messages, isAwaitingReply: false);

      // LLM 판정: cleared → 수료증 발급, failed → 목표 미달성 (피드백은 사용자가 요청)
      if (response.missionStatus == 'cleared') {
        issueClearance();
        return;
      }
      if (response.missionStatus == 'failed') {
        state = state.copyWith(status: MissionChatStatus.failed);
        return;
      }

      // 프론트 보조 판정: minTurns + 2턴 초과 시 강제 클리어 트리거
      final setup = state.setup;
      if (setup != null) {
        final userTurnCount = state.messages
            .where((m) => m.role == 'user' && m.countsAsHistory)
            .length;
        final minTurns = setup.mission.minTurns;
        if (userTurnCount >= minTurns + 2) {
          issueClearance();
        }
      }
    } catch (e) {
      state = state.copyWith(
        messages: _replaceMessage(userMsg, userMsg.copyWith(sendFailed: true)),
        errorMessage: missionErrorMessage(e),
        isAwaitingReply: false,
      );
    }
  }

  /// Re-sends a user message that failed to reach the server.
  Future<void> retryMessage(ChatMessage failed) async {
    if (!failed.sendFailed || state.isAwaitingReply) return;
    state = state.copyWith(
      messages: state.messages.where((m) => !identical(m, failed)).toList(),
      clearError: true,
    );
    await sendMessage(failed.content);
  }

  List<ChatMessage> _replaceMessage(ChatMessage oldMsg, ChatMessage newMsg) {
    return state.messages.map((m) => identical(m, oldMsg) ? newMsg : m).toList();
  }

  Future<void> issueClearance() async {
    if (state.setup == null) return;

    final previousStatus = state.status == MissionChatStatus.clearing
        ? MissionChatStatus.chatting
        : state.status;
    state = state.copyWith(status: MissionChatStatus.clearing, clearError: true);
    try {
      final clearanceResponse = await _repository.issueClearance(
        history: state.messages.where((m) => m.countsAsHistory).toList(),
        setup: state.setup!,
      );

      state = state.copyWith(
        status: MissionChatStatus.cleared,
        clearance: clearanceResponse,
      );
      ref.invalidate(clearancesProvider);
    } catch (e) {
      // Stay on the chat screen with a Retry option; the conversation is kept.
      state = state.copyWith(
        status: previousStatus == MissionChatStatus.failed
            ? MissionChatStatus.failed
            : MissionChatStatus.chatting,
        errorMessage: missionErrorMessage(e),
        failedAction: MissionChatAction.clearance,
      );
    }
  }

  void dismissError() {
    state = state.copyWith(clearError: true);
  }

  Future<List<SuggestionDto>?> getSuggestion() async {
    if (state.setup == null) return null;
    try {
      final response = await _repository.getSuggestion(
        history: state.messages.where((m) => m.countsAsHistory).toList(),
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
