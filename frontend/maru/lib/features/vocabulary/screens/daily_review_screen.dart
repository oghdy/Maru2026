import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/vocabulary_error_view.dart';
import '../widgets/vocabulary_session_pager.dart';

class DailyReviewScreen extends ConsumerStatefulWidget {
  const DailyReviewScreen({super.key});

  @override
  ConsumerState<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends ConsumerState<DailyReviewScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 오늘 복습할 단어 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vocabularySessionProvider.notifier).loadDailyReviewWords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(vocabularySessionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Daily Review'),
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
      final nothingDue = session.words.isEmpty;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                nothingDue ? Icons.done_all : Icons.celebration,
                size: 80,
                color: nothingDue ? Colors.green : Colors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                nothingDue ? 'Nothing to review right now' : 'All Caught Up!',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                nothingDue
                    ? 'Words come back here when they are due.'
                    : 'You reviewed ${session.words.length} due ${session.words.length == 1 ? 'word' : 'words'}.',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  // 홈 화면의 배너 카운트 갱신을 위해 무효화
                  ref.invalidate(dailyReviewCountProvider);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Return Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return VocabularySessionPager(words: session.words);
  }
}
