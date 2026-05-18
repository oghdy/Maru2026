import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    // Determine what keyboard to show based on state
    List<HangeulCharacter> currentKeyboard = HangeulConstants.initialConsonants;
    String keyboardTitle = '자음 (Consonants)';
    String activeType = 'initial';

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
      keyboardTitle = 'Final Consonants';
      activeType = 'final';
    }

    final isReadyToCombine = state.initialConsonant != null && state.vowel != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Hangeul Lab', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feel free to experiment',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Combine consonants and vowels to create letters',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                
                // 3 Slots Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade200, blurRadius: 16, spreadRadius: 4),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          HangeulSlot(
                            stepNumber: 1,
                            label: 'Consonant',
                            character: state.initialConsonant,
                            isActive: state.initialConsonant == null,
                            onClear: () => notifier.clearSlot('initial'),
                          ),
                          const Text('+', style: TextStyle(fontSize: 24, color: Colors.grey)),
                          HangeulSlot(
                            stepNumber: 2,
                            label: 'Vowel',
                            character: state.vowel,
                            isActive: state.initialConsonant != null && state.vowel == null,
                            onClear: () => notifier.clearSlot('vowel'),
                          ),
                          const Text('+', style: TextStyle(fontSize: 24, color: Colors.grey)),
                          HangeulSlot(
                            stepNumber: 3,
                            label: 'Final',
                            character: state.finalConsonant,
                            isActive: state.initialConsonant != null && state.vowel != null && state.finalConsonant == null,
                            onClear: () => notifier.clearSlot('final'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Combine Button
                      GestureDetector(
                        onTap: isReadyToCombine ? () => notifier.combine() : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isReadyToCombine ? Colors.blueAccent : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                                child: const Text('4', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.touch_app, color: isReadyToCombine ? Colors.white : Colors.grey.shade500, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Combine!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isReadyToCombine ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Output Section
          if (state.combinedResult.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.blue.shade100, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Result', style: TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      state.combinedResult,
                      style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            )
          else
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('The combined letter will appear here', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  ],
                ),
              ),
            ),

          // Keyboard Section
          Expanded(
            child: SingleChildScrollView(
              child: HangeulKeyboard(
                title: keyboardTitle,
                characters: currentKeyboard,
                onSelect: (char) => notifier.selectChar(char, activeType),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
