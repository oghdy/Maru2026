import 'dart:math' as math;

import 'package:flutter/animation.dart';

import 'character_pose.dart';
import 'character_types.dart';

/// Time-dependent inputs for the looping layer.
class LoopClock {
  const LoopClock({
    required this.breathPhase,
    required this.talkPhase,
    required this.sinceMood,
    required this.afterEntry,
  });

  /// Breathing cycles elapsed (fractional part is the position in the cycle).
  final double breathPhase;

  /// Talking bobs elapsed (rate jittered per cycle by the widget).
  final double talkPhase;

  /// Seconds since the current loop mood started.
  final double sinceMood;

  /// Seconds since the entry reaction ended (negative while it is still playing).
  final double afterEntry;
}

/// Personality expressed as timing — every number from CHARACTER_API §2.2/§2.3 lives here.
/// 🐰 fast, big, bouncy. 🐢 slow, small, soft.
class CharacterMotion {
  const CharacterMotion._({
    required this.kind,
    required this.breathAmp,
    required this.breathPeriod,
    required this.blinkMin,
    required this.blinkMax,
    required this.doubleBlinkChance,
    required this.fidgetMin,
    required this.fidgetMax,
    required this.maxLift,
    required this.sadSwayPeriod,
    required this.thinkTilt,
    required this.thinkSway,
    required this.thinkPeriod,
    required this.talkHz,
    required this.happyHopPeriod,
    required this.happyHopLift,
    required this.cheerHopPeriod,
    required this.cheerHopLift,
    required this.settle,
  });

  static CharacterMotion of(MaruCharacterKind kind) =>
      kind == MaruCharacterKind.rabbit ? rabbit : turtle;

  static const rabbit = CharacterMotion._(
    kind: MaruCharacterKind.rabbit,
    breathAmp: 0.025,
    breathPeriod: 1.8,
    blinkMin: 2.0,
    blinkMax: 4.5,
    doubleBlinkChance: 0.25,
    fidgetMin: 5,
    fidgetMax: 9,
    maxLift: 0.25,
    sadSwayPeriod: 2.4,
    thinkTilt: 6,
    thinkSway: 4,
    thinkPeriod: 1.4,
    talkHz: 5,
    happyHopPeriod: 1.6,
    happyHopLift: 0.03,
    cheerHopPeriod: 2.2,
    cheerHopLift: 0.08,
    settle: Curves.elasticOut,
  );

  static const turtle = CharacterMotion._(
    kind: MaruCharacterKind.turtle,
    breathAmp: 0.020,
    breathPeriod: 3.0,
    blinkMin: 3.5,
    blinkMax: 6.5,
    doubleBlinkChance: 0,
    fidgetMin: 8,
    fidgetMax: 12,
    maxLift: 0.12,
    sadSwayPeriod: 3.2,
    thinkTilt: 4,
    thinkSway: 3,
    thinkPeriod: 2.2,
    talkHz: 3.5,
    happyHopPeriod: 0,
    happyHopLift: 0,
    cheerHopPeriod: 3.0,
    cheerHopLift: 0.04,
    // Softer spring than the rabbit: fewer, gentler wobbles.
    settle: ElasticOutCurve(0.55),
  );

  final MaruCharacterKind kind;
  final double breathAmp;
  final double breathPeriod;
  final double blinkMin;
  final double blinkMax;
  final double doubleBlinkChance;
  final double fidgetMin;
  final double fidgetMax;

  /// Highest jump (cheer) — the shadow shrinks relative to this.
  final double maxLift;
  final double sadSwayPeriod;
  final double thinkTilt;
  final double thinkSway;
  final double thinkPeriod;
  final double talkHz;
  final double happyHopPeriod;
  final double happyHopLift;
  final double cheerHopPeriod;
  final double cheerHopLift;
  final Curve settle;

  bool get isRabbit => kind == MaruCharacterKind.rabbit;

