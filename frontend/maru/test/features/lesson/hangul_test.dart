import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lesson/utils/hangul.dart';

void main() {
  test('kind', () {
    expect(hangulKind('ㅏ'), HangulKind.vowel);
    expect(hangulKind('ㄱ'), HangulKind.consonant);
    expect(hangulKind('가'), HangulKind.syllable);
    expect(hangulKind('한글'), HangulKind.word);
    expect(hangulKind('a'), HangulKind.other);
  });

  test('decompose syllables', () {
    expect(decomposeSyllable('가')!.letters, ['ㄱ', 'ㅏ']);
    expect(decomposeSyllable('닭')!.letters, ['ㄷ', 'ㅏ', 'ㄺ']);
    expect(decomposeSyllable('값')!.finalConsonant, 'ㅄ');
    expect(decomposeSyllable('꽃')!.letters, ['ㄲ', 'ㅗ', 'ㅊ']);
    expect(decomposeSyllable('ㄱ'), isNull);
  });

  test('compose', () {
    expect(withVowelA('ㄱ'), '가');
    expect(withVowelA('ㅎ'), '하');
    expect(withSilentO('ㅏ'), '아');
    expect(withSilentO('ㅘ'), '와');
    expect(combinedFrom('ㅘ'), ['ㅗ', 'ㅏ']);
    expect(combinedFrom('ㅏ'), isNull);
  });
}
