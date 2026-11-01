import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../../lesson/widgets/lesson_style.dart';
import '../models/korean_text.dart';

/// Turtle correction, styled like a football card (MSN-1.7.3, original design):
/// red = serious mistake, the message was stopped (severity "immediate");
/// yellow = small slip, the chat goes on (severity "side").
enum CorrectionCardType { red, yellow }

class ChatCorrectionCard extends StatelessWidget {
  final CorrectionCardType type;
  final String? issueLabel; // e.g. "Politeness level"
  final String? message; // Korean feedback
  final String? messageEn;
  final Object? reactionKey; // new value -> the turtle reacts again
  final double characterSize;
  // Yellow card: sentence for the optional "Say it again" practice. Stays on this device: no /chat
  // call, not in the history, no turn used (web-demo API_CONTRACT 7.4).
  final String? sayAgainTarget;
  // Red card: the line didn't count, so saying it again is a normal message from the input box.
  final VoidCallback? onSayAgain;

  const ChatCorrectionCard({
    super.key,
    required this.type,
    this.issueLabel,
    this.message,
    this.messageEn,
    this.reactionKey,
    this.characterSize = 40,
    this.sayAgainTarget,
    this.onSayAgain,
  });

  // Fixed semantic colors, like the vocab rating buttons: these mean red / yellow card.
  static const _redBg = Color(0xFFFFECEC);
  static const _redEdge = Color(0xFFE5484D);
  static const _redText = Color(0xFF8A1C22);
  static const _yellowBg = Color(0xFFFFF7DB);
  static const _yellowEdge = Color(0xFFF5B800);
  static const _yellowText = Color(0xFF6B4E00);

  @override
  Widget build(BuildContext context) {
    final isRed = type == CorrectionCardType.red;
    final bg = isRed ? _redBg : _yellowBg;
    final edge = isRed ? _redEdge : _yellowEdge;
    final text = isRed ? _redText : _yellowText;
    final title = isRed ? 'Red card' : 'Yellow card';
    final subtitle = isRed ? 'Try that line again' : 'Small slip — keep going';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: edge.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MaruCharacter(
                kind: MaruCharacterKind.turtle,
                mood: isRed ? MaruMood.thinking : MaruMood.idle,
                size: characterSize,
                reactionKey: reactionKey,
                interactive: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // The card itself: a small tilted red / yellow card.
                        Transform.rotate(
                          angle: -0.12,
                          child: Container(
                            width: 12,
                            height: 16,
                            decoration: BoxDecoration(color: edge, borderRadius: BorderRadius.circular(2.5)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        if (issueLabel != null && issueLabel!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: edge.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                issueLabel!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: text.withValues(alpha: 0.75), fontSize: 12)),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      LessonText(message!, style: TextStyle(color: text, fontSize: 15, height: 1.4)),
                    ],
                    if (messageEn != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        messageEn!,
                        style: TextStyle(
                          color: text.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (sayAgainTarget != null) ...[const SizedBox(height: 10), _SayAgainPanel(target: sayAgainTarget!)],
          if (onSayAgain != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: _SayAgainButton(color: text, edge: edge, onTap: onSayAgain!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SayAgainButton extends StatelessWidget {
  final Color color;
  final Color edge;
  final VoidCallback onTap;

  const _SayAgainButton({required this.color, required this.edge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LessonPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: edge.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay_rounded, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              'Say it again',
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SayAgainStage { idle, trying, missed, matched }

/// Optional practice under a yellow card. Has its own small field so the reply box stays free:
/// the learner can ignore this and just answer Tokki.
class _SayAgainPanel extends StatefulWidget {
  final String target;

  const _SayAgainPanel({required this.target});

  @override
  State<_SayAgainPanel> createState() => _SayAgainPanelState();
}

class _SayAgainPanelState extends State<_SayAgainPanel> {
  final TextEditingController _controller = TextEditingController();
  _SayAgainStage _stage = _SayAgainStage.idle;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _stage = _SayAgainStage.trying);
    // The card may be the last thing in the chat: bring the new field into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(context, alignment: 1, duration: lessonMotion(context, 200));
    });
  }

  void _check() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _stage = isSameSentence(_controller.text, widget.target) ? _SayAgainStage.matched : _SayAgainStage.missed;
    });
  }

  void _skip() {
    _controller.clear();
    setState(() => _stage = _SayAgainStage.idle);
  }

  @override
  Widget build(BuildContext context) {
    const text = ChatCorrectionCard._yellowText;
    const edge = ChatCorrectionCard._yellowEdge;
    return switch (_stage) {
      _SayAgainStage.idle => Align(
        alignment: Alignment.centerLeft,
        child: _SayAgainButton(color: text, edge: edge, onTap: _open),
      ),
      _SayAgainStage.matched => LessonPopIn(child: _buildMatched()),
      _ => _buildTrying(text, edge),
    };
  }

  Widget _buildMatched() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(color: lessonSuccessSoft(), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.happy, size: 30, interactive: false),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nice! That sounds natural.',
              style: TextStyle(color: lessonSuccess(), fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrying(Color text, Color edge) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try this',
          style: TextStyle(color: text.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        LessonText(
          widget.target,
          style: TextStyle(color: text, fontSize: 15, height: 1.35, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                minLines: 1,
                maxLines: 3,
                style: const TextStyle(fontSize: 15),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _check(),
                decoration: InputDecoration(
                  hintText: 'Type it here...',
                  hintStyle: TextStyle(color: text.withValues(alpha: 0.5), fontSize: 14),
                  isDense: true,
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: edge, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: 'Check',
              child: LessonPressable(
                pressedScale: 0.9,
                onTap: _check,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: edge, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _stage == _SayAgainStage.missed
                  ? Text(
                      'Close! Have another go, or skip it.',
                      style: TextStyle(color: text, fontSize: 12.5, height: 1.3),
                    )
                  : const SizedBox.shrink(),
            ),
            TextButton(
              onPressed: _skip,
              style: TextButton.styleFrom(
                foregroundColor: text,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(44, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Skip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Learner-facing name for the turtle's issueType code (API_CONTRACT 1-2).
String? correctionIssueLabel(String issueType) {
  return switch (issueType) {
    'honorific_mismatch' => 'Politeness level',
    'grammar_error' => 'Grammar',
    'vocabulary' => 'Word choice',
    'pragmatic' => 'Sounds unnatural',
    'off_topic' => 'Off topic',
    _ => null,
  };
}
