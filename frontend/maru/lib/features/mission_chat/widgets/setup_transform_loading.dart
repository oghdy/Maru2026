import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maru/shared/characters/maru_character.dart';

/// Mood used while the rabbit transforms.
/// TODO(MSN-1.7.7): once CHR-1.7 (MaruMood.magic) is merged into feat/mission, set this to
/// MaruMood.magic and [_screenEffects] to false — the magic mood does the spin/poof/sparkles itself
/// (CHARACTER_API 3.3 C7).
const MaruMood _transformMood = MaruMood.thinking;
const bool _screenEffects = true;

/// Mission setup loading view: Tokki, the mischievous rabbit, spins, goes "poof" and
/// sparkles while it turns into the role the learner asked for.
class SetupTransformLoading extends StatefulWidget {
  /// Role typed by the learner (empty = they left it blank).
  final String role;

  const SetupTransformLoading({super.key, required this.role});

  @override
  State<SetupTransformLoading> createState() => _SetupTransformLoadingState();
}

class _SetupTransformLoadingState extends State<SetupTransformLoading> with SingleTickerProviderStateMixin {
  // One cycle = spin → poof → sparkle settle.
  static const _cycle = Duration(milliseconds: 2600);
  static const _stepLines = [
    'Waving the magic wand...',
    'Picking the right costume...',
    'Setting up the scene...',
    'Rehearsing some Korean lines...',
    'Almost ready to chat!',
  ];

  late final AnimationController _controller = AnimationController(vsync: this, duration: _cycle);
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _stepIndex = math.min(_stepIndex + 1, _stepLines.length - 1));
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final role = widget.role.trim();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  if (!_screenEffects) return child!;
                  final t = _controller.value;
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MagicPainter(
                            t: t,
                            primary: colors.primary,
                            puff: colors.surfaceContainerHighest,
                            outline: colors.outlineVariant,
                          ),
                        ),
                      ),
                      Transform(
                        alignment: Alignment.center,
                        transform: _spinTransform(t),
                        child: child,
                      ),
                    ],
                  );
                },
                child: const Padding(
                  // Top gap for the character's own motion (CHARACTER_API 3.0 rule 4).
                  padding: EdgeInsets.only(top: 30),
                  child: MaruCharacter(
                    kind: MaruCharacterKind.rabbit,
                    mood: _transformMood,
                    size: 120,
                    semanticLabel: 'Tokki the rabbit transforming',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MAGIC IN PROGRESS',
              style: text.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Tokki is transforming into\n'),
                  if (role.isEmpty)
                    const TextSpan(text: 'your conversation partner')
                  else
                    TextSpan(text: '“$role”', style: TextStyle(color: colors.primary)),
                  const TextSpan(text: '...'),
                ],
              ),
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: colors.primaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _stepLines[_stepIndex],
                key: ValueKey(_stepIndex),
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your mission and partner are being created. This takes a few seconds.',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  /// Coin-flip spin during the first part of each cycle, with a small squash at the "poof".
  Matrix4 _spinTransform(double t) {
    const spinEnd = 0.34;
    if (t >= spinEnd) {
      // Pop back from the poof: 0.9 → 1.0.
      final p = ((t - spinEnd) / 0.18).clamp(0.0, 1.0);
      final s = 0.9 + 0.1 * Curves.elasticOut.transform(p);
      return Matrix4.identity()..multiply(Matrix4.diagonal3Values(s, s, 1));
    }
    final p = Curves.easeInOutCubic.transform(t / spinEnd);
    final s = 1 - 0.1 * math.sin(p * math.pi);
    return Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateY(p * 2 * math.pi)
      ..multiply(Matrix4.diagonal3Values(s, s, 1));
  }
}

class _MagicPainter extends CustomPainter {
  final double t;
  final Color primary;
  final Color puff;
  final Color outline;

  _MagicPainter({required this.t, required this.primary, required this.puff, required this.outline});

  static const _sparkleColors = [Color(0xFFFFC83D), Color(0xFF4CD4B0), Color(0xFFFF8FB1)];

  @override
  void paint(Canvas canvas, Size size) {
    // Rabbit body centre (the character sits 30px lower because of its top gap).
    final center = Offset(size.width / 2, size.height / 2 + 15);
    _paintOrbit(canvas, center);
    _paintPoof(canvas, center);
  }

  // Sparkles circling the rabbit the whole time, twinkling at different phases.
  void _paintOrbit(Canvas canvas, Offset center) {
    const count = 7;
    for (var i = 0; i < count; i++) {
      final angle = 2 * math.pi * (i / count + t * 0.25);
      final radius = 92.0 + 8 * math.sin(2 * math.pi * (t + i * 0.3));
      final p = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius * 0.75);
      final twinkle = 0.5 + 0.5 * math.sin(2 * math.pi * (t * 2 + i / count));
      final color = i.isEven ? primary : _sparkleColors[i % _sparkleColors.length];
      _star(canvas, p, 4 + 4 * twinkle, color.withValues(alpha: 0.35 + 0.6 * twinkle));
    }
  }

  // "Poof": soft cloud puffs burst out right after the spin, plus a ring of sparkles.
  void _paintPoof(Canvas canvas, Offset center) {
    const start = 0.30, end = 0.80;
    if (t < start || t > end) return;
    final p = (t - start) / (end - start);
    final grow = Curves.easeOutCubic.transform(p);
    final fade = (1 - p).clamp(0.0, 1.0);

    const puffs = 9;
    for (var i = 0; i < puffs; i++) {
      final angle = 2 * math.pi * i / puffs + 0.3;
      final dist = 30 + 55 * grow;
      final o = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist * 0.8);
      final r = 14 + 14 * grow * (i.isEven ? 1 : 0.7);
      canvas.drawCircle(o, r, Paint()..color = puff.withValues(alpha: 0.9 * fade));
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = outline.withValues(alpha: 0.8 * fade),
      );
    }

    const burst = 10;
    for (var i = 0; i < burst; i++) {
      final angle = 2 * math.pi * i / burst;
      final dist = 40 + 80 * grow;
      final o = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      _star(canvas, o, 7 * fade + 2, _sparkleColors[i % _sparkleColors.length].withValues(alpha: fade));
    }
  }

  // Four-point sparkle.
  void _star(Canvas canvas, Offset c, double r, Color color) {
    final inner = r * 0.32;
    final path = Path();
    for (var k = 0; k < 8; k++) {
      final a = math.pi / 4 * k - math.pi / 2;
      final rr = k.isEven ? r : inner;
      final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MagicPainter old) => old.t != t || old.primary != primary;
}
