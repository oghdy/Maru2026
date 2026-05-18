class HangeulCharacter {
  final String char;
  final String romanization;
  final int index; // Index mapped to Unicode standard

  const HangeulCharacter({
    required this.char,
    required this.romanization,
    required this.index,
  });
}

class HangeulConstants {
  static const List<HangeulCharacter> initialConsonants = [
    HangeulCharacter(char: 'ㄱ', romanization: 'g', index: 0),
    HangeulCharacter(char: 'ㄲ', romanization: 'kk', index: 1),
    HangeulCharacter(char: 'ㄴ', romanization: 'n', index: 2),
    HangeulCharacter(char: 'ㄷ', romanization: 'd', index: 3),
    HangeulCharacter(char: 'ㄸ', romanization: 'tt', index: 4),
    HangeulCharacter(char: 'ㄹ', romanization: 'r', index: 5),
    HangeulCharacter(char: 'ㅁ', romanization: 'm', index: 6),
    HangeulCharacter(char: 'ㅂ', romanization: 'b', index: 7),
    HangeulCharacter(char: 'ㅃ', romanization: 'pp', index: 8),
    HangeulCharacter(char: 'ㅅ', romanization: 's', index: 9),
    HangeulCharacter(char: 'ㅆ', romanization: 'ss', index: 10),
    HangeulCharacter(char: 'ㅇ', romanization: '', index: 11),
    HangeulCharacter(char: 'ㅈ', romanization: 'j', index: 12),
    HangeulCharacter(char: 'ㅉ', romanization: 'jj', index: 13),
    HangeulCharacter(char: 'ㅊ', romanization: 'ch', index: 14),
    HangeulCharacter(char: 'ㅋ', romanization: 'k', index: 15),
    HangeulCharacter(char: 'ㅌ', romanization: 't', index: 16),
    HangeulCharacter(char: 'ㅍ', romanization: 'p', index: 17),
    HangeulCharacter(char: 'ㅎ', romanization: 'h', index: 18),
  ];

  static const List<HangeulCharacter> vowels = [
    HangeulCharacter(char: 'ㅏ', romanization: 'a', index: 0),
    HangeulCharacter(char: 'ㅐ', romanization: 'ae', index: 1),
    HangeulCharacter(char: 'ㅑ', romanization: 'ya', index: 2),
    HangeulCharacter(char: 'ㅒ', romanization: 'yae', index: 3),
    HangeulCharacter(char: 'ㅓ', romanization: 'eo', index: 4),
    HangeulCharacter(char: 'ㅔ', romanization: 'e', index: 5),
    HangeulCharacter(char: 'ㅕ', romanization: 'yeo', index: 6),
    HangeulCharacter(char: 'ㅖ', romanization: 'ye', index: 7),
    HangeulCharacter(char: 'ㅗ', romanization: 'o', index: 8),
    HangeulCharacter(char: 'ㅘ', romanization: 'wa', index: 9),
    HangeulCharacter(char: 'ㅙ', romanization: 'wae', index: 10),
    HangeulCharacter(char: 'ㅚ', romanization: 'oe', index: 11),
    HangeulCharacter(char: 'ㅛ', romanization: 'yo', index: 12),
    HangeulCharacter(char: 'ㅜ', romanization: 'u', index: 13),
    HangeulCharacter(char: 'ㅝ', romanization: 'weo', index: 14),
    HangeulCharacter(char: 'ㅞ', romanization: 'we', index: 15),
    HangeulCharacter(char: 'ㅟ', romanization: 'wi', index: 16),
    HangeulCharacter(char: 'ㅠ', romanization: 'yu', index: 17),
    HangeulCharacter(char: 'ㅡ', romanization: 'eu', index: 18),
    HangeulCharacter(char: 'ㅢ', romanization: 'ui', index: 19),
    HangeulCharacter(char: 'ㅣ', romanization: 'i', index: 20),
  ];

  static const List<HangeulCharacter> finalConsonants = [
    HangeulCharacter(char: ' ', romanization: '', index: 0), // Blank (No jongseong)
    HangeulCharacter(char: 'ㄱ', romanization: 'k', index: 1),
    HangeulCharacter(char: 'ㄲ', romanization: 'kk', index: 2),
    HangeulCharacter(char: 'ㄳ', romanization: 'ks', index: 3),
    HangeulCharacter(char: 'ㄴ', romanization: 'n', index: 4),
    HangeulCharacter(char: 'ㄵ', romanization: 'nj', index: 5),
    HangeulCharacter(char: 'ㄶ', romanization: 'nh', index: 6),
    HangeulCharacter(char: 'ㄷ', romanization: 't', index: 7),
    HangeulCharacter(char: 'ㄹ', romanization: 'l', index: 8),
    HangeulCharacter(char: 'ㄺ', romanization: 'lg', index: 9),
    HangeulCharacter(char: 'ㄻ', romanization: 'lm', index: 10),
    HangeulCharacter(char: 'ㄼ', romanization: 'lb', index: 11),
    HangeulCharacter(char: 'ㄽ', romanization: 'ls', index: 12),
    HangeulCharacter(char: 'ㄾ', romanization: 'lt', index: 13),
    HangeulCharacter(char: 'ㄿ', romanization: 'lp', index: 14),
    HangeulCharacter(char: 'ㅀ', romanization: 'lh', index: 15),
    HangeulCharacter(char: 'ㅁ', romanization: 'm', index: 16),
    HangeulCharacter(char: 'ㅂ', romanization: 'p', index: 17),
    HangeulCharacter(char: 'ㅄ', romanization: 'ps', index: 18),
    HangeulCharacter(char: 'ㅅ', romanization: 't', index: 19),
    HangeulCharacter(char: 'ㅆ', romanization: 't', index: 20),
    HangeulCharacter(char: 'ㅇ', romanization: 'ng', index: 21),
    HangeulCharacter(char: 'ㅈ', romanization: 't', index: 22),
    HangeulCharacter(char: 'ㅊ', romanization: 't', index: 23),
    HangeulCharacter(char: 'ㅋ', romanization: 'k', index: 24),
    HangeulCharacter(char: 'ㅌ', romanization: 't', index: 25),
    HangeulCharacter(char: 'ㅍ', romanization: 'p', index: 26),
    HangeulCharacter(char: 'ㅎ', romanization: 't', index: 27),
  ];
}
