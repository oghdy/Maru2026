import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson_model.dart';
import '../widgets/step_renderer.dart';
import '../../progress/providers/user_progress_provider.dart';
import '../../stats/providers/user_stats_provider.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final LessonModel lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  int currentStepIndex = 0;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  void _goToNextStep() async {
    if (currentStepIndex < widget.lesson.steps.length - 1) {
      setState(() {
        currentStepIndex++;
      });
    } else {
      // Completed the final step in the lesson
      final timeSpentSeconds = DateTime.now().difference(_startTime).inSeconds;
      
      try {
        await ref.read(progressServiceProvider).submitCompletion(
          lessonId: widget.lesson.lessonId,
          score: 100, // Assuming full score for now
          timeSpentSeconds: timeSpentSeconds,
        );
        ref.invalidate(userStatsProvider); // Refresh stats on home screen
      } catch (e) {
        debugPrint('Failed to submit progress: $e');
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

    return Scaffold(
      backgroundColor: Colors.white, // Match the Figma background
      appBar: AppBar(
        title: Text(widget.lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF6B4EFF), // Vibrant purple
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
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
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
                        style: const TextStyle(
                          color: Color(0xFF6B4EFF),
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
                      value: (currentStepIndex + 1) / widget.lesson.steps.length,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
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
                  children: [...previousChildren, if (currentChild != null) currentChild],
                ),
                child: StepRenderer(
                  key: ValueKey(currentStepIndex),
                  stepModel: currentStep,
                  onNext: _goToNextStep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String title;
  final String instruction;

  const _StepHeader({super.key, required this.title, required this.instruction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = title.trim();
    final i = instruction.trim();
    if (t.isEmpty && i.isEmpty) return const SizedBox(height: 8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.isNotEmpty)
            Text(
              t,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
            ),
          if (i.isNotEmpty) ...[
            if (t.isNotEmpty) const SizedBox(height: 4),
            Text(
              i,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, height: 1.4, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
