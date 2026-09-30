import 'package:flutter/material.dart';
import '../models/hangeul_character.dart';

class HangeulKeyboard extends StatelessWidget {
  final String title;
  final List<HangeulCharacter> characters;
  final Function(HangeulCharacter) onSelect;

  const HangeulKeyboard({super.key, required this.title, required this.characters, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // The "blank" final consonant (no 받침) is chosen by simply not picking one.
    final keys = characters.where((char) => char.char.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final char in keys)
                Material(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  shadowColor: cs.primary.withValues(alpha: 0.4),
                  child: InkWell(
                    onTap: () => onSelect(char),
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 60,
                      height: 64,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            char.char,
                            style: TextStyle(color: cs.onPrimary, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          // Romanization under the letter (used to overlap long ones like "yae").
                          Text(
                            char.romanization.isEmpty ? '–' : char.romanization,
                            style: TextStyle(
                              color: cs.onPrimary.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
