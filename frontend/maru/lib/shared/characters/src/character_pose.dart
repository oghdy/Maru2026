import 'dart:math' as math;

import 'package:flutter/animation.dart';

double deg(double degrees) => degrees * math.pi / 180;

/// Additive body transform, all relative to the character's size.
///
/// [lift] is height above the floor as a fraction of size (+ = up),
/// [rot] is radians around the feet, [sx]/[sy] are deltas from scale 1.0.
class CharacterPose {
  const CharacterPose({this.lift = 0, this.rot = 0, this.sx = 0, this.sy = 0});

  static const zero = CharacterPose();

  final double lift;
  final double rot;
  final double sx;
  final double sy;

  CharacterPose operator +(CharacterPose o) =>
      CharacterPose(lift: lift + o.lift, rot: rot + o.rot, sx: sx + o.sx, sy: sy + o.sy);

  CharacterPose operator -(CharacterPose o) =>
      CharacterPose(lift: lift - o.lift, rot: rot - o.rot, sx: sx - o.sx, sy: sy - o.sy);

  CharacterPose operator *(double k) =>
      CharacterPose(lift: lift * k, rot: rot * k, sx: sx * k, sy: sy * k);

  /// Unclamped so overshooting curves (elasticOut, easeOutBack) work.
  static CharacterPose lerp(CharacterPose a, CharacterPose b, double t) => a + (b - a) * t;

  @override
  String toString() =>
      'Pose(lift ${lift.toStringAsFixed(3)}, rot ${(rot * 180 / math.pi).toStringAsFixed(1)}°, '
      'sx ${sx.toStringAsFixed(3)}, sy ${sy.toStringAsFixed(3)})';
}

/// One keyframe: move to [pose] over [ms] using [curve].
class PoseKey {
  const PoseKey(this.pose, this.ms, [this.curve = Curves.easeInOut]);

  final CharacterPose pose;
  final int ms;
  final Curve curve;
}

/// Something that should happen at a point in a track.
/// burst = cheer confetti at the jump apex; spin = start a 360° turn around the body
/// centre (magic); poof = magic smoke + wand sparkles on landing.
enum TrackEvent { burst, spin, poof }

/// A one-shot reaction. It always starts from whatever pose the character is in
/// right now (passed to [eval]) and should end at [CharacterPose.zero], so
/// reactions can interrupt each other without snapping.
class PoseTrack {
  const PoseTrack(this.keys, {this.events = const {}});

  final List<PoseKey> keys;
  final Map<TrackEvent, int> events;

  int get totalMs => keys.fold(0, (sum, k) => sum + k.ms);

  CharacterPose eval(CharacterPose start, double ms) {
    var from = start;
    var t = ms;
    for (final k in keys) {
      if (t < k.ms) {
        return CharacterPose.lerp(from, k.pose, k.curve.transform((t / k.ms).clamp(0.0, 1.0)));
      }
      t -= k.ms;
      from = k.pose;
    }
    return from;
  }
}
