import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'character_assets.dart';
import 'character_motion.dart';
import 'character_pose.dart';
import 'character_types.dart';
import 'particles.dart';
import 'placeholder_painter.dart';

/// Rabbit / turtle mascot that breathes, blinks, fidgets and reacts to [mood]
/// changes. See CHARACTER_API §1–§2.
class MaruCharacter extends StatefulWidget {
  const MaruCharacter({
    super.key,
    required this.kind,
    this.mood = MaruMood.idle,
    this.size = 120,
    this.reactionKey,
    this.settleToIdleAfter,
    this.entrance = false,
    this.interactive = true,
    this.onTap,
    this.semanticLabel,
  });

  final MaruCharacterKind kind;
  final MaruMood mood;

  /// Side of the square the character occupies in layout. Jumps may draw outside it.
  final double size;

  /// Change it to replay the mood's entry reaction even when [mood] is unchanged.
  final Object? reactionKey;

  /// After the entry reaction, wait this long and then return the face/loop to idle.
  final Duration? settleToIdleAfter;

  /// Pop in (0 → 1.08 → 1.0) the first time it appears.
  final bool entrance;
  final bool interactive;
  final VoidCallback? onTap;

  /// Null = decorative (excluded from semantics).
  final String? semanticLabel;

  /// Sizes at or below this are "compact": half amplitude, no particles.
  static const compactSize = 56.0;

  /// Warm the image cache for [kind] before a screen shows it. Missing files are ignored.
  static Future<void> precache(BuildContext context, MaruCharacterKind kind) =>
      CharacterAssets.precache(context, kind);

  @override
  State<MaruCharacter> createState() => _MaruCharacterState();
}

class _FrameNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

