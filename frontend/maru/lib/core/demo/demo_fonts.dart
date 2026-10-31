import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Korean letters and emoji this app shows most, so the fonts that hold them are ready for the first screen.
/// The Flutter web engine downloads fallback fonts only when a character is first drawn and shows an empty box
/// until the download ends. Korean comes in many small font files, so this list is short on purpose:
/// a character that is missing here still appears, it just shows the box for a moment.
const _preloadSample =
    // Consonants and vowels (lessons, Hangul Lab)
    'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ'
    // Frequent syllables in the lessons and in the app's Korean text
    '요는저다를이을예민수사니에입아은유미하생커피의좋빵세학가해름안녕제어물마카밖꽃값닭바먹셔반갑습선님무슨일씨각까간앉과타말밤강없회원나고파따잎곧낮앞싫뭐책도라거차한글구기빠싸자짜양'
    '문정시동교식장부감밥지침존댓쇼핑경족인작상태육날연직업신체음숫량소뛰매'
    // Only the emoji on the home screen. Emoji and symbol font files are 130-370 KB each (Korean ones about 9 KB),
    // so the other emoji load when they are first drawn.
    '👋';

/// Asks the engine for the fonts of [_preloadSample] and waits until they arrive, at most [timeout].
/// Runs before the first frame, so the loading screen in web/index.html stays up meanwhile.
Future<void> preloadDemoFonts({Duration timeout = const Duration(seconds: 4)}) async {
  final fontsArrived = Completer<void>();
  void onFontsChanged() {
    if (!fontsArrived.isCompleted) fontsArrived.complete();
  }

  final systemFonts = PaintingBinding.instance.systemFonts;
  systemFonts.addListener(onFontsChanged);
  try {
    // Laying out text is what makes the engine look for the missing fonts.
    TextPainter(
      text: const TextSpan(text: _preloadSample),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..dispose();
    await fontsArrived.future.timeout(timeout);
  } catch (e) {
    // Never keep the app from starting because of a font.
    debugPrint('Font preload stopped early: ${e.runtimeType}');
  } finally {
    systemFonts.removeListener(onFontsChanged);
  }
}
