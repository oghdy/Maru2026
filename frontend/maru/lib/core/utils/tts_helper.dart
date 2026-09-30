import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../storage/secure_storage.dart';

/// Korean text-to-speech for the whole app.
///
/// `TtsHelper.speak(text)` plays natural server audio from `GET /api/tts?text=`
/// (OpenAI TTS, cached on the server). If that fails or takes too long it falls
/// back to the device voice (flutter_tts, best available ko-KR voice).
/// Calling speak again stops whatever is playing and plays the new text.
class TtsHelper {
  TtsHelper._();

  static const _serverTimeout = Duration(seconds: 8);
  static const _maxCachedClips = 60;
  static const _maxTextLength = 200; // server limit

  static final AudioPlayer _player = AudioPlayer();
  static final FlutterTts _deviceTts = FlutterTts();
  static bool _deviceTtsReady = false;

  /// Downloaded mp3 bytes by text, so replays are instant and don't hit the server.
  static final Map<String, Uint8List> _clips = {};

  /// Increases on every speak/stop so a slow download never plays over newer audio.
  static int _generation = 0;

  static Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final generation = ++_generation;
    await _stopPlayback();

    try {
      final bytes = await _serverAudio(trimmed);
      if (generation != _generation) return; // a newer speak/stop happened
      await _player.setAudioSource(_BytesSource(bytes));
      if (generation != _generation) return;
      unawaited(_player.play());
    } catch (e) {
      debugPrint('TtsHelper: server audio unavailable, using device voice ($e)');
      if (generation != _generation) return;
      await _speakWithDevice(trimmed);
    }
  }

  /// Stops any audio (e.g. when leaving a screen).
  static Future<void> stop() async {
    _generation++;
    await _stopPlayback();
  }

  static Future<void> _stopPlayback() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _deviceTts.stop();
    } catch (_) {}
  }

  static Future<Uint8List> _serverAudio(String text) async {
    final cached = _clips[text];
    if (cached != null) return cached;
    if (text.length > _maxTextLength) {
      throw StateError('text longer than $_maxTextLength characters');
    }

    final token = await SecureStorage().getAccessToken();
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl(),
      connectTimeout: _serverTimeout,
      receiveTimeout: _serverTimeout,
      responseType: ResponseType.bytes,
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    ));
    final response = await dio.get<List<int>>('/api/tts', queryParameters: {'text': text});
    final data = response.data;
    if (data == null || data.isEmpty) throw StateError('empty audio');

    final bytes = Uint8List.fromList(data);
    if (_clips.length >= _maxCachedClips) _clips.remove(_clips.keys.first);
    _clips[text] = bytes;
    return bytes;
  }

  /// Same rule as core/network/dio_client.dart (dart-defines API_BASE_URL / API_PORT).
  static String _baseUrl() {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envBaseUrl.isNotEmpty) return envBaseUrl;
    const localPort = String.fromEnvironment('API_PORT', defaultValue: '8080');
    final localHost = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';
    return 'http://$localHost:$localPort';
  }

  static Future<void> _speakWithDevice(String text) async {
    if (!_deviceTtsReady) {
      await _deviceTts.setLanguage('ko-KR');
      await _deviceTts.setPitch(1.0);
      await _deviceTts.setSpeechRate(0.45); // a little slower for learners
      await _pickBestKoreanVoice();
      _deviceTtsReady = true;
    }
    await _deviceTts.speak(text);
  }

  /// Prefers an enhanced/premium ko-KR voice when the device has one installed.
  static Future<void> _pickBestKoreanVoice() async {
    try {
      final voices = await _deviceTts.getVoices;
      if (voices is! List) return;
      final korean = voices
          .whereType<Map>()
          .where((v) => '${v['locale']}'.toLowerCase().replaceAll('_', '-').startsWith('ko'))
          .toList();
      if (korean.isEmpty) return;
      int rank(Map v) {
        final text = '${v['name']} ${v['quality'] ?? ''} ${v['identifier'] ?? ''}'.toLowerCase();
        if (text.contains('premium')) return 0;
        if (text.contains('enhanced')) return 1;
        return 2;
      }
      korean.sort((a, b) => rank(a).compareTo(rank(b)));
      final best = korean.first;
      await _deviceTts.setVoice({'name': '${best['name']}', 'locale': '${best['locale']}'});
    } catch (e) {
      debugPrint('TtsHelper: could not choose a voice ($e)');
    }
  }
}

/// Plays in-memory mp3 bytes with just_audio.
class _BytesSource extends StreamAudioSource {
  final Uint8List _bytes;
  _BytesSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
