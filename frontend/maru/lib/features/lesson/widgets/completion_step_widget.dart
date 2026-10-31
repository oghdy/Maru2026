import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';
import 'lesson_style.dart';

/// Final step of a lesson. Everything shown comes from the lesson data:
/// the step's `title`/`instruction` and the content's `text`/`highlights`.
class CompletionStepWidget extends StatelessWidget {
  final Map<String, dynamic> content;
  final String title;
  final String instruction;

  /// First-attempt accuracy of this lesson's graded questions, or null if nothing was graded.
  final int? scorePercent;
  final VoidCallback onNext;

  const CompletionStepWidget({
    super.key,
    required this.content,
    required this.onNext,
    this.title = '',
    this.instruction = '',
    this.scorePercent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = (content['text'] as String? ?? '').trim();
    final highlights = (content['highlights'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final heading = title.trim().isNotEmpty ? title.trim() : 'Lesson Complete!';
    final score = scorePercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🐰 cheers, 🐢 is happy — both pop in (CHARACTER_API §3.1 C3).
                  // Top padding leaves room for the cheer jump (0.25 × size).
                  const Padding(
                    padding: EdgeInsets.only(top: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MaruCharacter(
                          kind: MaruCharacterKind.rabbit,
                          mood: MaruMood.cheer,
                          size: 110,
                          entrance: true,
                        ),
                        SizedBox(width: 12),
                        MaruCharacter(
                          kind: MaruCharacterKind.turtle,
                          mood: MaruMood.happy,
                          size: 110,
                          entrance: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    heading,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          height: 1.2,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (instruction.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      instruction.trim(),
                      style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (score != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: missionCardDecoration(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LessonRing(
                            size: 60,
                            strokeWidth: 6,
                            value: score / 100,
                            child: Icon(Icons.emoji_events_rounded, color: colorScheme.primary, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Score: $score%',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Right on the first try',
                                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: missionCardDecoration(context),
                      child: Text(
                        text,
                        style: TextStyle(fontSize: 15, height: 1.5, color: colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  if (highlights.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Center(child: LessonOverline('What you learned', color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: highlights
                          .map((h) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  h,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.primary),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: LessonPrimaryButton(label: 'Continue', onPressed: onNext),
        ),
      ],
    );
  }
}
