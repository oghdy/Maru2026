import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';

/// Grammar Lab loading: the thinking turtle "experiments" with the sentence next to a bubbling flask.
/// [seconds] drives the stage line (cache HIT ≈ instant, a new sentence can take ~10-30s).
class LabExperimentLoading extends StatefulWidget {
  final String task; // e.g. "Exploring tense variations"
  final int seconds;

  const LabExperimentLoading({super.key, required this.task, required this.seconds});

  /// Stage line for the elapsed time. Public for tests.
  static String stageFor(int seconds) {
    if (seconds < 3) return 'Mixing grammar…';
    if (seconds < 7) return 'Adding a pinch of politeness…';
    if (seconds < 12) return 'Stirring the sentence endings…';
    return 'Almost done! New sentences take a little longer.';
  }

  @override
  State<LabExperimentLoading> createState() => _LabExperimentLoadingState();
}

class _LabExperimentLoadingState extends State<LabExperimentLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _bubbles = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion (and widget tests): keep the flask still.
    if (MediaQuery.of(context).disableAnimations) {
      _bubbles.stop();
    } else if (!_bubbles.isAnimating) {
      _bubbles.repeat();
    }
  }

  @override
  void dispose() {
    _bubbles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          SizedBox(
            height: 160, // ≥ 120 + 0.25×120 jump room
            width: 220,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                const Positioned(
                  left: 20,
                  bottom: 0,
                  child: MaruCharacter(
                    kind: MaruCharacterKind.turtle,
                    outfit: MaruOutfit.lab,
                    mood: MaruMood.thinking,
                    size: 120,
                  ),
                ),
                Positioned(right: 8, bottom: 6, child: _flask(cs)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Turtle is experimenting\nwith your sentence…',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(color: cs.primaryContainer, shape: const StadiumBorder()),
            child: Text(widget.task, style: textTheme.labelMedium?.copyWith(color: cs.onPrimaryContainer)),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              LabExperimentLoading.stageFor(widget.seconds),
              key: ValueKey(LabExperimentLoading.stageFor(widget.seconds)),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          if (widget.seconds >= 3) ...[
            const SizedBox(height: 4),
            Text('${widget.seconds}s', style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  /// Flask icon with three bubbles rising out of it (phase-shifted).
  Widget _flask(ColorScheme cs) {
    return SizedBox(
      width: 56,
      height: 96,
      child: AnimatedBuilder(
        animation: _bubbles,
        builder: (context, _) => Stack(
          alignment: Alignment.bottomCenter,
          children: [
            for (var i = 0; i < 3; i++) _bubble(cs, (_bubbles.value + i / 3) % 1.0, i),
            Icon(Icons.science_rounded, size: 52, color: cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ColorScheme cs, double t, int i) {
    final size = 6.0 + i * 3;
    return Positioned(
      bottom: 40 + t * 48,
      left: 22 + math.sin((t + i) * math.pi * 2) * 8,
      child: Opacity(
        opacity: (1 - t).clamp(0.0, 1.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary.withValues(alpha: 0.35)),
        ),
      ),
    );
  }
}
