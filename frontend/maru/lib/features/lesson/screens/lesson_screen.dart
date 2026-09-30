import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson_model.dart';
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
              // Nothing graded in a full run (reading-only lesson) counts as 100. After
          // resuming past graded steps with nothing graded since, send no score
          // rather than a made-up 100 (the server keeps the best earlier score).
          score: _scorePercent ?? (widget.initialStepIndex > 0 ? null : 100),
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
        appBar: AppBar(title: Text(widget.lesson.title)),
        body: const Center(child: Text('This lesson has no content steps.')),
      );
    }

    final currentStep = widget.lesson.steps[currentStepIndex];

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _saveInProgressOnExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.lesson.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: cs.primary, // Vibrant purple
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Section (Figma style)
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${currentStepIndex + 1}/${widget.lesson.steps.length}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${((currentStepIndex + 1) / widget.lesson.steps.length * 100).toInt()}%',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:
                            (currentStepIndex + 1) / widget.lesson.steps.length,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              // Step title / instruction from the lesson data (completion shows its own)
              if (currentStep.stepType != 'completion')
                _StepHeader(
                  key: ValueKey('header_$currentStepIndex'),
                  title: currentStep.title,
                  instruction: currentStep.instruction,
                ),

              // Dynamic Renderer for the current step
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  // Keep step content top-aligned under the header (default centers it)
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
                  child: StepRenderer(
                    key: ValueKey(currentStepIndex),
                    stepModel: currentStep,
                    onNext: _goToNextStep,
                    onScore: (correct, total) =>
                        _recordScore(currentStepIndex, correct, total),
                    scorePercent: _scorePercent,
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

  const _StepHeader({
    super.key,
    required this.title,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = title.trim();
    final i = instruction.trim();
    if (t.isEmpty && i.isEmpty) return const SizedBox(height: 8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.isNotEmpty)
            Text(
              t,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          if (i.isNotEmpty) ...[
            if (t.isNotEmpty) const SizedBox(height: 4),
            Text(
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
