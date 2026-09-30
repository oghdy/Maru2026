import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../models/mission_clearance_model.dart';
import '../providers/mission_chat_provider.dart';
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
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(
          switch (clearance.cleared) {
            true => 'Mission Cleared! 🎉',
            false => 'Mission Result',
            null => 'Mission Completed',
          },
          style: const TextStyle(fontWeight: FontWeight.bold),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? colors.primary : colors.outlineVariant,
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
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
          // Gold frame only for a real clear.
          border: Border.all(
            color: widget.clearance.cleared == true ? Colors.amber.shade600 : colors.outlineVariant,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildPage1Summary(MissionClearanceModel clearance) {
    final colors = Theme.of(context).colorScheme;
    final cleared = clearance.cleared;
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Result characters (CHARACTER_API 3.3 C5). Top gap leaves room for the jump.
          if (cleared != null) ...[
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: cleared
                  ? const [
                      MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.cheer, size: 110, entrance: true),
                      SizedBox(width: 12),
                      MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.happy, size: 110, entrance: true),
                    ]
                  : const [
                      MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.sad, size: 110),
                      SizedBox(width: 12),
                      MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.idle, size: 110),
                    ],
            ),
            const SizedBox(height: 16),
          ],
          Center(
            child: Text(
              cleared == true ? 'CERTIFICATE OF COMPLETION' : 'MISSION REPORT',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: colors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoRow('Mission:', clearance.missionTitle),
          if (clearance.goalCondition != null && clearance.goalCondition!.isNotEmpty)
            _buildInfoRow('Goal:', clearance.goalCondition!),
          _buildInfoRow('Persona:', clearance.persona),
          _buildInfoRow('Total Turns:', '${clearance.totalTurns} ${clearance.totalTurns == 1 ? 'turn' : 'turns'}'),
          _buildInfoRow(
            'Result:',
            switch (cleared) {
              true => 'Cleared 🎉',
              false => 'Not cleared yet — try again',
              null => 'Completed',
            },
          ),
          if (clearance.resultReason != null && clearance.resultReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cleared == true ? colors.primaryContainer : colors.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🐢', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clearance.resultReason!,
                      style: TextStyle(
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
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Swipe left to see feedback →',
              style: TextStyle(color: colors.onSurfaceVariant, fontStyle: FontStyle.italic),
            ),
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
          Text('✨ Great Expressions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary)),
          const SizedBox(height: 24),
          if (clearance.goodExpressions.isEmpty)
            Text('No expressions to highlight this time.', style: TextStyle(color: colors.onSurfaceVariant))
          else
            ...clearance.goodExpressions.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${e.expression}"', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(e.reason, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPage3AreasForImprovement(MissionClearanceModel clearance) {
    final colors = Theme.of(context).colorScheme;
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('📝 Areas for Improvement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
          const SizedBox(height: 24),
          if (clearance.incorrectExpressions.isEmpty)
            Text('No corrections needed this time.',
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold))
          else
            ...clearance.incorrectExpressions.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('❌ ${e.wrong}', style: TextStyle(color: colors.error, decoration: TextDecoration.lineThrough, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('✅ ${e.correct}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(e.explanation, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPage4TutorsNote(MissionClearanceModel clearance) {
    final colors = Theme.of(context).colorScheme;
    final canRetry = widget.fromChat &&
        clearance.cleared == false &&
        ref.read(missionChatProvider).setup != null;
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🐢', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tutor's Note",
                        style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(clearance.turtleComment, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎯 Next Goal:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.onPrimaryContainer)),
                const SizedBox(height: 4),
                Text(clearance.nextPractice,
                    style: TextStyle(fontSize: 14, color: colors.onPrimaryContainer)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          if (canRetry) ...[
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _tryAgain,
              child: const Text('Try This Mission Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
          ],
          if (canRetry)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _close,
              child: const Text('Return to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _close,
              child: Text(widget.fromChat ? 'Return to Home' : 'Back to Certificates',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
