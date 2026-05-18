import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/tts_helper.dart';

/// Provider for Hangeul learning state management
final hangeulViewModelProvider = StateNotifierProvider<HangeulViewModel, HangeulState>(
      (ref) => HangeulViewModel(),
);

/// State class holding all data for the Hangeul Master screen
@immutable
class HangeulState {
  final List<JamoData> consonants;
  final List<JamoData> vowels;
  final List<CombinedSyllable> combinedSyllables;
  final Set<String> learnedSyllables;
  final JamoData? selectedConsonant;
  final JamoData? selectedVowel;
  final JamoData? selectedFinalConsonant;
  final bool isAnimating;

  const HangeulState({
    required this.consonants,
    required this.vowels,
    this.combinedSyllables = const [],
    this.learnedSyllables = const {},
    this.selectedConsonant,
    this.selectedVowel,
    this.selectedFinalConsonant,
    this.isAnimating = false,
  });

  HangeulState copyWith({
    List<JamoData>? consonants,
    List<JamoData>? vowels,
    List<CombinedSyllable>? combinedSyllables,
    Set<String>? learnedSyllables,
    JamoData? selectedConsonant,
    JamoData? selectedVowel,
    JamoData? selectedFinalConsonant,
    bool? isAnimating,
    bool? clearSelected,
  }) {
    return HangeulState(
      consonants: consonants ?? this.consonants,
      vowels: vowels ?? this.vowels,
      combinedSyllables: combinedSyllables ?? this.combinedSyllables,
      learnedSyllables: learnedSyllables ?? this.learnedSyllables,
      selectedConsonant: (clearSelected == true) ? null : (selectedConsonant ?? this.selectedConsonant),
      selectedVowel: (clearSelected == true) ? null : (selectedVowel ?? this.selectedVowel),
      selectedFinalConsonant: (clearSelected == true) ? null : (selectedFinalConsonant ?? this.selectedFinalConsonant),
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

/// Data model for individual Jamo (consonant or vowel)
class JamoData {
  final String character;
  final String name;
  final String type;
  final String sound;
  final String? romanization;

  const JamoData({
    required this.character,
    required this.name,
    required this.type,
    required this.sound,
    this.romanization,
  });
}

/// Data model for combined syllable
class CombinedSyllable {
  final String character;
  final String? pronunciation;
  final JamoData consonant;
  final JamoData vowel;
  final JamoData? finalConsonant;
  final bool hasLinkingSound;

  const CombinedSyllable({
    required this.character,
    this.pronunciation,
    required this.consonant,
    required this.vowel,
    this.finalConsonant,
    this.hasLinkingSound = false,
  });
}

/// ViewModel managing the business logic for Hangeul Master
class HangeulViewModel extends StateNotifier<HangeulState> {
  final TtsHelper _ttsHelper = TtsHelper();

  HangeulViewModel() : super(HangeulState(
    consonants: _mockConsonants,
    vowels: _mockVowels,
  )) {
    _initializeTTS();
  }

  void _initializeTTS() {
    _ttsHelper.initialize();
  }

  /// Select consonant (Step 1)
  void selectConsonant(JamoData consonant) {
    state = state.copyWith(selectedConsonant: consonant);
    debugPrint('✅ Selected consonant: ${consonant.character}');
  }

  /// Select vowel (Step 2)
  void selectVowel(JamoData vowel) {
    state = state.copyWith(selectedVowel: vowel);
    debugPrint('✅ Selected vowel: ${vowel.character}');
  }

  /// Select final consonant / 받침 (Step 3)
  void selectFinalConsonant(JamoData consonant) {
    state = state.copyWith(selectedFinalConsonant: consonant);
    debugPrint('✅ Selected final consonant: ${consonant.character}');
  }

  /// Combine selected consonant and vowel (Step 4)
  void combineSyllables() {
    if (state.selectedConsonant == null || state.selectedVowel == null) {
      debugPrint('❌ Cannot combine: missing consonant or vowel');
      return;
    }

    debugPrint('🔵 Before: C=${state.selectedConsonant?.character}, V=${state.selectedVowel?.character}, F=${state.selectedFinalConsonant?.character}');

    // Save current selections
    final consonant = state.selectedConsonant!;
    final vowel = state.selectedVowel!;

    // Merge syllable (this adds to combinedSyllables list)
    _mergeSyllable(consonant, vowel);

    debugPrint('🔵 After merge: syllables=${state.combinedSyllables.length}');

    // CRITICAL: Manually clear by reassigning state
    // This triggers a state change notification
    final clearedState = HangeulState(
      consonants: state.consonants,
      vowels: state.vowels,
      combinedSyllables: state.combinedSyllables,
      learnedSyllables: state.learnedSyllables,
      selectedConsonant: null,
      selectedVowel: null,
      selectedFinalConsonant: null,
      isAnimating: false,
    );

    state = clearedState;

    debugPrint('🟢 Cleared: C=${state.selectedConsonant}, V=${state.selectedVowel}, F=${state.selectedFinalConsonant}');
  }

  void onJamoDragEnd(JamoData jamo, DraggableDetails details) {
    state = state.copyWith(clearSelected: true);
  }

  void checkForMerge(JamoData draggedJamo, Offset position) {
    if (draggedJamo.type == 'consonant') {
      state = state.copyWith(selectedConsonant: draggedJamo);
    } else {
      state = state.copyWith(selectedVowel: draggedJamo);
    }

    if (state.selectedConsonant != null && state.selectedVowel != null) {
      _mergeSyllable(state.selectedConsonant!, state.selectedVowel!);
    }
  }

  void _mergeSyllable(JamoData consonant, JamoData vowel) {
    final String combinedChar = _combineJamo(
      consonant.character,
      vowel.character,
      finalConsonant: state.selectedFinalConsonant?.character,
    );

    final syllable = CombinedSyllable(
      character: combinedChar,
      pronunciation: _getPronunciation(consonant, vowel, state.selectedFinalConsonant),
      consonant: consonant,
      vowel: vowel,
      finalConsonant: state.selectedFinalConsonant,
    );

    final updatedSyllables = [...state.combinedSyllables, syllable];
    final updatedLearned = {...state.learnedSyllables, combinedChar};

    state = state.copyWith(
      combinedSyllables: updatedSyllables,
      learnedSyllables: updatedLearned,
      // Don't clear here - will be cleared in combineSyllables()
    );

    playSyllableSound(syllable);
  }

  String _combineJamo(String consonant, String vowel, {String? finalConsonant}) {
    final consonantIndex = _getConsonantIndex(consonant);
    final vowelIndex = _getVowelIndex(vowel);

    if (consonantIndex == -1 || vowelIndex == -1) {
      return consonant + vowel;
    }

    int finalConsonantIndex = 0;
    if (finalConsonant != null) {
      finalConsonantIndex = _getFinalConsonantIndex(finalConsonant);
      if (finalConsonantIndex == -1) finalConsonantIndex = 0;
    }

    final syllableCode = 0xAC00 + (consonantIndex * 588) + (vowelIndex * 28) + finalConsonantIndex;
    return String.fromCharCode(syllableCode);
  }

  String _getPronunciation(JamoData consonant, JamoData vowel, [JamoData? finalConsonant]) {
    if (finalConsonant != null) {
      return consonant.sound + vowel.sound + finalConsonant.sound;
    }
    return consonant.sound + vowel.sound;
  }

  Future<void> playSyllableSound(CombinedSyllable syllable) async {
    await _ttsHelper.speak(syllable.character);
    debugPrint('🔊 Playing sound for: ${syllable.character} [${syllable.pronunciation}]');
  }

  Future<void> demonstrateLinkingSound(
      CombinedSyllable syllable1,
      CombinedSyllable syllable2,
      ) async {
    if (syllable1.finalConsonant == null) return;

    state = state.copyWith(isAnimating: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final linkedSyllable = CombinedSyllable(
      character: syllable1.character + syllable2.character,
      pronunciation: _getLinkingSoundPronunciation(syllable1, syllable2),
      consonant: syllable1.consonant,
      vowel: syllable1.vowel,
      finalConsonant: syllable1.finalConsonant,
      hasLinkingSound: true,
    );

    await playSyllableSound(linkedSyllable);
    state = state.copyWith(isAnimating: false);
  }

  String _getLinkingSoundPronunciation(
      CombinedSyllable syllable1,
      CombinedSyllable syllable2,
      ) {
    if (syllable1.finalConsonant == null) {
      return syllable1.character + syllable2.character;
    }

    final firstPart = syllable1.consonant.sound + syllable1.vowel.sound;
    final linkedPart = syllable1.finalConsonant!.sound + syllable2.vowel.sound;

    return firstPart + linkedPart;
  }

  int _getConsonantIndex(String consonant) {
    const consonants = [
      'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ',
      'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    ];
    return consonants.indexOf(consonant);
  }

  int _getVowelIndex(String vowel) {
    const vowels = [
      'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ',
      'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ'
    ];
    return vowels.indexOf(vowel);
  }

  int _getFinalConsonantIndex(String consonant) {
    const finalConsonants = [
      '', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ',
      'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    ];
    return finalConsonants.indexOf(consonant);
  }

  @override
  void dispose() {
    _ttsHelper.stop();
    super.dispose();
  }
}

// ============================================================================
// MOCK DATA
// ============================================================================

final List<JamoData> _mockConsonants = [
  JamoData(
    character: 'ㄱ',
    name: '기역',
    type: 'consonant',
    sound: 'g',
    romanization: 'giyeok',
  ),
  JamoData(
    character: 'ㄴ',
    name: '니은',
    type: 'consonant',
    sound: 'n',
    romanization: 'nieun',
  ),
  JamoData(
    character: 'ㄷ',
    name: '디귿',
    type: 'consonant',
    sound: 'd',
    romanization: 'digeut',
  ),
  JamoData(
    character: 'ㄹ',
    name: '리을',
    type: 'consonant',
    sound: 'r',
    romanization: 'rieul',
  ),
  JamoData(
    character: 'ㅁ',
    name: '미음',
    type: 'consonant',
    sound: 'm',
    romanization: 'mieum',
  ),
  JamoData(
    character: 'ㅂ',
    name: '비읍',
    type: 'consonant',
    sound: 'b',
    romanization: 'bieup',
  ),
  JamoData(
    character: 'ㅅ',
    name: '시옷',
    type: 'consonant',
    sound: 's',
    romanization: 'siot',
  ),
  JamoData(
    character: 'ㅇ',
    name: '이응',
    type: 'consonant',
    sound: '',
    romanization: 'ieung',
  ),
  JamoData(
    character: 'ㅈ',
    name: '지읒',
    type: 'consonant',
    sound: 'j',
    romanization: 'jieut',
  ),
  JamoData(
    character: 'ㅊ',
    name: '치읓',
    type: 'consonant',
    sound: 'ch',
    romanization: 'chieut',
  ),
  JamoData(
    character: 'ㅋ',
    name: '키읔',
    type: 'consonant',
    sound: 'k',
    romanization: 'kieuk',
  ),
  JamoData(
    character: 'ㅌ',
    name: '티읕',
    type: 'consonant',
    sound: 't',
    romanization: 'tieut',
  ),
  JamoData(
    character: 'ㅍ',
    name: '피읖',
    type: 'consonant',
    sound: 'p',
    romanization: 'pieup',
  ),
  JamoData(
    character: 'ㅎ',
    name: '히읗',
    type: 'consonant',
    sound: 'h',
    romanization: 'hieut',
  ),
];

final List<JamoData> _mockVowels = [
  JamoData(
    character: 'ㅏ',
    name: '아',
    type: 'vowel',
    sound: 'a',
  ),
  JamoData(
    character: 'ㅑ',
    name: '야',
    type: 'vowel',
    sound: 'ya',
  ),
  JamoData(
    character: 'ㅓ',
    name: '어',
    type: 'vowel',
    sound: 'eo',
  ),
  JamoData(
    character: 'ㅕ',
    name: '여',
    type: 'vowel',
    sound: 'yeo',
  ),
  JamoData(
    character: 'ㅗ',
    name: '오',
    type: 'vowel',
    sound: 'o',
  ),
  JamoData(
    character: 'ㅛ',
    name: '요',
    type: 'vowel',
    sound: 'yo',
  ),
  JamoData(
    character: 'ㅜ',
    name: '우',
    type: 'vowel',
    sound: 'u',
  ),
  JamoData(
    character: 'ㅠ',
    name: '유',
    type: 'vowel',
    sound: 'yu',
  ),
  JamoData(
    character: 'ㅡ',
    name: '으',
    type: 'vowel',
    sound: 'eu',
  ),
  JamoData(
    character: 'ㅣ',
    name: '이',
    type: 'vowel',
    sound: 'i',
  ),
];

