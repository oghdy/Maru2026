import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';

/// Rabbit bubble with animated dots, shown while waiting for the partner's reply.
class TypingBubbleWidget extends StatefulWidget {
  const TypingBubbleWidget({super.key});

  @override
  State<TypingBubbleWidget> createState() => _TypingBubbleWidgetState();
}

class _TypingBubbleWidgetState extends State<TypingBubbleWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Your partner is typing',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.thinking, size: 40, interactive: false),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(color: colors.primary.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      // Each dot pulses a third of a cycle after the previous one.
                      final t = (_controller.value - i / 3) % 1.0;
                      final opacity = t < 0.5 ? 0.3 + 1.4 * t : 1.0 - 1.4 * (t - 0.5);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: opacity.clamp(0.3, 1.0)),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
