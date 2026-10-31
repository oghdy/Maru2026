import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// The small chime for a right answer in a lesson.
///
/// It has its own player, so it mixes with a word being read aloud (TtsHelper) instead of
/// cutting it off, and TTS starting never cuts the chime. A sound is a nicety: every failure
/// here (no plugin in tests, a blocked play on the web) stays quiet and the lesson goes on.
class LessonSounds {
  LessonSounds._();

  static const _correctAsset = 'assets/sounds/correct.wav';
  static const _volume = 0.5;

  static AudioPlayer? _player;
  static bool _ready = false;
  static int _holders = 0;

  /// Replaces real playback in widget tests.
  @visibleForTesting
  static VoidCallback? onCorrectForTest;

  /// A lesson screen opened: load now so the first chime has no delay.
  /// Counted because the next lesson's screen opens before the last one is gone.
  static void hold() {
    _holders++;
    if (onCorrectForTest == null) _load();
  }

  /// A lesson screen closed. The last one frees the player.
  static void release() {
    if (--_holders > 0) return;
    _holders = 0;
    final player = _player;
    _player = null;
    _ready = false;
    if (player != null) _quiet(player.dispose());
  }

  /// Call straight from the tap handler: browsers only allow sound right after a tap.
  static void playCorrect() {
    final hook = onCorrectForTest;
    if (hook != null) return hook();

    final player = _player;
    if (player == null || !_ready) {
      // Not loaded: load for the next answer. A chime arriving late would be worse than none.
      _load();
      return;
    }
    try {
      if (player.playing) {
        _quiet(player.seek(Duration.zero));
      } else {
        // If the browser refuses, drop the "playing" flag so the next answer can try again.
        unawaited(player.play().catchError((Object e) {
          debugPrint('LessonSounds: could not play ($e)');
          _quiet(player.pause());
        }));
      }
    } catch (e) {
      debugPrint('LessonSounds: could not play ($e)');
    }
  }

  static void _load() {
    if (_player != null) return;
    try {
      // No audio-session handling: the chime must not pause TTS or take audio focus.
      final player = AudioPlayer(handleInterruptions: false, handleAudioSessionActivation: false);
      _player = player;
      _quiet(player.setVolume(_volume));
      // Stops at the end and rewinds, so the next play() starts right away.
      player.processingStateStream.listen(
        (state) {
          if (state != ProcessingState.completed) return;
          _quiet(player.pause());
          _quiet(player.seek(Duration.zero));
        },
        onError: (Object e) => debugPrint('LessonSounds: player error ($e)'),
      );
      player.setAsset(_correctAsset).then((_) {
        if (identical(player, _player)) _ready = true;
      }).catchError((Object e) {
        debugPrint('LessonSounds: could not load the chime ($e)');
        // Forget the player so the next answer tries again.
        if (identical(player, _player)) {
          _player = null;
          _quiet(player.dispose());
        }
      });
    } catch (e) {
      debugPrint('LessonSounds: no audio player ($e)');
      _player = null;
    }
  }

  static void _quiet(Future<void> future) {
    unawaited(future.catchError((Object e) => debugPrint('LessonSounds: $e')));
  }
}
