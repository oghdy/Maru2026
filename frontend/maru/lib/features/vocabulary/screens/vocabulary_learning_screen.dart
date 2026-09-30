import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/session_summary_view.dart';
import '../widgets/vocabulary_error_view.dart';
import '../widgets/vocabulary_session_pager.dart';

class VocabularyLearningScreen extends ConsumerStatefulWidget {
  final String deckTitle;

  const VocabularyLearningScreen({super.key, required this.deckTitle});

  @override
  ConsumerState<VocabularyLearningScreen> createState() => _VocabularyLearningScreenState();
}

class _VocabularyLearningScreenState extends ConsumerState<VocabularyLearningScreen> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vocabularySessionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(widget.deckTitle),
        // 투명이면 상태바 아이콘 색 추정이 틀려서(흰색) 배경과 같은 단색을 준다
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!session.isLoading && !session.isCompleted && session.words.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${session.currentIndex + 1} / ${session.words.length}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary),
                ),
              ),
            ),
        ],
        bottom: (!session.isLoading && !session.isCompleted && session.words.isNotEmpty)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: (session.currentIndex + 1) / session.words.length),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: _buildBody(session),
    );
  }

  Widget _buildBody(VocabularySessionState session) {
    if (session.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (session.errorMessage != null) {
      return VocabularyErrorView(
        message: session.errorMessage!,
        onRetry: () => ref.read(vocabularySessionProvider.notifier).retry(),
      );
    }

    if (session.isCompleted) {
      final empty = session.words.isEmpty;
      return SessionSummaryView(
        icon: empty ? Icons.inbox_rounded : Icons.emoji_events_rounded,
        iconColor: empty ? Theme.of(context).colorScheme.outline : Colors.amber.shade700,
        title: empty ? 'No words in this lesson' : 'Lesson Completed!',
        message: empty
            ? 'Try another lesson.'
            : 'You went through all ${session.words.length} words.\nWords you rated will come back in Daily Review.',
        ratingCounts: session.ratingCounts,
        buttonLabel: 'Back to Lessons',
        onPressed: () => Navigator.pop(context),
      );
    }

    return VocabularySessionPager(words: session.words);
  }
}
