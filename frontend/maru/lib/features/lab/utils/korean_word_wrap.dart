import 'package:flutter/widgets.dart'; // re-exports String.characters

/// Display-only copy of [text] that wraps Korean between words (어절), not between syllables.
///
/// Flutter breaks Hangul at any syllable ("안 마 / 셨어요"). Like MaruCharacterBubble, a WORD
/// JOINER (U+2060) is inserted between adjacent Hangul characters so lines break only at spaces.
/// Use the original text for copy / TTS — never this one.
String koreanKeepAll(String text) {
  final chars = text.characters.toList();
  bool hangul(String c) {
    final r = c.runes.first;
    return (r >= 0xAC00 && r <= 0xD7A3) || (r >= 0x3130 && r <= 0x318F);
  }

  final out = StringBuffer();
  for (var i = 0; i < chars.length; i++) {
    out.write(chars[i]);
    if (i + 1 < chars.length && hangul(chars[i]) && hangul(chars[i + 1])) out.write('⁠');
  }
  return out.toString();
}
