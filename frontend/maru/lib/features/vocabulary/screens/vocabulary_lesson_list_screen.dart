import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word_category.dart';
import '../models/word_lesson.dart';
import '../providers/vocabulary_provider.dart';
import '../repository/vocabulary_errors.dart';
import '../widgets/vocab_style.dart';
import '../widgets/vocabulary_error_view.dart';
import 'vocabulary_learning_screen.dart';
import 'vocabulary_game_screen.dart';

class VocabularyLessonListScreen extends ConsumerWidget {
  final WordCategory category;

  const VocabularyLessonListScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(vocabularyLessonsProvider(category.id));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(category.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => VocabularyErrorView(
          message: friendlyVocabularyError(err),
          onRetry: () => ref.invalidate(vocabularyLessonsProvider(category.id)),
        ),
        data: (lessons) {
          if (lessons.isEmpty) {
            return Center(
              child: Text(
                'No lessons in this deck yet.',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
              ),
            );
          }
          // 이어서 할 레슨 = 완료 안 된 첫 레슨
          final nextIndex = lessons.indexWhere((l) => !l.isCompleted);
          final visual = DeckVisual.of(context, category.koreanTitle);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(vocabularyLessonsProvider(category.id).future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: lessons.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FadeSlideIn(child: _DeckHeader(category: category, lessons: lessons));
                }
                final lesson = lessons[index - 1];
                return FadeSlideIn(
                  index: index,
                  child: _LessonTile(
                    lesson: lesson,
                    visual: visual,
                    isNext: index - 1 == nextIndex,
                    onTap: () => _showModeSheet(context, ref, lesson),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showModeSheet(BuildContext context, WidgetRef ref, WordLesson lesson) {
    // 학습/게임에서 돌아오면 완료·진행 표시를 다시 불러온다
    void refreshLessons(_) {
      if (context.mounted) ref.invalidate(vocabularyLessonsProvider(category.id));
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Lesson ${lesson.lessonNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${category.title} · ${lesson.totalWords} words',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                _ModeOption(
                  icon: Icons.style_rounded,
                  color: colorScheme.primary,
                  title: 'Word Study',
                  subtitle: 'Flip flashcards and rate how well you know each word',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref.read(vocabularySessionProvider.notifier).loadDueWords(
                          category.id,
                          lessonNumber: lesson.lessonNumber,
                        );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VocabularyLearningScreen(deckTitle: category.title),
                      ),
                    ).then(refreshLessons);
                  },
                ),
                const SizedBox(height: 12),
                _ModeOption(
                  icon: Icons.extension_rounded,
                  color: gameAccent(sheetContext),
                  title: 'Match Madness',
                  subtitle: 'Match English and Korean, 5 pairs per round',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VocabularyGameScreen(
                          category: category,
                          lessonNumber: lesson.lessonNumber,
                        ),
                      ),
                    ).then(refreshLessons);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeckHeader extends StatelessWidget {
  final WordCategory category;
  final List<WordLesson> lessons;

  const _DeckHeader({required this.category, required this.lessons});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visual = DeckVisual.of(context, category.koreanTitle);
    final studied = lessons.fold<int>(0, (sum, l) => sum + l.studiedWords);
    final completed = lessons.where((l) => l.isCompleted).length;
    final progress = category.totalWords == 0 ? 0.0 : studied / category.totalWords;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: visual.accent.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    color: visual.accent,
                    backgroundColor: visual.accentSoft,
                  ),
                ),
                Center(child: Icon(visual.icon, color: visual.accent, size: 30)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.koreanTitle,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  '$studied of ${category.totalWords} words studied',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  '$completed of ${lessons.length} lessons complete',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final WordLesson lesson;
  final DeckVisual visual;
  final bool isNext;
  final VoidCallback onTap;

  const _LessonTile({required this.lesson, required this.visual, required this.isNext, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = lesson.totalWords == 0 ? 0.0 : lesson.studiedWords / lesson.totalWords;

    final String status;
    if (lesson.isCompleted) {
      status = 'All ${lesson.totalWords} words studied';
    } else if (lesson.isInProgress) {
      status = '${lesson.studiedWords} of ${lesson.totalWords} words studied';
    } else {
      status = '${lesson.totalWords} new words';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isNext ? visual.accent.withValues(alpha: 0.6) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      color: lesson.isCompleted ? Colors.green : visual.accent,
                      backgroundColor: visual.accentSoft,
                    ),
                    Center(
                      child: lesson.isCompleted
                          ? const Icon(Icons.check_rounded, color: Colors.green)
                          : Text(
                              '${lesson.lessonNumber}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: visual.accent, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Lesson ${lesson.lessonNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (isNext) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: visual.accentSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              lesson.isInProgress ? 'Continue' : 'Up next',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: visual.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(status, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: colorScheme.surface, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
