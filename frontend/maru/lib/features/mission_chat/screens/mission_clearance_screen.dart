import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../../lesson/widgets/lesson_style.dart' show LessonText, lessonSuccess, lessonSuccessSoft;
import '../models/mission_clearance_model.dart';
import '../providers/mission_chat_provider.dart';
import '../widgets/clearance_style.dart';
import '../widgets/mission_difficulty_badge.dart';
import 'mission_chat_screen.dart';

class MissionClearanceScreen extends ConsumerStatefulWidget {
  final MissionClearanceModel clearance;
  // true when opened right after a chat (can retry the same mission); false from the list.
  final bool fromChat;

  const MissionClearanceScreen({super.key, required this.clearance, this.fromChat = false});

  @override
  ConsumerState<MissionClearanceScreen> createState() => _MissionClearanceScreenState();
}

class _MissionClearanceScreenState extends ConsumerState<MissionClearanceScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() {
    if (widget.fromChat) {
      ref.read(missionChatProvider.notifier).reset();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _tryAgain() {
    ref.read(missionChatProvider.notifier).retrySameMission();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MissionChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clearance = widget.clearance;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: missionPageBackground(context),
      appBar: AppBar(
        backgroundColor: missionPageBackground(context),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          switch (clearance.cleared) {
            true => 'Mission Cleared! 🎉',
            false => 'Almost there!',
            null => 'Mission Completed',
          },
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        automaticallyImplyLeading: !widget.fromChat,
        actions: [
          if (widget.fromChat)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: _close,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // Computers too: a mouse can't swipe a PageView on the web by default.
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildPage1Summary(clearance),
                  _buildPage2GoodExpressions(clearance),
                  _buildPage3AreasForImprovement(clearance),
                  _buildPage4TutorsNote(clearance),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0, top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final active = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: active ? 22.0 : 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: active ? colors.primary : colors.outlineVariant,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        // Gold frame only for a real clear.
        decoration: missionCardDecoration(
          context,
          borderColor: widget.clearance.cleared == true ? Colors.amber.shade600 : null,
        ),
        child: child,
      ),
    );
  }

  Widget _buildPage1Summary(MissionClearanceModel clearance) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cleared = clearance.cleared;
    final (pillLabel, pillIcon, pillBg, pillFg) = switch (cleared) {
      true => ('Cleared', Icons.workspace_premium, colors.primary, colors.onPrimary),
      false => ('Almost there — one more try!', Icons.trending_up, colors.secondaryContainer, colors.onSecondaryContainer),
      null => ('Completed', Icons.check, colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Result characters (CHARACTER_API 3.3 C5). Top gap leaves room for the jump.
          if (cleared != null) ...[
            const SizedBox(height: 28),
            // Shrinks below 110 on narrow phones so the pair never overflows the card.
            LayoutBuilder(builder: (context, box) {
              final size = ((box.maxWidth - 12) / 2).clamp(72.0, 110.0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: cleared
                    ? [
                        MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.cheer, size: size, entrance: true),
                        const SizedBox(width: 12),
                        MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.happy, size: size, entrance: true),
                      ]
                    // Not cleared: no crying rabbit — Tokki ponders, the turtle cheers you on (MSN-1.7.8).
                    : [
                        MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.thinking, size: size),
                        const SizedBox(width: 12),
                        MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.happy, size: size, entrance: true),
                      ],
              );
            }),
            const SizedBox(height: 16),
          ],
          Text(
            cleared == true ? 'CERTIFICATE OF COMPLETION' : 'MISSION REPORT',
            style: text.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
              color: colors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            clearance.missionTitle,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          if (cleared == false) ...[
            const SizedBox(height: 8),
            Text(
              "You're so close! Check the turtle's tips and give it another go.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              MissionPill(label: pillLabel, icon: pillIcon, background: pillBg, foreground: pillFg),
              if (clearance.difficulty != null) MissionDifficultyBadge(difficulty: clearance.difficulty!),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                if (clearance.goalCondition != null && clearance.goalCondition!.isNotEmpty)
                  _buildInfoRow(Icons.flag_rounded, 'Goal', clearance.goalCondition!),
                _buildInfoRow(Icons.theater_comedy_rounded, 'Partner', clearance.persona),
                _buildInfoRow(Icons.forum_rounded, 'Turns',
                    '${clearance.totalTurns} ${clearance.totalTurns == 1 ? 'turn' : 'turns'}'),
              ],
            ),
          ),
          if (clearance.resultReason != null && clearance.resultReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cleared == true ? colors.primaryContainer : colors.secondaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.idle, size: 40, interactive: false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      clearance.resultReason!,
                      style: TextStyle(
                        height: 1.35,
                        color: cleared == true
                            ? colors.onPrimaryContainer
                            : colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Swipe to see your feedback',
                  style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage2GoodExpressions(MissionClearanceModel clearance) {
    final colors = Theme.of(context).colorScheme;
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MissionSectionHeader(
            title: 'Great Expressions',
            emoji: '✨',
            color: colors.primary,
            count: clearance.goodExpressions.isEmpty ? null : clearance.goodExpressions.length,
          ),
          const SizedBox(height: 20),
          if (clearance.goodExpressions.isEmpty)
            _buildEmptyNote('No expressions to highlight this time.')
          else
            ...clearance.goodExpressions.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('“${e.expression}”',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.35)),
                  const SizedBox(height: 6),
                  Text(e.reason, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14, height: 1.35)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPage3AreasForImprovement(MissionClearanceModel clearance) {
    final colors = Theme.of(context).colorScheme;
    final comparisons =
        clearance.incorrectExpressions.where((e) => e.wrong.isNotEmpty && e.correct.isNotEmpty).toList();
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MissionSectionHeader(
            title: 'Say It More Naturally',
            emoji: '📝',
            color: colors.tertiary,
            count: comparisons.isEmpty ? null : comparisons.length,
          ),
          const SizedBox(height: 20),
          if (comparisons.isEmpty)
            _buildEmptyNote('No corrections needed this time. Nice work!')
          else
            ...comparisons.map((e) => _buildComparison(e)),
        ],
      ),
    );
  }

  // Your sentence next to the more natural one, with the part that changed marked in each.
  Widget _buildComparison(IncorrectExpressionModel e) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildComparisonLabel('YOU SAID', colors.onSurfaceVariant),
          const SizedBox(height: 3),
          _ChangedText(
            text: e.wrong,
            other: e.correct,
            style: TextStyle(color: colors.onSurface, fontSize: 15.5, height: 1.4),
            mark: TextStyle(backgroundColor: colors.errorContainer, color: colors.onErrorContainer),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(Icons.arrow_downward_rounded, size: 18, color: colors.outline),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(color: lessonSuccessSoft(), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildComparisonLabel('MORE NATURAL', lessonSuccess()),
                const SizedBox(height: 3),
                _ChangedText(
                  text: e.correct,
                  other: e.wrong,
                  style: TextStyle(color: colors.onSurface, fontSize: 16, height: 1.4, fontWeight: FontWeight.w700),
                  mark: TextStyle(color: lessonSuccess(), fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (e.explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            LessonText(e.explanation, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14, height: 1.35)),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
    );
  }

  Widget _buildEmptyNote(String message) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message, style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPage4TutorsNote(MissionClearanceModel clearance) {
    final colors = Theme.of(context).colorScheme;
    final canRetry = widget.fromChat &&
        clearance.cleared == false &&
        ref.read(missionChatProvider).setup != null;
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MissionSectionHeader(title: "Tutor's Note", icon: Icons.school_rounded, color: colors.primary),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.idle, size: 40, interactive: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(clearance.turtleComment,
                      style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15, height: 1.4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: missionHeroGradient(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag_rounded, color: colors.onPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next Goal',
                          style: TextStyle(fontWeight: FontWeight.w800, color: colors.onPrimary)),
                      const SizedBox(height: 4),
                      Text(clearance.nextPractice,
                          style: TextStyle(fontSize: 14, height: 1.35, color: colors.onPrimary.withValues(alpha: 0.92))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (canRetry) ...[
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: buttonShape,
              ),
              onPressed: _tryAgain,
              child: const Text('Try This Mission Again', style: buttonText),
            ),
            const SizedBox(height: 12),
          ],
          if (canRetry)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: buttonShape,
              ),
              onPressed: _close,
              child: const Text('Return to Home', style: buttonText),
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: buttonShape,
              ),
              onPressed: _close,
              child: Text(widget.fromChat ? 'Return to Home' : 'Back to Certificates', style: buttonText),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

/// [text] with the part that differs from [other] marked (same start and same end are left plain).
class _ChangedText extends StatelessWidget {
  final String text;
  final String other;
  final TextStyle style;
  final TextStyle mark;

  const _ChangedText({required this.text, required this.other, required this.style, required this.mark});

  @override
  Widget build(BuildContext context) {
    final a = text.runes.toList();
    final b = other.runes.toList();
    var start = 0;
    while (start < a.length && start < b.length && a[start] == b[start]) {
      start++;
    }
    var end = 0;
    while (end < a.length - start && end < b.length - start && a[a.length - 1 - end] == b[b.length - 1 - end]) {
      end++;
    }
    final changedEnd = a.length - end;
    // Nothing in common: marking the whole sentence would say nothing.
    if (start == 0 && end == 0) return Text(text, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: String.fromCharCodes(a.sublist(0, start))),
          if (changedEnd > start) TextSpan(text: String.fromCharCodes(a.sublist(start, changedEnd)), style: mark),
          TextSpan(text: String.fromCharCodes(a.sublist(changedEnd))),
        ],
      ),
    );
  }
}
