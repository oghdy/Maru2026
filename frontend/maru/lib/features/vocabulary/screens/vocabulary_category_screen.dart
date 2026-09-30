import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word_category.dart';
import '../providers/vocabulary_provider.dart';
import '../repository/vocabulary_errors.dart';
import '../widgets/vocab_style.dart';
import '../widgets/vocabulary_error_view.dart';
import 'vocabulary_lesson_list_screen.dart';

class VocabularyCategoryScreen extends ConsumerWidget {
  const VocabularyCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Vocabulary', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ref.watch(vocabularyCategoriesProvider('Beginner')).when(
            data: (categories) => _buildContent(context, ref, categories),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => VocabularyErrorView(
              message: friendlyVocabularyError(err),
              onRetry: () => ref.invalidate(vocabularyCategoriesProvider('Beginner')),
            ),
          ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<WordCategory> categories) {
    final totalWords = categories.fold<int>(0, (sum, c) => sum + c.totalWords);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          sliver: SliverToBoxAdapter(
            child: FadeSlideIn(child: _Header(deckCount: categories.length, totalWords: totalWords)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 176,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => FadeSlideIn(
                index: index,
                child: _DeckCard(category: categories[index]),
              ),
              childCount: categories.length,
            ),
          ),
        ),
      ],
    );
  }
}

String _thousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

class _Header extends StatelessWidget {
  final int deckCount;
  final int totalWords;

  const _Header({required this.deckCount, required this.totalWords});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, Color.lerp(colorScheme.primary, colorScheme.tertiary, 0.55)!],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build your Korean vocabulary',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$deckCount topic decks · ${_thousands(totalWords)} words\nFlashcards + spaced review, 30 words per lesson',
                  style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.85), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '가',
                style: TextStyle(color: colorScheme.onPrimary, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckCard extends ConsumerWidget {
  final WordCategory category;

  const _DeckCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final visual = DeckVisual.of(context, category.koreanTitle);
    // 덱 진행률 = 레슨별 studiedWords 합 (레슨 목록 화면과 같은 provider 라 들어가면 캐시 재사용)
    final lessons = ref.watch(vocabularyLessonsProvider(category.id)).value;
    final studied = lessons?.fold<int>(0, (sum, l) => sum + l.studiedWords);
    final progress = (studied == null || category.totalWords == 0) ? null : studied / category.totalWords;

    return PressableScale(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VocabularyLessonListScreen(category: category)),
        ).then((_) {
          if (context.mounted) ref.invalidate(vocabularyLessonsProvider(category.id));
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: visual.accent.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: visual.accentSoft, borderRadius: BorderRadius.circular(14)),
                  child: Icon(visual.icon, color: visual.accent, size: 24),
                ),
                const Spacer(),
                if (progress != null && progress >= 1)
                  Icon(Icons.check_circle_rounded, color: visual.accent, size: 22),
              ],
            ),
            const Spacer(),
            Text(
              category.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${category.koreanTitle} · ${category.totalWords} words',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress ?? 0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  color: visual.accent,
                  backgroundColor: visual.accentSoft,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              studied == null ? ' ' : '$studied / ${category.totalWords} studied',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
