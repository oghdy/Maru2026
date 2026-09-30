/// Small Hangul helpers used by the Unit 0 cards. Everything here is derived
/// from the Unicode layout of Hangul, so the card text is always true for the
/// character shown (no per-letter hand-written copy needed).
library;

const _choseong = ['ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'];
const _jungseong = ['ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ'];
const _jongseong = ['', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'];

/// Letters that are written by combining two simpler letters.
const _combined = {
  'ㅘ': ['ㅗ', 'ㅏ'], 'ㅙ': ['ㅗ', 'ㅐ'], 'ㅚ': ['ㅗ', 'ㅣ'],
  'ㅝ': ['ㅜ', 'ㅓ'], 'ㅞ': ['ㅜ', 'ㅔ'], 'ㅟ': ['ㅜ', 'ㅣ'], 'ㅢ': ['ㅡ', 'ㅣ'],
  'ㄲ': ['ㄱ', 'ㄱ'], 'ㄸ': ['ㄷ', 'ㄷ'], 'ㅃ': ['ㅂ', 'ㅂ'], 'ㅆ': ['ㅅ', 'ㅅ'], 'ㅉ': ['ㅈ', 'ㅈ'],
  'ㄳ': ['ㄱ', 'ㅅ'], 'ㄵ': ['ㄴ', 'ㅈ'], 'ㄶ': ['ㄴ', 'ㅎ'], 'ㄺ': ['ㄹ', 'ㄱ'], 'ㄻ': ['ㄹ', 'ㅁ'],
  'ㄼ': ['ㄹ', 'ㅂ'], 'ㄽ': ['ㄹ', 'ㅅ'], 'ㄾ': ['ㄹ', 'ㅌ'], 'ㄿ': ['ㄹ', 'ㅍ'], 'ㅀ': ['ㄹ', 'ㅎ'], 'ㅄ': ['ㅂ', 'ㅅ'],
};

enum HangulKind { vowel, consonant, syllable, word, other }

bool _isSyllable(int c) => c >= 0xAC00 && c <= 0xD7A3;
bool _isConsonantJamo(int c) => c >= 0x3131 && c <= 0x314E;
bool _isVowelJamo(int c) => c >= 0x314F && c <= 0x3163;

HangulKind hangulKind(String text) {
  final runes = text.runes.toList();
  if (runes.isEmpty) return HangulKind.other;
  if (runes.length > 1) return runes.every(_isSyllable) ? HangulKind.word : HangulKind.other;
  final c = runes.first;
  if (_isVowelJamo(c)) return HangulKind.vowel;
  if (_isConsonantJamo(c)) return HangulKind.consonant;
  if (_isSyllable(c)) return HangulKind.syllable;
  return HangulKind.other;
}

/// Parts of one syllable block: initial consonant, vowel, final consonant ('' if none).
class SyllableParts {
  final String initial;
  final String vowel;
  final String finalConsonant;
  const SyllableParts(this.initial, this.vowel, this.finalConsonant);

  List<String> get letters => [initial, vowel, if (finalConsonant.isNotEmpty) finalConsonant];
}

SyllableParts? decomposeSyllable(String syllable) {
  final runes = syllable.runes.toList();
  if (runes.length != 1 || !_isSyllable(runes.first)) return null;
  final index = runes.first - 0xAC00;
  return SyllableParts(
    _choseong[index ~/ (21 * 28)],
    _jungseong[(index % (21 * 28)) ~/ 28],
    _jongseong[index % 28],
  );
}

/// The two simpler letters a combined vowel/double consonant is written from, or null.
List<String>? combinedFrom(String jamo) => _combined[jamo];

/// Consonant + ㅏ as one syllable (e.g. ㄱ → 가), or null if the consonant can't start a syllable.
String? withVowelA(String consonant) {
  final i = _choseong.indexOf(consonant);
  if (i < 0) return null;
  return String.fromCharCode(0xAC00 + (i * 21) * 28);
}

/// ㅇ + vowel as one syllable (e.g. ㅏ → 아) — how a vowel is written on its own.
String? withSilentO(String vowel) {
  final i = _jungseong.indexOf(vowel);
  if (i < 0) return null;
  return String.fromCharCode(0xAC00 + (11 * 21 + i) * 28);
}