  // magic (v1.2) — 🐢 slower and smaller.
  /// Entry spin (360° round the body centre), seconds.
  double get magicSpin => isRabbit ? 0.52 : 0.80;

  /// Loop mini-transform: spin length and how often it repeats, seconds.
  double get miniSpin => isRabbit ? 0.45 : 0.70;
  double get magicLoopPeriod => isRabbit ? 3.2 : 4.0;
  double get magicSwayDeg => isRabbit ? 4 : 3;
  double get magicSwayPeriod => isRabbit ? 1.6 : 2.2;

  /// Wand twinkle interval range, seconds.
  (double, double) get wandTwinkle => isRabbit ? (1.8, 2.6) : (2.4, 3.4);

  /// Where sparkles come from, in size units of the box: the wand star in
  /// rabbit_magic.png (measured ≈ (0.21, 0.41), left of the face), above the head
  /// for the turtle (no wand image).
  Offset get wandTip => isRabbit ? const Offset(0.21, 0.40) : const Offset(0.50, 0.12);

  /// Breathing speed multiplier per mood (happy = quicker, sad = slower).
  double breathRate(MaruMood mood) => switch (mood) {
        MaruMood.happy || MaruMood.cheer => 1 / 0.8,
        MaruMood.sad => 1 / 1.4,
        _ => 1.0,
      };

  // ---------------------------------------------------------------- loops

  CharacterPose loopPose(MaruMood mood, LoopClock c) {
    // easeInOutSine-shaped 0→1→0 breath; volume preserving (x shrinks half as much).
    final b = 0.5 - 0.5 * math.cos(2 * math.pi * c.breathPhase);
    var pose = CharacterPose(sy: breathAmp * b, sx: -breathAmp / 2 * b);

    switch (mood) {
      case MaruMood.idle:
        break;
      case MaruMood.happy:
        if (happyHopPeriod > 0 && c.afterEntry > 0) {
          pose += _periodicHop(c.afterEntry, happyHopPeriod, 0.36, happyHopLift);
        }
      case MaruMood.sad:
        pose += CharacterPose(
          lift: -0.03,
          sy: -0.04,
          rot: deg(2) * math.sin(2 * math.pi * c.sinceMood / sadSwayPeriod),
        );
      case MaruMood.thinking:
        final w = 2 * math.pi * c.sinceMood / thinkPeriod;
        pose += CharacterPose(
          rot: deg(thinkTilt) + deg(thinkSway / 2) * math.sin(w),
          lift: 0.005 - 0.005 * math.cos(2 * w),
        );
      case MaruMood.talking:
        final s = math.sin(math.pi * c.talkPhase).abs();
        pose += CharacterPose(lift: 0.015 * s, sy: 0.03 * s, sx: -0.012 * s);
      case MaruMood.cheer:
        if (c.afterEntry > 0) {
          pose += _periodicHop(c.afterEntry, cheerHopPeriod, isRabbit ? 0.45 : 0.55, cheerHopLift);
        }
      case MaruMood.magic:
        // Slow "casting" sway + gentle float. The 360° mini-transform every
        // [magicLoopPeriod] is a spin around the body centre, driven by the widget.
        final w = 2 * math.pi * c.sinceMood / magicSwayPeriod;
        pose += CharacterPose(rot: deg(magicSwayDeg) * math.sin(w), lift: 0.01 - 0.01 * math.cos(w));
    }
    return pose;
  }

  /// A small hop that fires at the start of every [period]:
  /// crouch → parabolic flight with stretch → landing squash.
  /// The first hop comes 0.6·period after the entry reaction (a beat of rest after landing).
  CharacterPose _periodicHop(double t, double period, double dur, double h) {
    final u = ((t + period * 0.4) % period) / dur;
    if (u >= 1) return CharacterPose.zero;
    final s = h * 1.2; // squash amount scales with hop height
    if (u < 0.18) {
      final p = math.sin(math.pi * u / 0.18);
      return CharacterPose(sy: -s * p, sx: s * 0.7 * p);
    }
    if (u < 0.82) {
      final a = (u - 0.18) / 0.64;
      return CharacterPose(lift: h * 4 * a * (1 - a), sy: s * 0.5 * math.sin(math.pi * a));
    }
    final p = math.sin(math.pi * (u - 0.82) / 0.18);
    return CharacterPose(sy: -s * 0.8 * p, sx: s * 0.6 * p);
  }

