import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
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
                    const SizedBox(height: 20),
                    Text(
                      heading,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                            height: 1.2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (instruction.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        instruction.trim(),
                        style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (scorePercent != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Score: $scorePercent%',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                    ],
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(fontSize: 16, height: 1.5, color: colorScheme.onSurface),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    if (highlights.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'What you learned',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: highlights
                            .map((h) => Chip(
                                  label: Text(
                                    h,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                                  side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: const Text('Continue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
