import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../../lesson/widgets/lesson_style.dart';

/// The turtle's occasional "well said", small and under the message so it never covers the chat.
/// Sits with the yellow and red cards as the good-news one. Null text = nothing to say this turn.
class ChatPraiseChip extends StatelessWidget {
  final String? praise;
  final String? praiseEn;

  const ChatPraiseChip({super.key, this.praise, this.praiseEn});

  @override
  Widget build(BuildContext context) {
    final color = lessonSuccess();
    return LessonPopIn(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 12, 8),
        decoration: BoxDecoration(
          color: lessonSuccessSoft(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.happy, size: 30, interactive: false),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (praise != null)
                    LessonText(
                      praise!,
                      style: TextStyle(color: color, fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w700),
                    ),
                  if (praiseEn != null)
                    LessonText(
                      praiseEn!,
                      style: TextStyle(color: color.withValues(alpha: 0.85), fontSize: 12.5, height: 1.3),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
