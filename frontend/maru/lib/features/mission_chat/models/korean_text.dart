/// Cleans Korean text coming from the AI so every glyph renders on iOS.
///
/// The model sometimes writes a lone jamo the "Unicode-correct" way — a filler plus a
/// conjoining jamo (U+115F U+116D for ㅛ) — or uses halfwidth jamo / zero-width marks.
/// iOS fonts draw those as ▯ boxes (MSN-1.7.4, reproduced on iOS 18.5). This maps them to
/// precomposed syllables or compatibility jamo (ㄱ U+3131 … ㅣ U+3163), which always render.
String cleanKoreanText(String input) {
  final src = input.runes.toList();
  final out = StringBuffer();
  var i = 0;
  while (i < src.length) {
    final c = src[i];
    final next = i + 1 < src.length ? src[i + 1] : -1;

    // Leading consonant + vowel (+ trailing consonant) -> one precomposed syllable.
    if (_isLead(c) && _isVowel(next)) {
      var syllable = 0xAC00 + (c - 0x1100) * 588 + (next - 0x1161) * 28;
      i += 2;
      if (i < src.length && _isTail(src[i])) {
        syllable += src[i] - 0x11A7;
        i++;
      }
      out.writeCharCode(syllable);
      continue;
    }

    final mapped = _mapSingle(c); // null -> filler / zero-width mark: drop it
    if (mapped != null) out.writeCharCode(mapped);
    i++;
  }
  return out.toString();
}

bool _isLead(int c) => c >= 0x1100 && c <= 0x1112;
bool _isVowel(int c) => c >= 0x1161 && c <= 0x1175;
bool _isTail(int c) => c >= 0x11A8 && c <= 0x11C2;

bool _isDropped(int c) =>
    c == 0x115F || c == 0x1160 || c == 0x3164 || c == 0xFFA0 || // Hangul fillers
    (c >= 0x200B && c <= 0x200D) || c == 0x2060 || c == 0xFEFF; // zero-width marks

const _leadToCompat = [
  0x3131, 0x3132, 0x3134, 0x3137, 0x3138, 0x3139, 0x3141, 0x3142, 0x3143, 0x3145, //
  0x3146, 0x3147, 0x3148, 0x3149, 0x314A, 0x314B, 0x314C, 0x314D, 0x314E,
];
const _tailToCompat = [
  0x3131, 0x3132, 0x3133, 0x3134, 0x3135, 0x3136, 0x3137, 0x3139, 0x313A, 0x313B, //
  0x313C, 0x313D, 0x313E, 0x313F, 0x3140, 0x3141, 0x3142, 0x3144, 0x3145, 0x3146, //
  0x3147, 0x3148, 0x314A, 0x314B, 0x314C, 0x314D, 0x314E,
];

/// Returns the compatibility jamo for a lone conjoining / halfwidth jamo, `c` itself for
/// ordinary characters, or null for characters that should be dropped.
int? _mapSingle(int c) {
  if (_isDropped(c)) return null;
  if (_isLead(c)) return _leadToCompat[c - 0x1100];
  if (_isVowel(c)) return 0x314F + (c - 0x1161);
  if (_isTail(c)) return _tailToCompat[c - 0x11A8];
  // Halfwidth Hangul (U+FFA1–U+FFDC) -> compatibility jamo, as NFKC does.
  if (c >= 0xFFA1 && c <= 0xFFBE) return 0x3131 + (c - 0xFFA1);
  if (c >= 0xFFC2 && c <= 0xFFC7) return 0x314F + (c - 0xFFC2);
  if (c >= 0xFFCA && c <= 0xFFCF) return 0x3155 + (c - 0xFFCA);
  if (c >= 0xFFD2 && c <= 0xFFD7) return 0x315B + (c - 0xFFD2);
  if (c >= 0xFFDA && c <= 0xFFDC) return 0x3161 + (c - 0xFFDA);
  return c;
}

/// Null / blank / the string "null" -> null, otherwise the cleaned text.
String? cleanAiText(dynamic v) {
  if (v is! String) return null;
  final t = cleanKoreanText(v).trim();
  return t.isEmpty || t == 'null' ? null : t;
}
