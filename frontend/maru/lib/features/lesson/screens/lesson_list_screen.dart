import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../models/lesson_model.dart';
import '../providers/lesson_provider.dart';
import '../widgets/lesson_style.dart';
import '../../progress/models/user_progress_model.dart';
import '../../progress/providers/user_progress_provider.dart';
import '../../vocabulary/widgets/vocab_style.dart' show FadeSlideIn;
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
    final reduceMotion = lessonReduceMotion(context);

    return Scaffold(
      backgroundColor: missionPageBackground(context),
      appBar: lessonAppBar(context, title: 'Unit $unitId Lessons'),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.sad, size: 96),
                const SizedBox(height: 16),
                const Text(
                  "Couldn't load the lessons",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
                  icon: const Icon(Icons.refresh_rounded),
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
                    const MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.idle, size: 96),
                    const SizedBox(height: 12),
                    const Text('Coming soon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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

          // The lesson to do next = the first one not completed (a marker, not a lock)
          final nextIndex = lessons.indexWhere((l) => progress[l.lessonId]?.status != 'completed');

          return RefreshIndicator(
            onRefresh: () {
              ref.invalidate(unitProgressProvider(unitId));
              return ref.refresh(unitLessonsProvider(unitId).future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: lessons.length + 1,
              itemBuilder: (context, index) {
                final Widget child;
                if (index == 0) {
                  child = _UnitHeader(unitId: unitId, lessons: lessons, progress: progress);
                } else {
                  final lesson = lessons[index - 1];
                  child = _LessonTile(
                    lesson: lesson,
                    record: progress[lesson.lessonId],
                    isNext: index - 1 == nextIndex,
                  );
                }
                return reduceMotion ? child : FadeSlideIn(index: index, child: child);
              },
            ),
          );
        },
      ),
    );
  }
}

/// Unit summary: ring + real counts of completed lessons and earned stars.
class _UnitHeader extends StatelessWidget {
  final int unitId;
  final List<LessonModel> lessons;
  final Map<String, UserProgressResponseModel> progress;

  const _UnitHeader({required this.unitId, required this.lessons, required this.progress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = lessons.where((l) => progress[l.lessonId]?.status == 'completed').toList();
    final stars = completed.fold<int>(0, (sum, l) => sum + progress[l.lessonId]!.starsEarned);
    final allDone = completed.length == lessons.length;
    final title = lessons.first.unitTitle.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: missionCardDecoration(context),
      child: Row(
        children: [
          LessonRing(
            size: 68,
            strokeWidth: 6,
            value: completed.length / lessons.length,
            color: allDone ? lessonSuccess() : colorScheme.primary,
            trackColor: allDone ? lessonSuccessSoft() : colorScheme.primaryContainer,
            child: allDone
                ? Icon(Icons.check_rounded, color: lessonSuccess(), size: 32)
                : Text(
                    '${completed.length}/${lessons.length}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.primary),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LessonOverline('Unit $unitId'),
                const SizedBox(height: 3),
                if (title.isNotEmpty)
                  LessonText(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  '${completed.length} of ${lessons.length} lessons complete',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
                if (stars > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: lessonStar()),
                      const SizedBox(width: 3),
                      Text(
                        '$stars / ${lessons.length * 3} stars',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final LessonModel lesson;
  final UserProgressResponseModel? record;
  final bool isNext;

  const _LessonTile({required this.lesson, required this.record, required this.isNext});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = record;
    final completed = r?.status == 'completed';
    final inProgress = r != null && !completed;
    final stepCount = lesson.steps.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LessonPressable(
        onTap: () => _openLesson(context, lesson, r),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: missionCardDecoration(
            context,
            // Always a border, so the highlighted tile keeps the same inner layout
            borderColor: isNext ? colorScheme.primary.withValues(alpha: 0.55) : Colors.transparent,
          ),
          child: Row(
            children: [
              LessonRing(
                value: completed ? 1 : (inProgress && stepCount > 0 ? r.currentStep / stepCount : 0),
                color: completed ? lessonSuccess() : colorScheme.primary,
                trackColor: completed ? lessonSuccessSoft() : colorScheme.primaryContainer,
                child: completed
                    ? Icon(Icons.check_rounded, color: lessonSuccess())
                    : Text(
                        '${lesson.orderNum}',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.primary),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LessonText(lesson.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 3),
                    LessonText(
                      lesson.description,
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.35),
                    ),
                    if (completed || inProgress || isNext) ...[
                      const SizedBox(height: 7),
                      _StatusLine(record: r, isNext: isNext, stepCount: stepCount),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stars for completed lessons; a pill for the one to continue or start next.
class _StatusLine extends StatelessWidget {
  final UserProgressResponseModel? record;
  final bool isNext;
  final int stepCount;

  const _StatusLine({required this.record, required this.isNext, required this.stepCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = record;
    if (r != null && r.status == 'completed') return LessonStars(earned: r.starsEarned);

    final String label;
    if (r != null) {
      final atStep = r.currentStep + 1;
      final where = (r.currentStep > 0 && atStep <= stepCount) ? ' · step $atStep of $stepCount' : '';
      label = '${isNext ? 'Continue' : 'In progress'}$where';
    } else {
      label = 'Up next';
    }
    return MissionPill(label: label, background: colorScheme.primaryContainer, foreground: colorScheme.primary);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(missionCardRadius)),
        title: const Text('Continue where you left off?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
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
