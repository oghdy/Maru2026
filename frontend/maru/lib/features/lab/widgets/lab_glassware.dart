import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lab props drawn in code (no image assets / packages): glassware with bubbling liquid
/// and a graph-paper "lab notebook" background. Used by the Language Lab menu.
enum LabGlass { beaker, flask, tube }

/// One piece of glassware. [bubbles] (0..1, repeating) makes bubbles rise; null = still picture.
class LabGlassware extends StatelessWidget {
  final LabGlass kind;
  final Color liquid;
  final double width;
  final double height;
  final Animation<double>? bubbles;

  const LabGlassware({
    super.key,
    required this.kind,
    required this.liquid,
    this.width = 48,
    this.height = 64,
    this.bubbles,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, height),
        painter: _GlassPainter(
          kind: kind,
          liquid: liquid,
          glass: cs.onSurfaceVariant.withValues(alpha: 0.55),
          glassFill: cs.surface.withValues(alpha: 0.75),
          bubbles: bubbles,
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  final LabGlass kind;
  final Color liquid;
  final Color glass;
  final Color glassFill;
  final Animation<double>? bubbles;

  _GlassPainter({required this.kind, required this.liquid, required this.glass, required this.glassFill, this.bubbles})
    : super(repaint: bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Top 22% is room for bubbles leaving the glass.
    final body = _bodyPath(w, h);
    final liquidTop = switch (kind) {
      LabGlass.beaker => h * 0.58,
      LabGlass.flask => h * 0.62,
      LabGlass.tube => h * 0.55,
    };
    final t = bubbles?.value ?? 0.35;

    canvas.drawPath(body, Paint()..color = glassFill);

    // Liquid with a gentle wave, clipped to the glass.
    canvas.save();
    canvas.clipPath(body);
    final wave = Path()..moveTo(0, liquidTop);
    for (double x = 0; x <= w; x += 2) {
      wave.lineTo(x, liquidTop + math.sin((x / w * 2 + t * 2) * math.pi) * h * 0.015);
    }
    wave
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(wave, Paint()..color = liquid.withValues(alpha: 0.75));
    // Shine on the liquid.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.3, liquidTop + h * 0.06, w * 0.06, h * 0.18),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.restore();

    canvas.drawPath(
      body,
      Paint()
        ..color = glass
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, w * 0.045)
        ..strokeJoin = StrokeJoin.round,
    );

    if (kind == LabGlass.beaker) {
      final marks = Paint()
        ..color = glass
        ..strokeWidth = 1.2;
      for (var i = 0; i < 3; i++) {
        final y = h * (0.42 + i * 0.13);
        canvas.drawLine(Offset(w * 0.68, y), Offset(w * 0.8, y), marks);
      }
    }

    // Bubbles rise from the liquid and fade out above the rim.
    final topX = w / 2;
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final y = liquidTop - p * (liquidTop + h * 0.02);
      final x = topX + math.sin((p * 2 + i) * math.pi) * w * 0.12 + (i - 1) * w * 0.08;
      final r = w * (0.05 + i * 0.02) * (0.6 + p * 0.6);
      canvas.drawCircle(Offset(x, y), r, Paint()..color = liquid.withValues(alpha: 0.45 * (1 - p)));
    }
  }

  Path _bodyPath(double w, double h) {
    switch (kind) {
      case LabGlass.beaker:
        final r = w * 0.1;
        return Path()
          ..moveTo(w * 0.1, h * 0.26) // lip
          ..lineTo(w * 0.18, h * 0.3)
          ..lineTo(w * 0.18, h * 0.96 - r)
          ..quadraticBezierTo(w * 0.18, h * 0.96, w * 0.18 + r, h * 0.96)
          ..lineTo(w * 0.82 - r, h * 0.96)
          ..quadraticBezierTo(w * 0.82, h * 0.96, w * 0.82, h * 0.96 - r)
          ..lineTo(w * 0.82, h * 0.26)
          ..close();
      case LabGlass.flask:
        return Path()
          ..moveTo(w * 0.38, h * 0.24)
          ..lineTo(w * 0.62, h * 0.24)
          ..lineTo(w * 0.62, h * 0.46)
          ..lineTo(w * 0.92, h * 0.88)
          ..quadraticBezierTo(w * 0.96, h * 0.96, w * 0.86, h * 0.96)
          ..lineTo(w * 0.14, h * 0.96)
          ..quadraticBezierTo(w * 0.04, h * 0.96, w * 0.08, h * 0.88)
          ..lineTo(w * 0.38, h * 0.46)
          ..close();
      case LabGlass.tube:
        final left = w * 0.3;
        final right = w * 0.7;
        final rr = (right - left) / 2;
        return Path()
          ..moveTo(left - w * 0.04, h * 0.24)
          ..lineTo(left, h * 0.27)
          ..lineTo(left, h * 0.96 - rr)
          ..arcToPoint(Offset(right, h * 0.96 - rr), radius: Radius.circular(rr), clockwise: false)
          ..lineTo(right, h * 0.27)
          ..lineTo(right + w * 0.04, h * 0.24)
          ..close();
    }
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.kind != kind || old.liquid != liquid || old.glass != glass || old.bubbles != bubbles;
}

/// Graph-paper page with a notebook margin line, painted behind the lab menu.
class LabGraphPaper extends StatelessWidget {
  const LabGraphPaper({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _GraphPaperPainter(
        minor: cs.primary.withValues(alpha: 0.05),
        major: cs.primary.withValues(alpha: 0.10),
        margin: cs.tertiary.withValues(alpha: 0.22),
      ),
    );
  }
}

class _GraphPaperPainter extends CustomPainter {
  final Color minor;
  final Color major;
  final Color margin;

  _GraphPaperPainter({required this.minor, required this.major, required this.margin});

  static const double _cell = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = minor
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = major
      ..strokeWidth = 1;
    var i = 0;
    for (double x = 0; x <= size.width; x += _cell, i++) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), i % 5 == 0 ? majorPaint : minorPaint);
    }
    i = 0;
    for (double y = 0; y <= size.height; y += _cell, i++) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i % 5 == 0 ? majorPaint : minorPaint);
    }
    // Notebook margin.
    canvas.drawLine(
      const Offset(_cell * 1.5, 0),
      Offset(_cell * 1.5, size.height),
      Paint()
        ..color = margin
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_GraphPaperPainter old) => old.minor != minor || old.major != major || old.margin != margin;
}
