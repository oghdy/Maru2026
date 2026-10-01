import 'dart:math' as math;

import 'package:flutter/material.dart';

enum _Shape { star, dot, puff }

/// One particle, in units of the character size (so it scales with it).
class _Particle {
  _Particle({
    required this.velocity,
    required this.color,
    required this.shape,
    required this.radius,
    this.spin = 0,
  });

  final Offset velocity; // size/s
  final Color color;
  final _Shape shape;
  final double radius; // size
  final double spin; // rad/s
}

/// A short-lived effect driven by the character's own frame clock (no extra ticker):
/// - [ParticleBurst.new] cheer confetti (CHARACTER_API §2.3): 10–14 stars/dots fly up
///   from above the head, fall with gravity and fade, 900ms.
/// - [ParticleBurst.sparkle] magic sparkles: stars twinkling out from the wand tip.
/// - [ParticleBurst.smoke] magic "poof": soft lavender/white puffs that swell and fade.
class ParticleBurst {
  ParticleBurst({
    required this.origin,
    required this.startT,
    required Color primary,
    required math.Random rnd,
  })  : duration = 0.9,
        _gravity = 2.4,
        _rim = null,
        _particles = _confetti(primary, rnd);

  /// [count] stars (purple/gold/white) shooting out in all directions, light gravity.
  ParticleBurst.sparkle({
    required this.origin,
    required this.startT,
    required Color primary,
    required math.Random rnd,
    int count = 9,
    double speed = 0.7,
  })  : duration = 0.7,
        _gravity = 0.6,
        _rim = primary,
        _particles = List.generate(count, (i) {
          final a = 2 * math.pi * (i + rnd.nextDouble() * 0.8) / count;
          final v = speed * (0.6 + rnd.nextDouble() * 0.6);
          return _Particle(
            velocity: Offset(math.cos(a), math.sin(a)) * v,
            color: [primary, _gold, Colors.white][i % 3],
            shape: _Shape.star,
            radius: 0.022 + rnd.nextDouble() * 0.02,
            spin: (rnd.nextDouble() - 0.5) * 8,
          );
        });

  /// [count] puffs drifting outward from [origin] while swelling and fading.
  ParticleBurst.smoke({
    required this.origin,
    required this.startT,
    required math.Random rnd,
    int count = 4,
    double scale = 1,
  })  : duration = 0.45,
        _gravity = -0.3, // smoke drifts up a little
        _rim = null,
        _particles = List.generate(count, (i) {
          final a = 2 * math.pi * (i + rnd.nextDouble() * 0.5) / count + math.pi / 4;
          return _Particle(
            velocity: Offset(math.cos(a), math.sin(a) * 0.6) * (0.55 * scale),
            color: i.isEven ? _lavender : Colors.white,
            shape: _Shape.puff,
            radius: (0.09 + rnd.nextDouble() * 0.04) * scale,
          );
        });

  static List<_Particle> _confetti(Color primary, math.Random rnd) {
    final count = 10 + rnd.nextInt(5); // 10–14
    return List.generate(count, (i) {
      // Upward fan (−170°…−10°), evenly spread with jitter.
      final a = -math.pi * (0.06 + 0.88 * (i + rnd.nextDouble()) / count);
      final speed = 0.9 + rnd.nextDouble() * 0.7;
      return _Particle(
        velocity: Offset(math.cos(a), math.sin(a)) * speed,
        color: [primary, ..._accents][rnd.nextInt(4)],
        shape: rnd.nextBool() ? _Shape.star : _Shape.dot,
        radius: 0.028 + rnd.nextDouble() * 0.022,
        spin: (rnd.nextDouble() - 0.5) * 10,
      );
    });
  }

  // Secondary festive colours (allowed exception to colorScheme-only).
  static const _accents = [Color(0xFFFFC83D), Color(0xFF4CD4B0), Color(0xFFFF8FB1)];
  static const _gold = Color(0xFFFFC83D);
  static const _lavender = Color(0xFFD9CCFF);

  /// Origin in size units, relative to the character box (0,0 = top-left).
  final Offset origin;
  final double startT;
  final double duration; // seconds
  final double _gravity; // size/s²

  /// Thin outline for sparkles so white/gold stars stay visible on light backgrounds.
  final Color? _rim;
  final List<_Particle> _particles;

  bool isDone(double t) => t - startT >= duration;

  void paint(Canvas canvas, double size, double t) {
    final age = t - startT;
    if (age < 0 || age >= duration) return;
    final u = age / duration;
    // Quick pop-in so pieces don't appear at full size on the character.
    final grow = Curves.easeOutBack.transform((age / 0.12).clamp(0.0, 1.0));
    for (final p in _particles) {
      final pos = (origin + p.velocity * age + Offset(0, 0.5 * _gravity * age * age)) * size;
      switch (p.shape) {
        case _Shape.puff:
          // Swell from 60% to 140% while fading out.
          final r = p.radius * size * (0.6 + 0.8 * Curves.easeOutCubic.transform(u));
          final alpha = 0.85 * (1 - Curves.easeInQuad.transform(u));
          canvas.drawCircle(pos, r, Paint()..color = p.color.withValues(alpha: alpha));
        case _Shape.star:
        case _Shape.dot:
          final alpha = (1 - u * u).clamp(0.0, 1.0);
          final r = p.radius * size * grow;
          final paint = Paint()..color = p.color.withValues(alpha: alpha);
          if (p.shape == _Shape.dot) {
            canvas.drawCircle(pos, r * 0.75, paint);
          } else {
            canvas.save();
            canvas.translate(pos.dx, pos.dy);
            canvas.rotate(p.spin * age);
            canvas.drawPath(_star(r), paint);
            final rim = _rim;
            if (rim != null) {
              canvas.drawPath(
                _star(r),
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = math.max(0.8, r * 0.12)
                  ..color = rim.withValues(alpha: alpha * 0.45),
              );
            }
            canvas.restore();
          }
      }
    }
  }

  static Path _star(double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(math.cos(a), math.sin(a)) * rad;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }
}

class ParticlePainter extends CustomPainter {
  ParticlePainter({required Listenable repaint, required this.bursts, required this.now}) : super(repaint: repaint);

  final List<ParticleBurst> Function() bursts;
  final double Function() now;

  @override
  void paint(Canvas canvas, Size size) {
    final t = now();
    for (final b in bursts()) {
      b.paint(canvas, size.width, t);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter old) => false;
}
