import 'package:flutter/material.dart';

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

        return GestureDetector(
          onTap: isTappable ? () => onChunkTap?.call(entry.key, chunk) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Hitbox optimization
            decoration: BoxDecoration(
              color: isSelected 
                  ? cs.primary.withValues(alpha: 0.15) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? cs.primary.withValues(alpha: 0.4) 
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              display,
              style: TextStyle(
                fontSize: 22, // Slightly smaller than hardcoded text for better flow in Wrap
                fontWeight: FontWeight.bold,
                color: isSelected ? cs.primary : Colors.black87,
                decoration: isTappable ? TextDecoration.underline : TextDecoration.none,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: cs.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
