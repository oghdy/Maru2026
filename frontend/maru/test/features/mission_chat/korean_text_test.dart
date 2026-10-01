import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/mission_chat/models/korean_text.dart';

void main() {
  group('cleanKoreanText (MSN-1.7.4)', () {
    test('filler + conjoining vowel becomes compatibility jamo', () {
      expect(cleanKoreanText("'주세요ᅟᅭ'에서 'ᅟᅭ'는"), "'주세요ㅛ'에서 'ㅛ'는");
    });
    test('lone conjoining jamo become compatibility jamo', () {
      expect(cleanKoreanText('ᄀ ᅭ ᆫ'), 'ㄱ ㅛ ㄴ');
    });
    test('conjoining sequences compose into syllables', () {
      expect(cleanKoreanText('한글'), '한글');
    });
    test('halfwidth jamo map to compatibility jamo', () {
      expect(cleanKoreanText('요ￒ ﾡ'), '요ㅛ ㄱ');
    });
    test('fillers and zero-width marks are removed', () {
      expect(cleanKoreanText('주⁠세​요﻿ㅤᅠ'), '주세요');
    });
    test('ordinary mixed text is unchanged', () {
      const s = "The final 'ㅛ' in '주세요ㅛ' is unnecessary. 'ㅛ'는 불필요해요!";
      expect(cleanKoreanText(s), s);
    });
    test('cleanAiText treats "null" and blanks as missing', () {
      expect(cleanAiText('null'), isNull);
      expect(cleanAiText('  '), isNull);
      expect(cleanAiText(null), isNull);
      expect(cleanAiText(' 네 '), '네');
    });
  });
}