  // ---------------------------------------------------------- reactions

  /// Entry reaction for a mood. Tracks without a jump just ease the carried-over
  /// pose into the new loop (that *is* the sad sink / thinking tilt / idle return).
  PoseTrack entry(MaruMood mood, math.Random rnd) {
    final r = isRabbit;
    switch (mood) {
      case MaruMood.idle:
        return const PoseTrack([PoseKey(CharacterPose.zero, 400, Curves.easeOut)]);
      case MaruMood.sad:
        return PoseTrack([PoseKey(CharacterPose.zero, r ? 450 : 700, Curves.easeOutCubic)]);
      case MaruMood.thinking:
        return PoseTrack([PoseKey(CharacterPose.zero, r ? 300 : 500, Curves.easeOutBack)]);
      case MaruMood.talking:
        return const PoseTrack([
          PoseKey(CharacterPose(lift: 0.02, sy: 0.02, sx: -0.01), 60, Curves.easeOut),
          PoseKey(CharacterPose.zero, 90, Curves.easeIn),
        ]);
      case MaruMood.happy:
        const crouch = CharacterPose(sy: -0.08, sx: 0.06);
        const land = CharacterPose(sy: -0.06, sx: 0.05);
        if (!r) {
          return PoseTrack([
            const PoseKey(crouch, 80, Curves.easeOut),
            const PoseKey(CharacterPose(lift: 0.06, sy: 0.03, sx: -0.02), 210, Curves.easeOutCubic),
            const PoseKey(CharacterPose.zero, 210, Curves.easeInCubic),
            const PoseKey(land, 70, Curves.easeOut),
            PoseKey(CharacterPose.zero, 550, settle),
          ]);
        }
        final side = rnd.nextBool() ? 1.0 : -1.0;
        return PoseTrack([
          const PoseKey(crouch, 80, Curves.easeOut),
          PoseKey(CharacterPose(lift: 0.12, sy: 0.04, sx: -0.03, rot: deg(3) * side), 160, Curves.easeOutCubic),
          const PoseKey(CharacterPose.zero, 160, Curves.easeInCubic),
          const PoseKey(land, 60, Curves.easeOut),
          PoseKey(CharacterPose(lift: 0.12, sy: 0.04, sx: -0.03, rot: -deg(3) * side), 160, Curves.easeOutCubic),
          const PoseKey(CharacterPose.zero, 160, Curves.easeInCubic),
          const PoseKey(land, 60, Curves.easeOut),
          PoseKey(CharacterPose.zero, 450, settle),
        ]);
      case MaruMood.cheer:
        if (!r) {
          return PoseTrack([
            const PoseKey(CharacterPose(sy: -0.12, sx: 0.08), 150, Curves.easeOut),
            const PoseKey(CharacterPose(lift: 0.12, sy: 0.05, sx: -0.03), 300, Curves.easeOutCubic),
            const PoseKey(CharacterPose.zero, 300, Curves.easeInCubic),
            const PoseKey(CharacterPose(sy: -0.10, sx: 0.08), 90, Curves.easeOut),
            PoseKey(CharacterPose.zero, 500, settle),
          ], events: const {TrackEvent.burst: 450});
        }
        final spin = deg(8) * (rnd.nextBool() ? 1 : -1);
        return PoseTrack([
          const PoseKey(CharacterPose(sy: -0.15, sx: 0.10), 120, Curves.easeOut),
          PoseKey(CharacterPose(lift: 0.25, sy: 0.08, sx: -0.06, rot: spin), 240, Curves.easeOutCubic),
          const PoseKey(CharacterPose(sy: 0.02), 240, Curves.easeInCubic),
          const PoseKey(CharacterPose(sy: -0.12, sx: 0.10), 80, Curves.easeOut),
          PoseKey(CharacterPose.zero, 500, settle),
        ], events: const {TrackEvent.burst: 360});
      case MaruMood.magic:
        // Crouch → small hop while spinning 360° round the body centre (spin channel,
        // easeInOutCubic over [magicSpin]) → landing squash → scale pulse 1→1.12→1
        // with a smoke "poof" + wand sparkles.
        final crouch = r ? 120 : 160;
        final air = (magicSpin * 1000 / 2).round();
        return PoseTrack([
          PoseKey(const CharacterPose(sy: -0.10, sx: 0.06), crouch, Curves.easeOut),
          PoseKey(CharacterPose(lift: r ? 0.10 : 0.06, sy: 0.03, sx: -0.02), air, Curves.easeOutCubic),
          PoseKey(CharacterPose.zero, air, Curves.easeInCubic),
          PoseKey(const CharacterPose(sy: -0.08, sx: 0.06), r ? 80 : 100, Curves.easeOut),
          PoseKey(const CharacterPose(sy: 0.12, sx: 0.12), r ? 150 : 200, Curves.easeOutCubic),
          PoseKey(CharacterPose.zero, r ? 150 : 200, Curves.easeInOutSine),
        ], events: {TrackEvent.spin: crouch, TrackEvent.poof: crouch + air * 2});
    }
  }

