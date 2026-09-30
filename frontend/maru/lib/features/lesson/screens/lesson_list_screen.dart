import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson_model.dart';
import '../providers/lesson_provider.dart';
import '../../progress/models/user_progress_model.dart';
import '../../progress/providers/user_progress_provider.dart';
import 'lesson_screen.dart';

class LessonListScreen extends ConsumerWidget {
  final int unitId; // E.g., 1

  const LessonListScreen({super.key, required this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    // 1. Fetch lessons from backend using Riverpod
    final lessonsAsync = ref.watch(unitLessonsProvider(unitId));
    // Progress marks are secondary: if they fail to load the list still works
    final progress = ref.watch(unitProgressProvider(unitId)).asData?.value ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Unit $unitId Lessons', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, color: colorScheme.error, size: 64),
                const SizedBox(height: 16),
                const Text(
                  "Couldn't load the lessons",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(unitLessonsProvider(unitId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (lessons) {
          if (lessons.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_clock, color: colorScheme.outline, size: 56),
                    const SizedBox(height: 12),
                    const Text('Coming soon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Lessons for this unit are being prepared.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              ref.invalidate(unitProgressProvider(unitId));
              return ref.refresh(unitLessonsProvider(unitId).future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outlineVariant, width: 2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        '${lesson.orderNum}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                    title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(lesson.description, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                    ),
                    trailing: _ProgressBadge(record: progress[lesson.lessonId]),
                    onTap: () => _openLesson(context, lesson, progress[lesson.lessonId]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Opens a lesson; an unfinished one can be resumed from the step where the learner left.
Future<void> _openLesson(BuildContext context, LessonModel lesson, UserProgressResponseModel? record) async {
  var startStep = 0;
  final saved = record?.currentStep ?? 0;
  if (record != null && record.status == 'in_progress' && saved > 0 && saved < lesson.steps.length) {
    final resume = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Continue where you left off?'),
        content: Text('You stopped at step ${saved + 1} of ${lesson.steps.length}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Start over')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );
    if (resume == null) return; // dismissed
    if (resume) startStep = saved;
  }
  if (!context.mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson, initialStepIndex: startStep)),
  );
}

/// ✓ + earned stars for completed lessons, "In progress" for started ones.
class _ProgressBadge extends StatelessWidget {
  final UserProgressResponseModel? record;

  const _ProgressBadge({required this.record});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = record;
    if (r == null) return Icon(Icons.chevron_right, color: colorScheme.outline);

    if (r.status == 'completed') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 22),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Icon(
                i < r.starsEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: i < r.starsEarned ? Colors.amber.shade600 : colorScheme.outlineVariant,
              ),
            ),
          ),
        ],
      );
    }
    return Text(
      'In progress',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
    );
  }
}
