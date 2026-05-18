import 'package:flutter_tts/flutter_tts.dart';

class TtsHelper {
  static final FlutterTts _flutterTts = FlutterTts();

  static Future<void> speak(String text) async {
    await _flutterTts.setLanguage('ko-KR');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }
}