  PoseTrack tap(math.Random rnd) {
    const squash = CharacterPose(sy: -0.10, sx: 0.08);
    if (isRabbit) {
      return PoseTrack([
        const PoseKey(squash, 90, Curves.easeOut),
        const PoseKey(CharacterPose(lift: 0.06, sy: 0.03, sx: -0.02), 130, Curves.easeOutCubic),
        const PoseKey(CharacterPose.zero, 130, Curves.easeInCubic),
        const PoseKey(CharacterPose(sy: -0.05, sx: 0.04), 50, Curves.easeOut),
        PoseKey(CharacterPose.zero, 450, settle),
      ]);
    }
    final side = rnd.nextBool() ? 1.0 : -1.0;
    return PoseTrack([
      const PoseKey(squash, 90, Curves.easeOut),
      PoseKey(CharacterPose(rot: deg(4) * side), 200, Curves.easeOut),
      PoseKey(CharacterPose.zero, 450, settle),
    ]);
  }

  /// Idle-only fidget so a character left alone never looks frozen.
  PoseTrack fidget(math.Random rnd) {
    final side = rnd.nextBool() ? 1.0 : -1.0;
    if (!isRabbit) {
      final tilt = CharacterPose(rot: deg(3) * side);
      return PoseTrack([
        PoseKey(tilt, 350, Curves.easeInOutSine),
        PoseKey(tilt, 200, Curves.linear),
        const PoseKey(CharacterPose.zero, 350, Curves.easeInOutSine),
      ]);
    }
    if (rnd.nextBool()) {
      return PoseTrack([
        const PoseKey(CharacterPose(sy: -0.05, sx: 0.04), 50, Curves.easeOut),
        const PoseKey(CharacterPose(lift: 0.04, sy: 0.02), 115, Curves.easeOutCubic),
        const PoseKey(CharacterPose.zero, 115, Curves.easeInCubic),
        const PoseKey(CharacterPose(sy: -0.03, sx: 0.02), 40, Curves.easeOut),
        PoseKey(CharacterPose.zero, 300, settle),
      ]);
    }
    final tilt = CharacterPose(rot: deg(5) * side);
    return PoseTrack([
      PoseKey(tilt, 180, Curves.easeOutCubic),
      PoseKey(tilt, 250, Curves.linear),
      PoseKey(CharacterPose.zero, 500, settle),
    ]);
  }
}
