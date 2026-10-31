import 'package:flutter/material.dart';
import 'lesson_style.dart';

/// A widget that renders Korean text split into morphological chunks (어절).
/// It supports a "Tap-to-Translate" feature where tapping a chunk shows
/// its internal morphological structure and functional dictionary.
class MorphologicalTextChunk extends StatelessWidget {
  final List<dynamic> chunks;
  final void Function(int index, Map<String, dynamic> chunk)? onChunkTap;

  /// Index of the selected chunk in [chunks] (by position, so repeated words
  /// like '저는' in the same list aren't highlighted together).
  final int? selectedIndex;

  const MorphologicalTextChunk({
    super.key,
    required this.chunks,
    this.onChunkTap,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 6.0, // Natural spacing between 'eojeol'
      runSpacing: 8.0,
      children: chunks.asMap().entries.map((entry) {
        final chunk = entry.value as Map<String, dynamic>;
        final display = chunk['display'] as String? ?? '';
        final isSelected = selectedIndex == entry.key;
        // Chunks with no tokens (glosses, symbols) have nothing to analyze
        final isTappable = (chunk['tokens'] as List<dynamic>? ?? []).isNotEmpty;

        return LessonPressable(
          pressedScale: 0.93,
          onTap: isTappable ? () => onChunkTap?.call(entry.key, chunk) : null,
          child: AnimatedContainer(
            duration: lessonMotion(context, 160),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primaryContainer
                  : (isTappable ? cs.primary.withValues(alpha: 0.06) : Colors.transparent),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? cs.primary.withValues(alpha: 0.55) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              display,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: isSelected ? cs.primary : cs.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
