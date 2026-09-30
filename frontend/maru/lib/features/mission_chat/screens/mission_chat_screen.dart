import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mission_chat_provider.dart';
import '../widgets/chat_bubble_widget.dart';
import '../widgets/typing_bubble_widget.dart';
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
    final future = ref.read(missionChatProvider.notifier).sendMessage(text);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    await future;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _retryMessage(ChatMessage message) async {
    await ref.read(missionChatProvider.notifier).retryMessage(message);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _showSuggestionBottomSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const SizedBox(
          height: 250,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );

    final suggestions = await ref.read(missionChatProvider.notifier).getSuggestion();

    if (!mounted) return;
    Navigator.pop(context); // close loading sheet

    if (suggestions == null || suggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get suggestions. Please try again.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🐢 Turtle\'s Suggestions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...suggestions.map((suggestion) {
                return InkWell(
                  onTap: () {
                    _textController.text = suggestion.korean;
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.korean,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestion.english,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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
              const Text('🐢', style: TextStyle(fontSize: 28)),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionChatProvider);

    // Listen for cleared status to navigate to clearance screen
    ref.listen<MissionChatState>(missionChatProvider, (previous, next) {
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 1. Top Mission Card
          if (state.setup != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.teal.shade50,
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
                    style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w500),
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
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      switch (state.missionStatus) {
                        'cleared' => 'Goal reached! Preparing your feedback...',
                        'failed' => 'Mission not completed. Preparing your feedback...',
                        _ => 'Preparing your feedback...',
                      },
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Text('🐢', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wait a second! (${state.immediateCorrection!.issueType})',
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.immediateCorrection!.turtleFeedbackEn ?? 
                          state.immediateCorrection!.turtleFeedback ?? 
                          'Try saying it differently.',
                          style: TextStyle(color: Colors.red.shade800),
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
              color: Colors.white,
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
                        label: const Text('Help me Turtle', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
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
                        fillColor: Colors.grey.shade100,
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
                      icon: const Icon(Icons.send, color: Colors.teal),
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
