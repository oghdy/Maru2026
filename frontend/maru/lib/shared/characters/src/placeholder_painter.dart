import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'character_pose.dart';
import 'character_types.dart';

/// Character palette for the code placeholder. Body colours are the characters'
/// identity (white rabbit / green turtle), so they are fixed; outline and props
/// are derived from the app's colorScheme.
class _Palette {
  static const fur = Color(0xFFFFFCF7);
  static const earInner = Color(0xFFFFC4D6);
  static const cheek = Color(0xFFFF9FBD);
  static const skin = Color(0xFF93D48E);
  static const shell = Color(0xFF3E9E86);
  static const shellLine = Color(0xFF2E7F6B);
  static const belly = Color(0xFFF4E8BC);
  static const tongue = Color(0xFFFF8FA3);
  static const gold = Color(0xFFFFC83D);
}

/// Draws a mascot in a 100×100 unit box, feet on y≈94.
///
/// [blink] (optional) closes the eyes while true — only passed for the idle face.
class CharacterPlaceholderPainter extends CustomPainter {
  CharacterPlaceholderPainter({
    required this.kind,
    required this.face,
    required this.outline,
    required this.accent,
    this.blink,
  }) : super(repaint: blink);

  final MaruCharacterKind kind;
  final MaruMood face;
  final Color outline;
  final Color accent;
  final ValueListenable<bool>? blink;

