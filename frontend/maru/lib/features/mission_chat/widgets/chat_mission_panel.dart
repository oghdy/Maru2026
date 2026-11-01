import 'package:flutter/material.dart';
import '../models/mission_difficulty.dart';
import '../models/mission_setup_response.dart';
import 'mission_difficulty_badge.dart';

/// Mission card at the top of the chat (MSN-1.7.5). Collapsed by default so the chat has room:
/// title + Turn n/max + one-line goal. Tap to see the full scenario and goal.
/// While the keyboard is up it closes itself and shows only the title line, so the messages stay in view.
class ChatMissionPanel extends StatefulWidget {
  final Mission mission;
  final int userTurn;
  final int? maxTurns;
  // MSN-1.8.5: shown next to the MISSION label. null = server didn't send one.
  final MissionDifficulty? difficulty;
  // Conversation guide, not a checklist to clear: dots when closed, small chips when opened.
  final List<String> steps;
  final List<int> completedSteps;
  // Whether the on-screen keyboard is up. The parent knows: a Scaffold body sees no keyboard inset.
  final bool keyboardOpen;
  // The opened panel scrolls past this height, so it can't push the reply box away.
  final double maxContentHeight;

  const ChatMissionPanel({
    super.key,
    required this.mission,
    required this.userTurn,
    this.maxTurns,
    this.difficulty,
    this.steps = const [],
    this.completedSteps = const [],
    this.keyboardOpen = false,
    this.maxContentHeight = double.infinity,
  });

  @override
  State<ChatMissionPanel> createState() => _ChatMissionPanelState();
}

class _ChatMissionPanelState extends State<ChatMissionPanel> {
  bool _expanded = false;

  @override
  void didUpdateWidget(ChatMissionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only when it opens: the learner can still open the panel again while typing.
    if (widget.keyboardOpen && !oldWidget.keyboardOpen) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mission = widget.mission;
    final maxTurns = widget.maxTurns;
    final goal = mission.clearCondition.goalCondition;
    final titleOnly = widget.keyboardOpen && !_expanded;

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
            padding: EdgeInsets.fromLTRB(16, titleOnly ? 8 : 12, 12, titleOnly ? 8 : 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxContentHeight),
              child: SingleChildScrollView(
                primary: false,
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
                  if (!titleOnly) ...[
                  // Empty until the first reply brings maxTurns, so the panel doesn't jump.
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: maxTurns != null && maxTurns > 0 ? (widget.userTurn / maxTurns).clamp(0.0, 1.0) : 0,
                      minHeight: 4,
                      backgroundColor: colors.primaryContainer,
                      color: colors.primary,
                    ),
                  ),
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
                      if (!_expanded && widget.steps.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: _StepDots(count: widget.steps.length, completed: widget.completedSteps),
                        ),
                      ],
                    ],
                  ),
                  if (_expanded && widget.steps.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < widget.steps.length; i++)
                          _StepChip(label: widget.steps[i], done: widget.completedSteps.contains(i + 1)),
                      ],
                    ),
                  ],
                  ],
                ],
              ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int count;
  final List<int> completed;

  const _StepDots({required this.count, required this.completed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final done = [for (var i = 1; i <= count; i++) if (completed.contains(i)) i].length;
    return Semantics(
      label: '$done of $count conversation steps done',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.only(left: i == 1 ? 0 : 4),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed.contains(i) ? colors.primary : colors.primary.withValues(alpha: 0.2),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final bool done;

  const _StepChip({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: done ? colors.primaryContainer : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) ...[
            Icon(Icons.check_rounded, size: 13, color: colors.primary),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: done ? colors.onPrimaryContainer : colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
