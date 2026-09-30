import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../providers/hangeul_lab_provider.dart';
import '../models/hangeul_character.dart';
import '../widgets/hangeul_slot.dart';
import '../widgets/hangeul_keyboard.dart';

class HangeulLabScreen extends ConsumerWidget {
  const HangeulLabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hangeulLabProvider);
    final notifier = ref.read(hangeulLabProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    // Keyboard follows the next empty slot: consonant → vowel → (optional) final consonant.
    final List<HangeulCharacter> currentKeyboard;
    final String keyboardTitle;
    final String activeType;
    if (state.initialConsonant == null) {
      currentKeyboard = HangeulConstants.initialConsonants;
      keyboardTitle = 'Consonants';
      activeType = 'initial';
    } else if (state.vowel == null) {
      currentKeyboard = HangeulConstants.vowels;
      keyboardTitle = 'Vowels';
      activeType = 'vowel';
    } else {
      currentKeyboard = HangeulConstants.finalConsonants;
      keyboardTitle = 'Final consonants (optional)';
      activeType = 'final';
    }

    final isReadyToCombine = state.initialConsonant != null && state.vowel != null;
    final hasResult = state.combinedResult.isNotEmpty;
    final hasAnySelection = state.initialConsonant != null || state.vowel != null || state.finalConsonant != null;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Hangeul Lab', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      // One scroll view: on small screens the keyboard stays reachable after a result appears.
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                color: cs.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Combine a consonant and a vowel (plus an optional final consonant, 받침) to build a syllable.',
                      style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: HangeulSlot(
                            stepNumber: 1,
                            label: 'Consonant',
                            character: state.initialConsonant,
                            isActive: state.initialConsonant == null,
                            onClear: () => notifier.clearSlot('initial'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text('+', style: TextStyle(fontSize: 24, color: cs.outline)),
                        ),
                        Expanded(
                          child: HangeulSlot(
                            stepNumber: 2,
                            label: 'Vowel',
                            character: state.vowel,
                            isActive: state.initialConsonant != null && state.vowel == null,
                            onClear: () => notifier.clearSlot('vowel'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text('+', style: TextStyle(fontSize: 24, color: cs.outline)),
                        ),
                        Expanded(
                          child: HangeulSlot(
                            stepNumber: 3,
                            label: 'Final',
                            character: state.finalConsonant,
                            isActive: isReadyToCombine && state.finalConsonant == null,
                            onClear: () => notifier.clearSlot('final'),
                          ),
                        ),
                      ],
                    ),
                    if (hasAnySelection) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tap a filled box to change it.',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // After combining, the same big button becomes "Try another" (clears everything).
                    // Changing any slot clears the result, so it turns back into "Combine!".
                    FilledButton.icon(
                      onPressed: hasResult ? notifier.reset : (isReadyToCombine ? notifier.combine : null),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(hasResult ? Icons.refresh : Icons.auto_fix_high, key: ValueKey(hasResult)),
                      ),
                      label: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          hasResult ? 'Try another' : 'Combine!',
                          key: ValueKey(hasResult),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),

              // C1 (CHARACTER_API §3.4): rabbit above the result card — happy on each new syllable.
              // Top padding 0.25×size so the jump has room (no clipping).
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Center(
                  child: MaruCharacter(
                    kind: MaruCharacterKind.rabbit,
                    size: 72,
                    mood: hasResult ? MaruMood.happy : MaruMood.idle,
                    reactionKey: state.combinedResult,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: state.combinedResult.isNotEmpty
                    ? _ResultCard(
                        result: state.combinedResult,
                        romanization: _romanize(state),
                        onReplay: notifier.replay,
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cs.outlineVariant, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lightbulb_outline, size: 24, color: cs.outline),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isReadyToCombine
                                    ? 'Tap Combine! to see and hear the syllable'
                                    : 'The combined syllable will appear here',
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              HangeulKeyboard(
                title: keyboardTitle,
                characters: currentKeyboard,
                onSelect: (char) => notifier.selectChar(char, activeType),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Simple letter-by-letter romanization of the picked jamo (e.g. ㅎ+ㅏ+ㄴ → "han").
  String _romanize(HangeulLabState state) {
    return [
      state.initialConsonant?.romanization ?? '',
      state.vowel?.romanization ?? '',
      state.finalConsonant?.romanization ?? '',
    ].join();
  }
}

class _ResultCard extends StatelessWidget {
  final String result;
  final String romanization;
  final VoidCallback onReplay;

  const _ResultCard({required this.result, required this.romanization, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primaryContainer, width: 2),
        boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Text(
            result,
            style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: cs.onSurface, height: 1.1),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Result',
                  style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  romanization.isEmpty ? '' : '[$romanization]',
                  style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onReplay,
            iconSize: 28,
            tooltip: 'Listen again',
            icon: const Icon(Icons.volume_up),
          ),
        ],
      ),
    );
  }
}
