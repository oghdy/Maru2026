import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Helper class for Text-to-Speech functionality across the app
class TtsHelper {
  static final TtsHelper _instance = TtsHelper._internal();
  factory TtsHelper() => _instance;

  FlutterTts? _flutterTts;
  bool _isInitialized = false;

  TtsHelper._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();
    
    // Configure TTS settings
    await _flutterTts?.setLanguage("ko-KR");
    await _flutterTts?.setSpeechRate(0.4); // Slightly slower for learning
    await _flutterTts?.setVolume(1.0);
    await _flutterTts?.setPitch(1.0);
    
    // iOS specific settings
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _flutterTts?.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ],
      );
    }

    _flutterTts?.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
    });

    _isInitialized = true;
    debugPrint("✅ TTS Initialized");
  }

  /// Speak the provided text
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    debugPrint("🔊 Speaking: $text");
    await _flutterTts?.stop(); // Stop any current speech
    await _flutterTts?.speak(text);
  }

  /// Stop speaking
  Future<void> stop() async {
    await _flutterTts?.stop();
  }
}

