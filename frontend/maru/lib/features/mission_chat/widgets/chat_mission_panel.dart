import 'package:flutter/material.dart';
import '../models/mission_difficulty.dart';
import '../models/mission_setup_response.dart';
import 'mission_difficulty_badge.dart';

/// Mission card at the top of the chat (MSN-1.7.5). Collapsed by default so the chat has room:
/// title + Turn n/max + one-line goal. Tap to see the full scenario and goal.
class ChatMissionPanel extends StatefulWidget {
  final Mission mission;
  final int userTurn;
  final int? maxTurns;
  // MSN-1.8.5: shown next to the MISSION label. null = server didn't send one.
  final MissionDifficulty? difficulty;

  const ChatMissionPanel({
    super.key,
    required this.mission,
    required this.userTurn,
    this.maxTurns,
    this.difficulty,
  });

  @override
  State<ChatMissionPanel> createState() => _ChatMissionPanelState();
}

class _ChatMissionPanelState extends State<ChatMissionPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mission = widget.mission;
    final maxTurns = widget.maxTurns;
    final goal = mission.clearCondition.goalCondition;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.flag_rounded, size: 18, color: colors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'MISSION',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: colors.primary,
                                  ),
                                ),
                                if (widget.difficulty != null) ...[
                                  const SizedBox(width: 6),
                                  MissionDifficultyBadge(difficulty: widget.difficulty!),
                                ],
                              ],
                            ),
                            Text(
                              mission.title,
                              maxLines: _expanded ? 3 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.25),
                            ),
                          ],
                        ),
                      ),
                      if (maxTurns != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Turn ${widget.userTurn}/$maxTurns',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (maxTurns != null && maxTurns > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (widget.userTurn / maxTurns).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: colors.primaryContainer,
                        color: colors.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (_expanded) ...[
                    Text(
                      mission.description,
                      style: TextStyle(fontSize: 14, height: 1.45, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(Icons.track_changes_rounded, size: 16, color: colors.primary),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Goal  ', style: TextStyle(fontWeight: FontWeight.w800)),
                              TextSpan(text: goal),
                            ],
                          ),
                          maxLines: _expanded ? null : 1,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, height: 1.4, color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
