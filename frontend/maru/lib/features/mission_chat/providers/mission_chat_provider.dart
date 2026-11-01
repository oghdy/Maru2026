import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/demo/demo_mode.dart';
import '../models/chat_message_model.dart';
import '../models/korean_text.dart';
import '../models/mission_clearance_model.dart';
import '../models/mission_scenario.dart';
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
  // Last missionStatus from /chat: in_progress | cleared | failed.
  final String? missionStatus;
  // Server turn counter (API_CONTRACT 1-7 A). userTurn counts accepted user messages.
  final int userTurn;
  // From the server only: null until the first /chat reply.
  final int? maxTurns;
  // Conversation guide steps done so far (web-demo API_CONTRACT 7.3); sent back with each /chat.
  final List<int> completedSteps;
  // Web demo only: the visitor's allowance is used up, so Retry would not help. The screen offers a way out.
  final bool limitReached;

  MissionChatState({
    this.status = MissionChatStatus.idle,
    this.setup,
    this.messages = const [],
    this.clearance,
    this.errorMessage,
    this.failedAction = MissionChatAction.none,
    this.immediateCorrection,
    this.isAwaitingReply = false,
    this.missionStatus,
    this.userTurn = 0,
    this.maxTurns,
    this.completedSteps = const [],
    this.limitReached = false,
  });

  bool get isChatOver =>
      missionStatus == 'cleared' ||
      missionStatus == 'failed' ||
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
    String? missionStatus,
    int? userTurn,
    int? maxTurns,
    List<int>? completedSteps,
    bool? limitReached,
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
      missionStatus: missionStatus ?? this.missionStatus,
      userTurn: userTurn ?? this.userTurn,
      maxTurns: maxTurns ?? this.maxTurns,
      completedSteps: completedSteps ?? this.completedSteps,
      limitReached: clearError ? false : (limitReached ?? this.limitReached),
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
    if (code == 401 || code == 403) {
      return kDemoMode
          ? 'Your guest session ended. Please reload the page.'
          : 'Your session has expired. Please log in again.';
    }
    // API_CONTRACT 1-6: error bodies carry a learner-facing English `message`.
    final data = e.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
      return data['message'] as String;
    }
    if (code != null && code >= 500) return 'Something went wrong on our side. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}

/// Web demo: the server answered 429 (a demo limit), so asking again will not help.
bool isDemoLimitError(Object e) => kDemoMode && e is DioException && e.response?.statusCode == 429;

/// Web demo: the server stopped the request on purpose (limit, busy, AI paused) and its message says why.
bool _isDemoNotice(Object e) {
  if (!kDemoMode || e is! DioException) return false;
  final code = e.response?.statusCode;
  return code == 429 || code == 503;
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
        limitReached: isDemoLimitError(e),
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
        completedSteps: state.completedSteps,
      );

      final isImmediate = response.correction.severity == 'immediate';
      final isSide = response.correction.severity == 'side';

      if (isImmediate) {
        // The turtle stopped this message: keep it on screen, but leave it out of the conversation.
        // Its completedSteps are ignored too: that line never happened.
        state = state.copyWith(
          messages: _replaceMessage(userMsg, userMsg.copyWith(isRejected: true)),
          immediateCorrection: response.correction,
          isAwaitingReply: false,
        );
        return;
      }

      final corrected = response.correction.correctExpression;
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
            turtleIssueType: isSide ? response.correction.issueType : null,
            // Nothing to practise when the "fix" only differs by spaces or punctuation.
            sayAgainTarget: isSide && corrected != null && !isSameSentence(corrected, text) ? corrected : null,
            praise: response.praise,
            praiseEn: response.praiseEn,
          ),
        ];
      }
      state = state.copyWith(
        messages: messages,
        isAwaitingReply: false,
        missionStatus: response.missionStatus,
        userTurn: response.userTurn ??
            state.messages.where((m) => m.role == 'user' && m.countsAsHistory).length,
        maxTurns: response.maxTurns,
        completedSteps: response.completedSteps,
      );

      // 서버 3-Zone 판정(API_CONTRACT 1-7): cleared/failed 면 대화 종료 → 수료증(피드백은 항상) 발급.
      // 서버가 maxTurns 안에 반드시 끝내므로 FE 강제 발급 로직은 없음.
      if (response.missionStatus == 'cleared' || response.missionStatus == 'failed') {
        if (response.missionStatus == 'failed') {
          state = state.copyWith(status: MissionChatStatus.failed);
        }
        issueClearance();
      }
    } catch (e) {
      state = state.copyWith(
        messages: _replaceMessage(userMsg, userMsg.copyWith(sendFailed: true)),
        errorMessage: missionErrorMessage(e),
        isAwaitingReply: false,
        limitReached: isDemoLimitError(e),
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
      final status = state.missionStatus;
      final clearanceResponse = await _repository.issueClearance(
        history: state.messages.where((m) => m.countsAsHistory).toList(),
        setup: state.setup!,
        missionStatus: status == 'cleared' || status == 'failed' ? status : null,
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
        limitReached: isDemoLimitError(e),
      );
    }
  }

  void dismissError() {
    state = state.copyWith(clearError: true);
  }

  /// Web demo: why the last hint request was refused, for the hint sheet. Null otherwise.
  String? suggestionNotice;

  Future<List<SuggestionDto>?> getSuggestion() async {
    if (state.setup == null) return null;
    suggestionNotice = null;
    try {
      final response = await _repository.getSuggestion(
        history: state.messages.where((m) => m.countsAsHistory).toList(),
        setup: state.setup!,
      );
      return response.suggestions;
    } catch (e) {
      // Return null or handle error silently since it's just a bottom sheet
      if (_isDemoNotice(e)) suggestionNotice = missionErrorMessage(e);
      return null;
    }
  }

  /// Starts the same mission over (same persona and goal) after a not-cleared result.
  void retrySameMission() {
    final setup = state.setup;
    if (setup == null) return;
    state = MissionChatState(
      status: MissionChatStatus.chatting,
      setup: setup,
      messages: [
        ChatMessage(
          role: 'assistant',
          content: setup.persona.firstMessage,
          contentEn: setup.persona.firstMessageEn,
        ),
      ],
      maxTurns: state.maxTurns,
    );
  }

  void reset() {
    state = MissionChatState();
  }
}

final missionChatProvider = NotifierProvider<MissionChatNotifier, MissionChatState>(() {
  return MissionChatNotifier();
});

// No automatic retry: the setup screen shows the failure with its own Retry, and free input keeps working.
final missionScenariosProvider = FutureProvider<List<MissionScenario>>((ref) async {
  return await ref.read(missionChatRepositoryProvider).getScenarios();
}, retry: (retryCount, error) => null);

// No automatic retry: the list screen shows the error with its own Retry button right away.
final clearancesProvider = FutureProvider<List<MissionClearanceModel>>((ref) async {
  final repository = ref.read(missionChatRepositoryProvider);
  return await repository.getClearances();
}, retry: (retryCount, error) => null);
