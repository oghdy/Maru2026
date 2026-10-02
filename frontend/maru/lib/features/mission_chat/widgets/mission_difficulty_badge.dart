import 'package:flutter/material.dart';

import '../models/mission_difficulty.dart';

/// Small stadium badge, e.g. "🌱 Easy". Used on the chat mission panel and the report (MSN-1.8.5).
class MissionDifficultyBadge extends StatelessWidget {
  final MissionDifficulty difficulty;

  const MissionDifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Difficulty: ${difficulty.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: ShapeDecoration(color: colors.primaryContainer, shape: const StadiumBorder()),
        child: Text(
          '${difficulty.emoji} ${difficulty.label}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.onPrimaryContainer),
        ),
      ),
    );
  }
}
