class HangeulCombiner {
  /// Combine Initial (Cho), Vowel (Jung), and Final (Jong) into a single Unicode character.
  /// Unicode Base: 0xAC00 (가)
  /// Formula: 0xAC00 + (cho_index * 21 * 28) + (jung_index * 28) + jong_index
  static String combine(int choIndex, int jungIndex, int jongIndex) {
    if (choIndex < 0 || jungIndex < 0) return '';
    
    // Ensure bounds
    if (choIndex > 18 || jungIndex > 20 || jongIndex > 27) return '';

    int unicode = 0xAC00 + (choIndex * 21 * 28) + (jungIndex * 28) + (jongIndex > 0 ? jongIndex : 0);
    return String.fromCharCode(unicode);
  }
}
