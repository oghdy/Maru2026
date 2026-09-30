import 'package:flutter_test/flutter_test.dart';
import 'package:maru/features/lab/utils/korean_word_wrap.dart';

void main() {
  test('joins syllables inside a word, keeps spaces and punctuation', () {
    final out = koreanKeepAll('안 마셨어요.');
    expect(out, '안 마⁠셨⁠어⁠요.');
    expect(out.replaceAll('⁠', ''), '안 마셨어요.');
  });

  test('leaves non-Korean text unchanged', () {
    expect(koreanKeepAll('hello world'), 'hello world');
  });
}
