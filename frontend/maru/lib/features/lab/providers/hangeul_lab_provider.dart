import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/hangeul_character.dart';
import '../utils/hangeul_combiner.dart';

class HangeulLabState {
  final HangeulCharacter? initialConsonant;
  final HangeulCharacter? vowel;
  final HangeulCharacter? finalConsonant;
  final String combinedResult;
  final bool isInitialTurn; // true = Select Initial, false = Select Vowel/Final

  HangeulLabState({
    this.initialConsonant,
    this.vowel,
    this.finalConsonant,
    this.combinedResult = '',
    this.isInitialTurn = true,
  });

  HangeulLabState copyWith({
    HangeulCharacter? initialConsonant,
    HangeulCharacter? vowel,
    HangeulCharacter? finalConsonant,
    String? combinedResult,
    bool? isInitialTurn,
  }) {
    return HangeulLabState(
      initialConsonant: initialConsonant ?? this.initialConsonant,
      vowel: vowel ?? this.vowel,
      finalConsonant: finalConsonant ?? this.finalConsonant,
      combinedResult: combinedResult ?? this.combinedResult,
      isInitialTurn: isInitialTurn ?? this.isInitialTurn,
    );
  }

  HangeulLabState clear() {
    return HangeulLabState();
  }
}

class HangeulLabNotifier extends Notifier<HangeulLabState> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  HangeulLabState build() {
    _initTts();
    return HangeulLabState();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void selectChar(HangeulCharacter char, String type) {
    if (type == 'initial') {
      state = state.copyWith(initialConsonant: char, isInitialTurn: false);
    } else if (type == 'vowel') {
      state = state.copyWith(vowel: char);
    } else if (type == 'final') {
      state = state.copyWith(finalConsonant: char);
    }
    
    // Auto clear result when modifying
    if (state.combinedResult.isNotEmpty) {
      state = state.copyWith(combinedResult: '');
    }
  }

  void clearSlot(String type) {
    if (type == 'initial') {
      state = HangeulLabState(
        initialConsonant: null,
        vowel: state.vowel,
        finalConsonant: state.finalConsonant,
        isInitialTurn: true,
      );
    } else if (type == 'vowel') {
      state = HangeulLabState(
        initialConsonant: state.initialConsonant,
        vowel: null,
        finalConsonant: state.finalConsonant,
        isInitialTurn: state.isInitialTurn,
      );
    } else if (type == 'final') {
      state = HangeulLabState(
        initialConsonant: state.initialConsonant,
        vowel: state.vowel,
        finalConsonant: null,
        isInitialTurn: state.isInitialTurn,
      );
    }
  }

  void combine() {
    if (state.initialConsonant == null || state.vowel == null) {
      return; // Need at least Cho and Jung
    }
    
    final result = HangeulCombiner.combine(
      state.initialConsonant!.index,
      state.vowel!.index,
      state.finalConsonant?.index ?? 0,
    );
    
    state = state.copyWith(combinedResult: result);
    _speak(result);
  }

  /// Plays the current result again.
  void replay() => _speak(state.combinedResult);

  /// Clears all slots and the result.
  void reset() {
    state = state.clear();
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }
}

final hangeulLabProvider = NotifierProvider<HangeulLabNotifier, HangeulLabState>(HangeulLabNotifier.new);