  late Paint _stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / 100;
    canvas.save();
    canvas.translate((size.width - 100 * k) / 2, (size.height - 100 * k) / 2);
    canvas.scale(k);
    _stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = outline
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    if (kind == MaruCharacterKind.rabbit) {
      _rabbit(canvas);
    } else {
      _turtle(canvas);
    }
    canvas.restore();
  }

  bool get _eyesClosed => blink?.value ?? false;

  // ------------------------------------------------------------- rabbit

  void _rabbit(Canvas c) {
    final (earL, earR) = switch (face) {
      MaruMood.happy => (-18.0, 18.0),
      MaruMood.cheer => (-24.0, 24.0),
      MaruMood.sad => (-105.0, 105.0),
      MaruMood.thinking => (-10.0, 42.0),
      MaruMood.talking => (-8.0, 14.0),
      MaruMood.magic => (-16.0, 22.0),
      MaruMood.idle => (-11.0, 11.0),
    };
    _ear(c, const Offset(42, 33), earL);
    _ear(c, const Offset(58, 33), earR);
    if (face == MaruMood.cheer) _raisedArms(c, _Palette.fur);

    _blob(c, Rect.fromCenter(center: const Offset(50, 76), width: 44, height: 34), _Palette.fur);
    _blob(c, Rect.fromCenter(center: const Offset(40, 91), width: 14, height: 7), _Palette.fur);
    _blob(c, Rect.fromCenter(center: const Offset(60, 91), width: 14, height: 7), _Palette.fur);

    final headDrop = face == MaruMood.sad ? 2.0 : 0.0;
    _blob(c, Rect.fromCenter(center: Offset(50, 46 + headDrop), width: 46, height: 40), _Palette.fur);

    // Scarf: hanging tail first, then the band over the neck.
    c.save();
    c.translate(61, 66);
    c.rotate(deg(-12));
    _blob(c, RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 0, 9, 15), const Radius.circular(3)), accent);
    c.restore();
    _blob(c, RRect.fromRectAndRadius(const Rect.fromLTRB(31, 62, 69, 70), const Radius.circular(4)), accent);

    final y = 44 + headDrop;
    _cheeks(c, Offset(37, y + 8), Offset(63, y + 8));
    // tiny nose
    final nose = Path()
      ..moveTo(48.2, y + 5)
      ..lineTo(51.8, y + 5)
      ..lineTo(50, y + 7)
      ..close();
    c.drawPath(nose, Paint()..color = _Palette.tongue);
    _eyes(c, Offset(42, y), Offset(58, y), 1.0);
    _mouth(c, Offset(50, y + 10), 1.0, rabbit: true);

    _frontArms(c, _Palette.fur);
  }

  void _ear(Canvas c, Offset base, double angle) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(deg(angle));
    _blob(c, Rect.fromCenter(center: const Offset(0, -15), width: 12, height: 32), _Palette.fur);
    c.drawOval(
      Rect.fromCenter(center: const Offset(0, -15), width: 5.5, height: 22),
      Paint()..color = _Palette.earInner,
    );
    c.restore();
  }

  // ------------------------------------------------------------- turtle

  void _turtle(Canvas c) {
    if (face == MaruMood.cheer) _raisedArms(c, _Palette.skin);

    // Shell peeks out behind the body, with a simple hexagon pattern.
    final shellRect = Rect.fromCenter(center: const Offset(50, 71), width: 62, height: 44);
    _blob(c, shellRect, _Palette.shell);
    c.save();
    c.clipPath(Path()..addOval(shellRect.deflate(1.5)));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _Palette.shellLine;
    for (final center in const [Offset(24, 64), Offset(76, 64), Offset(24, 82), Offset(76, 82), Offset(50, 55)]) {
      c.drawPath(_hexagon(center, 8), line);
    }
    c.restore();

    _blob(c, Rect.fromCenter(center: const Offset(40, 91), width: 14, height: 8), _Palette.skin);
    _blob(c, Rect.fromCenter(center: const Offset(60, 91), width: 14, height: 8), _Palette.skin);
    final belly = Rect.fromCenter(center: const Offset(50, 76), width: 38, height: 32);
    _blob(c, belly, _Palette.belly);
    final plate = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = outline.withValues(alpha: 0.35);
    c.drawLine(const Offset(36, 74), const Offset(64, 74), plate);
    c.drawLine(const Offset(38, 83), const Offset(62, 83), plate);

    final headDrop = face == MaruMood.sad ? 3.0 : 0.0;
    _blob(c, Rect.fromCenter(center: Offset(50, 43 + headDrop), width: 42, height: 36), _Palette.skin);

    // Bow tie
    final bow = Path()
      ..moveTo(50, 61)
      ..lineTo(41, 56.5)
      ..lineTo(41, 65.5)
      ..close()
      ..moveTo(50, 61)
      ..lineTo(59, 56.5)
      ..lineTo(59, 65.5)
      ..close();
    _blobPath(c, bow, accent);
    _blob(c, Rect.fromCircle(center: const Offset(50, 61), radius: 2.6), accent);

    final y = 42 + headDrop;
    _cheeks(c, Offset(36.5, y + 7.5), Offset(63.5, y + 7.5));
    _eyes(c, Offset(42.5, y), Offset(57.5, y), 0.85);
    // Glasses over the eyes.
    final glass = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = outline;
    final lens = Paint()..color = Colors.white.withValues(alpha: 0.22);
    for (final e in [Offset(42.5, y), Offset(57.5, y)]) {
      c.drawCircle(e, 6.8, lens);
      c.drawCircle(e, 6.8, glass);
    }
    c.drawLine(Offset(49.3, y - 0.5), Offset(50.7, y - 0.5), glass);
    _mouth(c, Offset(50, y + 10), 0.9, rabbit: false);

    _frontArms(c, _Palette.skin);
  }

  Path _hexagon(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = deg(60.0 * i + 30);
      final pt = c + Offset.fromDirection(a, r);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  // ------------------------------------------------------------- shared parts

  void _raisedArms(Canvas c, Color fill) {
    for (final (pos, angle) in const [(Offset(29, 50), -28.0), (Offset(71, 50), 28.0)]) {
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(deg(angle));
      _blob(c, Rect.fromCenter(center: Offset.zero, width: 9, height: 20), fill);
      c.restore();
    }
  }

  void _frontArms(Canvas c, Color fill) {
    final arms = switch (face) {
      MaruMood.cheer => const <(Offset, double)>[],
      MaruMood.happy => const [(Offset(28, 68), 55.0), (Offset(72, 68), -55.0)],
      MaruMood.thinking => const [(Offset(31, 76), 18.0), (Offset(58, 61), -35.0)],
      MaruMood.talking => const [(Offset(31, 76), 18.0), (Offset(75, 69), -75.0)],
      MaruMood.sad => const [(Offset(33, 78), 8.0), (Offset(67, 78), -8.0)],
      MaruMood.magic => const [(Offset(29, 58), 25.0), (Offset(69, 76), -18.0)],
      MaruMood.idle => const [(Offset(31, 76), 18.0), (Offset(69, 76), -18.0)],
    };
    if (face == MaruMood.magic) _wand(c);
    for (final (pos, angle) in arms) {
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(deg(angle));
      _blob(c, Rect.fromCenter(center: Offset.zero, width: 9, height: 15), fill);
      c.restore();
    }
  }

  /// Magic wand held up in the left hand; the star tip is at (21, 40) — the same
  /// point the sparkles come from (CharacterMotion.wandTip, matches rabbit_magic.png).
  void _wand(Canvas c) {
    c.drawLine(
      const Offset(27, 53),
      const Offset(22, 43),
      Paint()
        ..color = outline
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 6.5 : 2.9;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = const Offset(21, 40) + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    _blobPath(c, star..close(), _Palette.gold);
  }

  void _cheeks(Canvas c, Offset l, Offset r) {
    final p = Paint()..color = _Palette.cheek.withValues(alpha: face == MaruMood.sad ? 0.25 : 0.55);
    c.drawOval(Rect.fromCenter(center: l, width: 7, height: 4.5), p);
    c.drawOval(Rect.fromCenter(center: r, width: 7, height: 4.5), p);
  }

  void _eyes(Canvas c, Offset l, Offset r, double s) {
    final ink = Paint()..color = outline;
    final shine = Paint()..color = Colors.white;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = outline
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;

    void openEye(Offset e, {Offset look = Offset.zero}) {
      c.drawOval(Rect.fromCenter(center: e + look, width: 5.4 * s, height: 7 * s), ink);
      c.drawCircle(e + look + Offset(1.1 * s, -1.6 * s), 1.2 * s, shine);
    }

    void arc(Offset e, double w, double bend) {
      c.drawPath(
        Path()
          ..moveTo(e.dx - w, e.dy)
          ..quadraticBezierTo(e.dx, e.dy + bend, e.dx + w, e.dy),
        line,
      );
    }

    switch (face) {
      case MaruMood.idle || MaruMood.talking:
        if (_eyesClosed) {
          arc(l + const Offset(0, 0.5), 3.2 * s, 2.6 * s);
          arc(r + const Offset(0, 0.5), 3.2 * s, 2.6 * s);
        } else {
          openEye(l);
          openEye(r);
        }
      case MaruMood.happy:
        arc(l + const Offset(0, 1), 3.3 * s, -4.5 * s);
        arc(r + const Offset(0, 1), 3.3 * s, -4.5 * s);
      case MaruMood.cheer:
        line.strokeWidth = 2.6 * s;
        arc(l + const Offset(0, 1), 4 * s, -5.5 * s);
        arc(r + const Offset(0, 1), 4 * s, -5.5 * s);
      case MaruMood.sad:
        openEye(l, look: Offset(0, 1.2 * s));
        openEye(r, look: Offset(0, 1.2 * s));
        // worried brows: inner ends up
        c.drawLine(l + Offset(-4 * s, -6 * s), l + Offset(3 * s, -8.5 * s), line);
        c.drawLine(r + Offset(4 * s, -6 * s), r + Offset(-3 * s, -8.5 * s), line);
      case MaruMood.magic:
        // wink: left eye closed in a happy arc, right eye open
        arc(l + const Offset(0, 1), 3.3 * s, -4.2 * s);
        openEye(r);
      case MaruMood.thinking:
        openEye(l, look: Offset(1.3 * s, -1.4 * s));
        openEye(r, look: Offset(1.3 * s, -1.4 * s));
        // one raised brow
        c.drawPath(
          Path()
            ..moveTo(r.dx - 3.5 * s, r.dy - 7.5 * s)
            ..quadraticBezierTo(r.dx, r.dy - 11 * s, r.dx + 4 * s, r.dy - 8 * s),
          line,
        );
    }
  }

  void _mouth(Canvas c, Offset m, double s, {required bool rabbit}) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = outline
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;
    final ink = Paint()..color = outline;
    final tongue = Paint()..color = _Palette.tongue;

    void openMouth(double w, double depth) {
      final p = Path()
        ..moveTo(m.dx - w, m.dy - 1)
        ..lineTo(m.dx + w, m.dy - 1)
        ..quadraticBezierTo(m.dx, m.dy - 1 + depth * 2, m.dx - w, m.dy - 1)
        ..close();
      c.drawPath(p, ink);
      c.save();
      c.clipPath(p);
      c.drawOval(Rect.fromCenter(center: Offset(m.dx, m.dy - 1 + depth), width: w * 1.2, height: depth), tongue);
      c.restore();
    }

    switch (face) {
      case MaruMood.idle:
        if (rabbit) {
          // ω
          c.drawPath(
            Path()
              ..moveTo(m.dx - 4.5 * s, m.dy - 0.5)
              ..quadraticBezierTo(m.dx - 2.25 * s, m.dy + 2.8 * s, m.dx, m.dy - 0.2)
              ..quadraticBezierTo(m.dx + 2.25 * s, m.dy + 2.8 * s, m.dx + 4.5 * s, m.dy - 0.5),
            line,
          );
        } else {
          c.drawPath(
            Path()
              ..moveTo(m.dx - 4 * s, m.dy)
              ..quadraticBezierTo(m.dx, m.dy + 3.5 * s, m.dx + 4 * s, m.dy),
            line,
          );
        }
      case MaruMood.happy:
        openMouth(6 * s, 5 * s);
      case MaruMood.magic:
        openMouth(4.5 * s, 3.8 * s);
      case MaruMood.cheer:
        openMouth(7.5 * s, 7 * s);
      case MaruMood.talking:
        final r = Rect.fromCenter(center: m + Offset(0, 1.5 * s), width: 7 * s, height: 6 * s);
        c.drawOval(r, ink);
        c.save();
        c.clipPath(Path()..addOval(r));
        c.drawOval(Rect.fromCenter(center: r.bottomCenter, width: 5 * s, height: 4 * s), tongue);
        c.restore();
      case MaruMood.sad:
        c.drawPath(
          Path()
            ..moveTo(m.dx - 4 * s, m.dy + 2.5 * s)
            ..quadraticBezierTo(m.dx, m.dy - 1.5 * s, m.dx + 4 * s, m.dy + 2.5 * s),
          line,
        );
      case MaruMood.thinking:
        c.drawPath(
          Path()
            ..moveTo(m.dx - 1 * s, m.dy + 1.2 * s)
            ..quadraticBezierTo(m.dx + 2 * s, m.dy - 0.2 * s, m.dx + 5 * s, m.dy + 0.4 * s),
          line,
        );
    }
  }

  void _blob(Canvas c, Object shape, Color fill) {
    final p = Path();
    if (shape is Rect) p.addOval(shape);
    if (shape is RRect) p.addRRect(shape);
    _blobPath(c, p, fill);
  }

  void _blobPath(Canvas c, Path p, Color fill) {
    c.drawPath(p, Paint()..color = fill);
    c.drawPath(p, _stroke);
  }

  @override
  bool shouldRepaint(CharacterPlaceholderPainter old) =>
      old.kind != kind || old.face != face || old.outline != outline || old.accent != accent || old.blink != blink;
}
