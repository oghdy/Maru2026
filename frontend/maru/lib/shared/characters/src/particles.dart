import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One confetti piece, in units of the character size (so it scales with it).
class _Particle {
  _Particle({
    required this.velocity,
    required this.color,
    required this.star,
    required this.radius,
    required this.spin,
  });

  final Offset velocity; // size/s
  final Color color;
  final bool star;
  final double radius; // size
  final double spin; // rad/s
}

/// Cheer burst (CHARACTER_API §2.3): 10–14 stars/dots fly out radially from above
/// the head, fall with gravity and fade out over [duration]. Driven by the
/// character's own frame clock — no extra ticker.
class ParticleBurst {
  ParticleBurst({
    required this.origin,
    required this.startT,
    required Color primary,
    required math.Random rnd,
  }) : _particles = _spawn(primary, rnd);

  static List<_Particle> _spawn(Color primary, math.Random rnd) {
    final count = 10 + rnd.nextInt(5); // 10–14
    return List.generate(count, (i) {
      // Upward fan (−170°…−10°), evenly spread with jitter.
      final a = -math.pi * (0.06 + 0.88 * (i + rnd.nextDouble()) / count);
      final speed = 0.9 + rnd.nextDouble() * 0.7;
      return _Particle(
        velocity: Offset(math.cos(a), math.sin(a)) * speed,
        color: [primary, ..._accents][rnd.nextInt(4)],
        star: rnd.nextBool(),
        radius: 0.028 + rnd.nextDouble() * 0.022,
        spin: (rnd.nextDouble() - 0.5) * 10,
      );
    });
  }

  // Secondary festive colours (allowed exception to colorScheme-only).
  static const _accents = [Color(0xFFFFC83D), Color(0xFF4CD4B0), Color(0xFFFF8FB1)];
  static const duration = 0.9;
  static const _gravity = 2.4; // size/s²

  /// Burst origin in size units, relative to the character box (0,0 = top-left).
  final Offset origin;
  final double startT;
  final List<_Particle> _particles;

  bool isDone(double t) => t - startT >= duration;

  void paint(Canvas canvas, double size, double t) {
    final age = t - startT;
    if (age < 0 || age >= duration) return;
    final u = age / duration;
    final alpha = (1 - u * u).clamp(0.0, 1.0);
    // Quick pop-in so pieces don't appear at full size on the head.
    final grow = Curves.easeOutBack.transform((age / 0.12).clamp(0.0, 1.0));
    for (final p in _particles) {
      final pos = (origin + p.velocity * age + Offset(0, 0.5 * _gravity * age * age)) * size;
      final r = p.radius * size * grow;
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      if (p.star) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(p.spin * age);
        canvas.drawPath(_star(r), paint);
        canvas.restore();
      } else {
        canvas.drawCircle(pos, r * 0.75, paint);
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
  ParticlePainter({required Listenable repaint, required this.burst, required this.now}) : super(repaint: repaint);

  final ParticleBurst? Function() burst;
  final double Function() now;

  @override
  void paint(Canvas canvas, Size size) => burst()?.paint(canvas, size.width, now());

  @override
  bool shouldRepaint(ParticlePainter old) => false;
}
