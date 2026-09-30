import 'package:flutter/material.dart';

/// A widget that renders Korean text split into morphological chunks (어절).
/// It supports a "Tap-to-Translate" feature where tapping a chunk shows 
/// its internal morphological structure and functional dictionary.
class MorphologicalTextChunk extends StatelessWidget {
  final List<dynamic> chunks;
  final Function(Map<String, dynamic> chunk)? onChunkTap;
  final String? selectedChunkDisplay;

  const MorphologicalTextChunk({
    super.key,
    required this.chunks,
    this.onChunkTap,
    this.selectedChunkDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 6.0, // Natural spacing between 'eojeol'
      runSpacing: 8.0,
      children: chunks.map((chunkData) {
        final chunk = chunkData as Map<String, dynamic>;
        final display = chunk['display'] as String? ?? '';
        final isSelected = selectedChunkDisplay == display;
        // Chunks with no tokens (glosses, symbols) have nothing to analyze
        final isTappable = (chunk['tokens'] as List<dynamic>? ?? []).isNotEmpty;

        return GestureDetector(
          onTap: isTappable ? () => onChunkTap?.call(chunk) : null,
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
