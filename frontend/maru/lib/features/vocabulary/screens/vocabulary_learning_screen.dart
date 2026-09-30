import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vocabulary_provider.dart';
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
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                session.words.isEmpty ? 'No words in this lesson' : 'Lesson Completed!',
                style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (session.words.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'You went through all ${session.words.length} words.\nWords you rated will come back in Daily Review.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Back to Lessons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return VocabularySessionPager(words: session.words);
  }
}
