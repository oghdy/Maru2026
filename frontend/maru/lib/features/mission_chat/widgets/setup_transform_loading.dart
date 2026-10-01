import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';

/// Mission setup loading view: Tokki, the mischievous rabbit, transforms into the role the
/// learner asked for. The spin, poof and sparkles come from MaruMood.magic itself
/// (CHARACTER_API v1.2 3.3 C7) — this screen only adds the text.
class SetupTransformLoading extends StatefulWidget {
  /// Role typed by the learner (empty = they left it blank).
  final String role;

  const SetupTransformLoading({super.key, required this.role});

  @override
  State<SetupTransformLoading> createState() => _SetupTransformLoadingState();
}

class _SetupTransformLoadingState extends State<SetupTransformLoading> with SingleTickerProviderStateMixin {
  // The status line moves on every cycle.
  static const _cycle = Duration(milliseconds: 2600);
  static const _stepLines = [
    'Waving the magic wand...',
    'Picking the right costume...',
    'Setting up the scene...',
    'Rehearsing some Korean lines...',
    'Almost ready to chat!',
  ];

  late final AnimationController _controller = AnimationController(vsync: this, duration: _cycle);
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _stepIndex = math.min(_stepIndex + 1, _stepLines.length - 1));
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final role = widget.role.trim();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              // Top gap for the jump/spin and room for the poof and sparkles (CHARACTER_API 3.0 rule 4).
              padding: EdgeInsets.only(top: 60, bottom: 24),
              child: MaruCharacter(
                kind: MaruCharacterKind.rabbit,
                mood: MaruMood.magic,
                size: 120,
                semanticLabel: 'Tokki the rabbit transforming',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MAGIC IN PROGRESS',
              style: text.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Tokki is transforming into\n'),
                  if (role.isEmpty)
                    const TextSpan(text: 'your conversation partner')
                  else
                    TextSpan(text: '“$role”', style: TextStyle(color: colors.primary)),
                  const TextSpan(text: '...'),
                ],
              ),
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: colors.primaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _stepLines[_stepIndex],
                key: ValueKey(_stepIndex),
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your mission and partner are being created. This takes a few seconds.',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
