import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../providers/mission_chat_provider.dart';
import '../widgets/chat_bubble_widget.dart';
import '../widgets/typing_bubble_widget.dart';
import '../widgets/suggestion_sheet.dart';
import 'mission_clearance_screen.dart';
import 'mission_setup_screen.dart';
import '../models/chat_message_model.dart';

class MissionChatScreen extends ConsumerStatefulWidget {
  const MissionChatScreen({super.key});

  @override
  ConsumerState<MissionChatScreen> createState() => _MissionChatScreenState();
}

class _MissionChatScreenState extends ConsumerState<MissionChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await ref.read(missionChatProvider.notifier).sendMessage(text);
  }

  void _retryMessage(ChatMessage message) {
    ref.read(missionChatProvider.notifier).retryMessage(message);
  }

  void _showSuggestionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SuggestionSheet(
        load: ref.read(missionChatProvider.notifier).getSuggestion,
        onPick: (suggestion) {
          _textController.text = suggestion.korean;
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Widget _buildErrorBanner(MissionChatState state) {
    final colors = Theme.of(context).colorScheme;
    final notifier = ref.read(missionChatProvider.notifier);
    final isClearance = state.failedAction == MissionChatAction.clearance;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isClearance
                  ? "Couldn't create your feedback report. ${state.errorMessage}"
                  : state.errorMessage!,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          if (isClearance)
            TextButton(
              onPressed: notifier.issueClearance,
              child: const Text('Retry'),
            )
          else
            IconButton(
              icon: Icon(Icons.close, color: colors.onErrorContainer),
              tooltip: 'Dismiss',
              onPressed: notifier.dismissError,
            ),
        ],
      ),
    );
  }

  Widget _buildFailedBanner() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.sad, size: 40, interactive: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission not completed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "The goal wasn't reached this time. See your feedback, then try again!",
                      style: TextStyle(color: colors.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(missionChatProvider.notifier).reset();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MissionSetupScreen()),
                    );
                  },
                  child: const Text('New Mission'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: ref.read(missionChatProvider.notifier).issueClearance,
                  child: const Text('See Feedback'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Learner-facing name for the turtle's issueType code (API_CONTRACT 1-2).
  String _issueLabel(String issueType) {
    return switch (issueType) {
      'honorific_mismatch' => '(Politeness level)',
      'grammar_error' => '(Grammar)',
      'vocabulary' => '(Word choice)',
      'pragmatic' => '(Sounds unnatural here)',
      'off_topic' => '(Off topic)',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionChatProvider);
    final colors = Theme.of(context).colorScheme;

    // Listen for cleared status to navigate to clearance screen
    ref.listen<MissionChatState>(missionChatProvider, (previous, next) {
      // Banners and bubbles change the list height; keep the latest message in view.
      if (previous?.messages.length != next.messages.length ||
          previous?.isAwaitingReply != next.isAwaitingReply ||
          previous?.status != next.status ||
          previous?.errorMessage != next.errorMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
      if (next.status == MissionChatStatus.cleared &&
          previous?.status != MissionChatStatus.cleared &&
          next.clearance != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MissionClearanceScreen(clearance: next.clearance!, fromChat: true)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Chat'),
        elevation: 1,
      ),
      body: Column(
        children: [
          // 1. Top Mission Card
          if (state.setup != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: colors.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Mission: ${state.setup!.mission.title}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (state.maxTurns != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Turn ${state.userTurn}/${state.maxTurns}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(state.setup!.mission.description),
                  const SizedBox(height: 4),
                  Text(
                    'Goal: ${state.setup!.mission.clearCondition.goalCondition}',
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          // 2. Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: state.messages.length + (state.isAwaitingReply ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.messages.length) return const TypingBubbleWidget();
                final msg = state.messages[index];
                if (msg.role == 'system') return const SizedBox.shrink();
                return ChatBubbleWidget(
                  message: msg,
                  onRetry: msg.sendFailed && !state.isAwaitingReply ? () => _retryMessage(msg) : null,
                );
              },
            ),
          ),

          // Request error (send / certificate) with Retry
          if (state.errorMessage != null) _buildErrorBanner(state),

          // Mission not completed (turtle judged the goal was not reached)
          if (state.status == MissionChatStatus.failed) _buildFailedBanner(),

          // Mission Clear Banner
          if (state.status == MissionChatStatus.clearing)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      switch (state.missionStatus) {
                        'cleared' => 'Goal reached! Preparing your feedback...',
                        'failed' => 'Mission not completed. Preparing your feedback...',
                        _ => 'Preparing your feedback...',
                      },
                      style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          else if (state.status == MissionChatStatus.cleared)
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => MissionClearanceScreen(clearance: state.clearance!, fromChat: true)),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📋', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feedback ready!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tap to view your result →',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Immediate Correction Feedback
          if (state.immediateCorrection != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // New correction object each time -> the turtle reacts again (CHARACTER_API 3.3 C4).
                  MaruCharacter(
                    kind: MaruCharacterKind.turtle,
                    mood: MaruMood.thinking,
                    size: 48,
                    reactionKey: state.immediateCorrection,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wait a second! ${_issueLabel(state.immediateCorrection!.issueType)}',
                          style: TextStyle(color: colors.onErrorContainer, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.immediateCorrection!.turtleFeedbackEn ?? 
                          state.immediateCorrection!.turtleFeedback ?? 
                          'Try saying it differently.',
                          style: TextStyle(color: colors.onErrorContainer),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 3. Bottom Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -2), blurRadius: 4),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!state.isChatOver)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: state.isAwaitingReply ? null : _showSuggestionBottomSheet,
                        icon: const Text('🐢', style: TextStyle(fontSize: 18)),
                        label: Text('Help me Turtle', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Reply in Korean...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !state.isAwaitingReply && !state.isChatOver,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (state.isAwaitingReply || state.status == MissionChatStatus.clearing)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: colors.primary,
                      onPressed: state.isChatOver ? null : _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}