class _MaruCharacterState extends State<MaruCharacter> with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);

  /// Body + shadow stay invisible until the face has painted once (R-004: no
  /// "shadow with an empty body" while a PNG decodes), then fade in.
  late final AnimationController _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  bool _revealed = false;
  final _frame = _FrameNotifier();
  final _blink = ValueNotifier(false);
  final _rnd = math.Random();

  late CharacterMotion _motion;
  bool _reduceMotion = false;

  // Clock (seconds). Advanced only by the ticker, so there are no Timers to leak.
  double _t = 0;
  Duration _lastElapsed = Duration.zero;
  late double _breathPhase = _rnd.nextDouble(); // desync characters on one screen
  double _talkPhase = 0;
  double _talkRate = 1;

  // Mood / reaction state.
  late MaruMood _loopMood;
  double _moodStartT = 0;
  double _entryEndT = 0;
  double? _settleAtT;
  PoseTrack? _track;
  double _trackStartT = 0;
  CharacterPose _trackFrom = CharacterPose.zero;
  final _firedEvents = <TrackEvent>{};

  double? _tapFaceUntil;
  late double _nextBlinkT;
  final List<(double, double)> _blinkWindows = [];
  late double _nextFidgetT;
  double? _entranceStartT;
  ParticleBurst? _burst;
  bool _burstPending = false;

  // Output of the last tick, read by the builders.
  CharacterPose _pose = CharacterPose.zero;
  double _entranceScale = 1;

  late MaruMood _face;
  bool _assetsReady = CharacterAssets.availableSync != null;

  bool get _compact => widget.size <= MaruCharacter.compactSize;

  @override
  void initState() {
    super.initState();
    _motion = CharacterMotion.of(widget.kind);
    _loopMood = widget.mood;
    _face = widget.mood;
    _scheduleIdleEvents(first: true);
    if (widget.entrance) _entranceScale = 0; // starts when the body is ready (_markBodyReady)
    if (widget.mood != MaruMood.idle) _enterMood(widget.mood, initial: true);

    if (!_assetsReady) {
      CharacterAssets.ensureLoaded().then((_) {
        if (mounted) setState(() => _assetsReady = true);
        _warmUp();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _warmUp());
    }
    CharacterAssets.changes.addListener(_onAssetsChanged);
  }

  void _onAssetsChanged() {
    if (CharacterAssets.availableSync == null) return;
    setState(() => _assetsReady = true);
    _warmUp();
  }

  void _warmUp() {
    if (mounted) CharacterAssets.warmUp(context);
  }

  /// Called from the face's first painted frame (image frameBuilder, or right away
  /// for the code placeholder). Cache hits appear instantly; fresh decodes fade in.
  void _markBodyReady({required bool instant}) {
    if (_revealed) return;
    _revealed = true;
    if (instant || _reduceMotion) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
    if (widget.entrance && !_reduceMotion) _entranceStartT = _t;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      if (reduce) {
        _track = null;
        _pose = CharacterPose.zero;
        _entranceStartT = null;
        _entranceScale = 1;
        if (_revealed) _reveal.value = 1;
        _blinkWindows.clear();
        _blink.value = false;
        _burst = null;
      }
    }
    _syncTicker();
  }

  @override
  void didUpdateWidget(MaruCharacter old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind) {
      _motion = CharacterMotion.of(widget.kind);
    }
    if (old.mood != widget.mood || old.reactionKey != widget.reactionKey) {
      _enterMood(widget.mood);
    } else if (old.settleToIdleAfter != widget.settleToIdleAfter && widget.settleToIdleAfter == null) {
      _settleAtT = null;
    }
    _syncTicker();
  }

  @override
  void dispose() {
    CharacterAssets.changes.removeListener(_onAssetsChanged);
    _ticker.dispose();
    _reveal.dispose();
    _frame.dispose();
    _blink.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ logic

  LoopClock get _clock => LoopClock(
        breathPhase: _breathPhase,
        talkPhase: _talkPhase,
        sinceMood: _t - _moodStartT,
        afterEntry: _t - _entryEndT,
      );

  CharacterPose _loopPose() => _motion.loopPose(_loopMood, _clock);

  CharacterPose _reactionPose() {
    final track = _track;
    if (track == null) return CharacterPose.zero;
    final ms = (_t - _trackStartT) * 1000;
    if (ms >= track.totalMs) {
      _track = null;
      return CharacterPose.zero;
    }
    return track.eval(_trackFrom, ms);
  }

  /// Start [track] from wherever the body is right now (no snapping), optionally
  /// switching the loop at the same instant — the track absorbs the difference.
  void _play(PoseTrack track, {MaruMood? loopMood}) {
    final current = _reduceMotion ? CharacterPose.zero : _loopPose() + _reactionPose();
    if (loopMood != null) {
      _loopMood = loopMood;
      _moodStartT = _t;
    }
    if (_reduceMotion) return;
    _track = track;
    _trackStartT = _t;
    _trackFrom = current - _loopPose();
    _firedEvents.clear();
  }

  void _enterMood(MaruMood mood, {bool initial = false}) {
    final track = _motion.entry(mood, _rnd);
    _play(track, loopMood: mood);
    _entryEndT = _t + (_reduceMotion ? 0 : track.totalMs / 1000);
    final settle = widget.settleToIdleAfter;
    _settleAtT = (settle != null && mood != MaruMood.idle)
        ? _entryEndT + settle.inMicroseconds / Duration.microsecondsPerSecond
        : null;
    if (mood == MaruMood.idle) _scheduleIdleEvents();
    // Called from initState/didUpdateWidget: a build follows anyway, so no setState.
    if (!initial) _updateFace(rebuild: false);
  }

  void _scheduleIdleEvents({bool first = false}) {
    _nextBlinkT = _t + (first ? 0.6 + _rnd.nextDouble() * _motion.blinkMax : _randBetween(_motion.blinkMin, _motion.blinkMax));
    _nextFidgetT = _t + _randBetween(_motion.fidgetMin, _motion.fidgetMax);
  }

  double _randBetween(double a, double b) => a + _rnd.nextDouble() * (b - a);

  MaruMood get _computedFace {
    final tap = _tapFaceUntil;
    if (tap != null && _t < tap) return MaruMood.happy;
    return _loopMood;
  }

  void _updateFace({bool rebuild = true}) {
    final f = _computedFace;
    if (f == _face) return;
    final wasIdle = _face == MaruMood.idle;
    if (rebuild && mounted) {
      setState(() => _face = f);
    } else {
      _face = f;
    }
    if (f != MaruMood.idle) {
      _blinkWindows.clear();
      _blink.value = false;
    } else if (!wasIdle) {
      _nextBlinkT = _t + _randBetween(0.8, _motion.blinkMin);
    }
  }

  bool get _hasPendingFaceEvent => _tapFaceUntil != null || _settleAtT != null;

  void _syncTicker() {
    final run = !_reduceMotion || _hasPendingFaceEvent;
    if (run && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _handleTap() {
    if (!widget.interactive) return;
    _tapFaceUntil = _t + 0.9;
    _play(_motion.tap(_rnd));
    _updateFace();
    _syncTicker();
    widget.onTap?.call();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _lastElapsed = elapsed;
    _t += dt;

    // Discrete events (also needed with reduced motion).
    final tap = _tapFaceUntil;
    if (tap != null && _t >= tap) _tapFaceUntil = null;
    final settleAt = _settleAtT;
    if (settleAt != null && _t >= settleAt) {
      _settleAtT = null;
      _play(_motion.entry(MaruMood.idle, _rnd), loopMood: MaruMood.idle);
      _entryEndT = _t;
      _scheduleIdleEvents();
    }
    _updateFace();

    if (_reduceMotion) {
      _syncTicker();
      return;
    }

    _breathPhase += dt / _motion.breathPeriod * _motion.breathRate(_loopMood);
    if (_loopMood == MaruMood.talking) {
      final before = _talkPhase.floor();
      _talkPhase += dt * _motion.talkHz * _talkRate;
      // ±20% jitter per bob so talking never looks mechanical.
      if (_talkPhase.floor() != before) _talkRate = 0.8 + _rnd.nextDouble() * 0.4;
    }

    _tickIdleLife();

    final reaction = _reactionPose();
    if (_track != null) _fireEvents();
    _pose = _loopPose() + reaction;

    // Cheer confetti: spawned at the jump apex just above the head; then it flies
    // in screen space (does not follow the body). None in compact mode.
    if (_burstPending) {
      _burstPending = false;
      if (!_compact) {
        _burst = ParticleBurst(
          // Just above the head (0.8·size above the feet pivot), following the body's tilt.
          origin: Offset(0.5 + 0.8 * math.sin(_pose.rot), 1.0 - _pose.lift - 0.8 * math.cos(_pose.rot)),
          startT: _t,
          primary: Theme.of(context).colorScheme.primary,
          rnd: _rnd,
        );
      }
    }
    if (_burst?.isDone(_t) ?? false) _burst = null;

    final es = _entranceStartT;
    if (es != null) {
      final ms = (_t - es) * 1000;
      _entranceScale = _entranceCurve(ms);
      if (ms >= 550) _entranceStartT = null;
    }

    _frame.tick();
  }

  void _tickIdleLife() {
    if (_face != MaruMood.idle) return;
    if (_t >= _nextBlinkT) {
      _blinkWindows
        ..clear()
        ..add((_t, _t + 0.12));
      var end = _t + 0.12;
      if (_rnd.nextDouble() < _motion.doubleBlinkChance) {
        _blinkWindows.add((_t + 0.24, _t + 0.36));
        end = _t + 0.36;
      }
      _nextBlinkT = end + _randBetween(_motion.blinkMin, _motion.blinkMax);
    }
    _blink.value = _blinkWindows.any((w) => _t >= w.$1 && _t < w.$2);

    if (_loopMood == MaruMood.idle && _t >= _nextFidgetT) {
      if (_track == null) {
        _play(_motion.fidget(_rnd));
        _nextFidgetT = _t + _randBetween(_motion.fidgetMin, _motion.fidgetMax);
      } else {
        _nextFidgetT = _t + 1;
      }
    }
  }

  void _fireEvents() {
    final ms = (_t - _trackStartT) * 1000;
    _track!.events.forEach((event, at) {
      if (ms >= at && _firedEvents.add(event) && event == TrackEvent.burst) _burstPending = true;
    });
  }

  /// 0 → 1.08 → 1.0 over 550ms.
  static double _entranceCurve(double ms) {
    if (ms <= 0) return 0;
    if (ms < 330) return 1.08 * Curves.easeOutCubic.transform(ms / 330);
    if (ms < 550) return 1.08 - 0.08 * Curves.easeInOutSine.transform((ms - 330) / 220);
    return 1;
  }

  // ------------------------------------------------------------------ build

  Matrix4 _matrix() {
    var p = _pose;
    if (_compact) p = p * 0.5;
    final s = widget.size;
    final e = _entranceScale;
    return Matrix4.translationValues(0, -p.lift * s, 0)
      ..multiply(Matrix4.rotationZ(p.rot))
      ..multiply(Matrix4.diagonal3Values((1 + p.sx) * e, (1 + p.sy) * e, 1));
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final scheme = Theme.of(context).colorScheme;

    Widget body = FadeTransition(
      opacity: _reveal,
      child: AnimatedBuilder(
      animation: _frame,
      builder: (context, child) => Transform(
        alignment: Alignment.bottomCenter,
        transform: _matrix(),
        child: child,
      ),
        child: _assetsReady ? _faceLayer(scheme) : const SizedBox.expand(),
      ),
    );

    Widget result = SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _ShadowPainter(
              repaint: Listenable.merge([_frame, _reveal]),
              pose: () => _compact ? _pose * 0.5 : _pose,
              maxLift: _motion.maxLift,
              entrance: () => _entranceScale.clamp(0.0, 1.0) * _reveal.value,
              color: scheme.onSurface,
            ),
          ),
          body,
          CustomPaint(
            painter: ParticlePainter(repaint: _frame, burst: () => _burst, now: () => _t),
          ),
        ],
      ),
    );

    if (widget.interactive) {
      result = GestureDetector(behavior: HitTestBehavior.opaque, onTap: _handleTap, child: result);
    }
    result = RepaintBoundary(child: result);

    final label = widget.semanticLabel;
    return label == null ? ExcludeSemantics(child: result) : Semantics(label: label, image: true, child: result);
  }

  Widget _faceLayer(ColorScheme scheme) {
    final face = _face;
    final path = CharacterAssets.face(widget.kind, face);
    final Widget child;
    if (path == null) {
      _markBodyReady(instant: true); // drawn synchronously
      child = CustomPaint(
        key: ValueKey('ph-${widget.kind.name}-${face.name}'),
        painter: CharacterPlaceholderPainter(
          kind: widget.kind,
          face: face,
          outline: Color.lerp(scheme.primary, Colors.black, 0.62)!,
          accent: scheme.primary,
          blink: face == MaruMood.idle ? _blink : null,
        ),
      );
    } else {
      final blinkPath = face == MaruMood.idle ? CharacterAssets.blink(widget.kind) : null;
      child = Stack(
        key: ValueKey('img-$path'),
        fit: StackFit.expand,
        children: [
          _image(path, scheme, reportsReady: true),
          if (blinkPath != null)
            ValueListenableBuilder<bool>(
              valueListenable: _blink,
              builder: (context, closed, child) => Opacity(opacity: closed ? 1 : 0, child: child),
              child: _image(blinkPath, scheme),
            ),
        ],
      );
    }
    return AnimatedSwitcher(
      duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }

  // No cacheWidth: one full-res (512px) cache entry per PNG, shared by every size,
  // so the warm-up precache and any earlier character make later ones cache hits.
  Widget _image(String path, ColorScheme scheme, {bool reportsReady = false}) => Image.asset(
        path,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        frameBuilder: reportsReady
            ? (context, child, frame, wasSynchronouslyLoaded) {
                if (frame != null) _markBodyReady(instant: wasSynchronouslyLoaded);
                return child;
              }
            : null,
        errorBuilder: (context, error, stack) {
          if (reportsReady) _markBodyReady(instant: true);
          return CustomPaint(
          painter: CharacterPlaceholderPainter(
            kind: widget.kind,
            face: _face,
            outline: Color.lerp(scheme.primary, Colors.black, 0.62)!,
            accent: scheme.primary,
          ),
        );
        },
      );
}

/// Floor shadow: shrinks and fades as the character rises.
class _ShadowPainter extends CustomPainter {
  _ShadowPainter({
    required Listenable repaint,
    required this.pose,
    required this.maxLift,
    required this.entrance,
    required this.color,
  }) : super(repaint: repaint);

  final CharacterPose Function() pose;
  final double Function() entrance;
  final double maxLift;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final h = pose().lift;
    final k = (1 - 0.5 * h / maxLift).clamp(0.35, 1.05);
    final e = entrance();
    if (e <= 0) return;
    final w = size.width * 0.55 * k;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.94),
      width: w,
      height: size.height * 0.07 * k,
    );
    canvas.drawOval(rect, Paint()..color = color.withValues(alpha: 0.10 * k.clamp(0.0, 1.0) * e));
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => old.color != color || old.maxLift != maxLift;
}
