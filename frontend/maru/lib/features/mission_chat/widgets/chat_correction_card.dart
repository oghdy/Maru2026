import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';

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

  const ChatCorrectionCard({
    super.key,
    required this.type,
    this.issueLabel,
    this.message,
    this.messageEn,
    this.reactionKey,
    this.characterSize = 40,
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
      child: Row(
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
                        decoration: BoxDecoration(
                          color: edge,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
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
                  Text(message!, style: TextStyle(color: text, fontSize: 15, height: 1.4)),
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
