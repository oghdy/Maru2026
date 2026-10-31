import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson_model.dart';
import '../widgets/lesson_style.dart';
import '../widgets/step_renderer.dart';
import '../../progress/providers/user_progress_provider.dart';
import '../../stats/providers/user_stats_provider.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final LessonModel lesson;

  /// Step to start from (0-based) when resuming an unfinished lesson.
  final int initialStepIndex;

  const LessonScreen({
    super.key,
    required this.lesson,
    this.initialStepIndex = 0,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  ColorScheme get cs => Theme.of(context).colorScheme;

  int currentStepIndex = 0;
  late DateTime _startTime;

  // Graded results per step index: (correct, total) on first attempts
  final Map<int, (int, int)> _stepScores = {};

  void _recordScore(int stepIndex, int correct, int total) {
    if (total > 0) setState(() => _stepScores[stepIndex] = (correct, total));
  }

  static const _gradedExercises = {'fill_blank', 'listening', 'multiple_choice'};

  /// Whether finishing this lesson can produce a score at all. `graded: false` checks don't.
  bool get _hasGradedSteps => widget.lesson.steps.any((step) {
        final content = step.contentObj;
        switch (step.stepType) {
          case 'quiz':
          case 'agglutinative_quiz':
            return true;
          case 'practice':
            if (content['graded'] == false) return false;
            final exercises = content['exercises'] as List<dynamic>? ?? const [];
            return content['quizType'] == 'listen_match' ||
                exercises.any((e) => _gradedExercises.contains((e as Map<String, dynamic>)['type']));
          default:
            return false;
        }
      });

  /// Lesson score = first-attempt accuracy over all graded questions.
  /// Null when the lesson had nothing graded.
  int? get _scorePercent {
    final total = _stepScores.values.fold<int>(0, (sum, s) => sum + s.$2);
    if (total == 0) return null;
    final correct = _stepScores.values.fold<int>(0, (sum, s) => sum + s.$1);
    return (correct * 100 / total).round();
  }

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    currentStepIndex = widget.initialStepIndex.clamp(
      0,
      widget.lesson.steps.isEmpty ? 0 : widget.lesson.steps.length - 1,
    );
  }

  bool _submitted = false;

  /// Leaving mid-lesson: remember the step so the lesson can be resumed from the list.
  void _saveInProgressOnExit() {
    if (_submitted || widget.lesson.steps.isEmpty) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final unitId = widget.lesson.unitId;
    container
        .read(progressServiceProvider)
        .saveInProgress(
          lessonId: widget.lesson.lessonId,
          currentStep: currentStepIndex,
          timeSpentSeconds: DateTime.now().difference(_startTime).inSeconds,
        )
        .then((_) => container.invalidate(unitProgressProvider(unitId)))
        .catchError((e) => debugPrint('Failed to save lesson position: $e'));
  }

  void _goToNextStep() async {
    if (currentStepIndex < widget.lesson.steps.length - 1) {
      setState(() {
        currentStepIndex++;
      });
    } else {
      // Completed the final step in the lesson
      if (_submitted) return;
      _submitted = true;
      final timeSpentSeconds = DateTime.now().difference(_startTime).inSeconds;
      final messenger = ScaffoldMessenger.of(context);

      try {
        await ref
            .read(progressServiceProvider)
            .submitCompletion(
              lessonId: widget.lesson.lessonId,
              // A lesson with nothing to grade counts as 100, however it was reached. After
              // resuming past graded steps with nothing graded since, send no score
              // rather than a made-up 100 (the server keeps the best earlier score).
              score: _scorePercent ?? (_hasGradedSteps && widget.initialStepIndex > 0 ? null : 100),
              timeSpentSeconds: timeSpentSeconds,
              stepCount: widget.lesson.steps.length,
            );
        ref.invalidate(userStatsProvider); // Refresh stats on home screen
        ref.invalidate(
          unitProgressProvider(widget.lesson.unitId),
        ); // Refresh ✓/stars on the lesson list
      } catch (e) {
        debugPrint('Failed to submit progress: $e');
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't save your progress. Please check your connection.",
            ),
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context); // Go back to lesson list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lesson.steps.isEmpty) {
      return Scaffold(
        backgroundColor: missionPageBackground(context),
        appBar: lessonAppBar(context, title: widget.lesson.title),
        body: const Center(child: Text('This lesson has no content steps.')),
      );
    }

    final currentStep = widget.lesson.steps[currentStepIndex];
    final stepCount = widget.lesson.steps.length;
    final stepKey = ValueKey(currentStepIndex);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _saveInProgressOnExit();
      },
      child: Scaffold(
        backgroundColor: missionPageBackground(context),
        appBar: lessonAppBar(
          context,
          title: widget.lesson.title,
          onBack: () => Navigator.pop(context),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Semantics(
                  label: 'Step ${currentStepIndex + 1} of $stepCount',
                  excludeSemantics: true,
                  child: Text(
                    '${currentStepIndex + 1} / $stepCount',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                child: LessonProgressBar(value: (currentStepIndex + 1) / stepCount),
              ),
              // Step header and content change together with a short glide
              Expanded(
                child: AnimatedSwitcher(
                  duration: lessonMotion(context, 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    fit: StackFit.expand,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
                  transitionBuilder: (child, animation) {
                    final incoming = child.key == stepKey;
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(incoming ? 0.05 : -0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: stepKey,
                    children: [
                      // Step title / instruction from the lesson data (completion shows its own)
                      if (currentStep.stepType != 'completion')
                        _StepHeader(title: currentStep.title, instruction: currentStep.instruction),
                      // Dynamic Renderer for the current step
                      Expanded(
                        child: StepRenderer(
                          stepModel: currentStep,
                          onNext: _goToNextStep,
                          onScore: (correct, total) => _recordScore(currentStepIndex, correct, total),
                          scorePercent: _scorePercent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String title;
  final String instruction;

  const _StepHeader({required this.title, required this.instruction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = title.trim();
    final i = instruction.trim();
    if (t.isEmpty && i.isEmpty) return const SizedBox(height: 8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.isNotEmpty)
            LessonText(
              t,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          if (i.isNotEmpty) ...[
            if (t.isNotEmpty) const SizedBox(height: 4),
            LessonText(
              i,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
