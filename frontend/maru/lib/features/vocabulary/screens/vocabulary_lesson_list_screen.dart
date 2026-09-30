import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word_category.dart';
import '../models/word_lesson.dart';
import '../providers/vocabulary_provider.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          category.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildError(ref),
        data: (lessons) {
          if (lessons.isEmpty) {
            return const Center(
              child: Text(
                'No lessons in this deck yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(vocabularyLessonsProvider(category.id).future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) => _buildLessonCard(context, ref, lessons[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Couldn't load the lessons.\nPlease check your connection and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(vocabularyLessonsProvider(category.id)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, WidgetRef ref, WordLesson lesson) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = lesson.totalWords == 0 ? 0.0 : lesson.studiedWords / lesson.totalWords;

    final Widget trailing;
    if (lesson.isCompleted) {
      trailing = const Icon(Icons.check_circle, color: Colors.green);
    } else if (lesson.isInProgress) {
      trailing = Text(
        '${lesson.studiedWords}/${lesson.totalWords}',
        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
      );
    } else {
      trailing = const Icon(Icons.arrow_forward_ios, size: 16);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: lesson.isCompleted
            ? Border.all(color: Colors.green.withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            '${lesson.lessonNumber}',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Lesson ${lesson.lessonNumber}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lesson.isCompleted
                  ? 'All ${lesson.totalWords} words studied'
                  : lesson.isInProgress
                      ? '${lesson.studiedWords} of ${lesson.totalWords} words studied'
                      : '${lesson.totalWords} words',
            ),
            if (lesson.isInProgress) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ],
        ),
        trailing: trailing,
        onTap: () => _showModeSheet(context, ref, lesson),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lesson ${lesson.lessonNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(sheetContext).colorScheme.primary,
                  child: Icon(Icons.menu_book, color: Theme.of(sheetContext).colorScheme.onPrimary),
                ),
                title: const Text('Word Study', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Learn words with flashcards'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.extension, color: Colors.white),
                ),
                title: const Text('Match Madness', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Test your knowledge with 4x4 game'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
