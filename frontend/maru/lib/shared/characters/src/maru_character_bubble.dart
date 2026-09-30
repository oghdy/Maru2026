import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'character_types.dart';
import 'maru_character_widget.dart';

/// Character + speech bubble (coaching, hints, dialogue). See CHARACTER_API §2.4.
class MaruCharacterBubble extends StatefulWidget {
  const MaruCharacterBubble({
    super.key,
    required this.kind,
    required this.message,
    this.mood = MaruMood.idle,
    this.size = 72,
    this.side = MaruBubbleSide.left,
    this.typewriter = true,
    this.onTypingDone,
  });

  final MaruCharacterKind kind;
  final String message;

  /// Mood once typing has finished (the character is `talking` while it types).
  final MaruMood mood;
  final double size;

  /// Which side the character sits on; the tail points at it.
  final MaruBubbleSide side;
  final bool typewriter;
  final VoidCallback? onTypingDone;

  /// Characters per second for the typewriter.
  static const typingSpeed = 40.0;

  @override
  State<MaruCharacterBubble> createState() => _MaruCharacterBubbleState();
}

class _MaruCharacterBubbleState extends State<MaruCharacterBubble> with TickerProviderStateMixin {
  late final AnimationController _appear = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Ticker _typer = createTicker(_onType);
  final _shown = ValueNotifier(0);
  bool _typing = false;
  bool _reduceMotion = false;
  bool _started = false;

  int get _length => _glyphs.length;

  List<String>? _glyphCache;
  String? _glyphSource;

  /// One entry per user-visible character. Hangul syllables inside a word get a
  /// WORD JOINER appended so lines break only between words (keep-all), instead
  /// of Flutter's default per-syllable breaks ("학 / 생이에요").
  List<String> get _glyphs {
    if (_glyphSource == widget.message && _glyphCache != null) return _glyphCache!;
    final chars = widget.message.characters.toList();
    bool hangul(String c) {
      final r = c.runes.first;
      return (r >= 0xAC00 && r <= 0xD7A3) || (r >= 0x3130 && r <= 0x318F);
    }

    _glyphCache = [
      for (var i = 0; i < chars.length; i++)
        (i + 1 < chars.length && hangul(chars[i]) && hangul(chars[i + 1])) ? '${chars[i]}\u2060' : chars[i],
    ];
    _glyphSource = widget.message;
    return _glyphCache!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_started) {
      _started = true;
      _restart(rebuild: false);
    } else if (_reduceMotion && _typing) {
      _finishTyping(rebuild: false);
    }
  }

  @override
  void didUpdateWidget(MaruCharacterBubble old) {
    super.didUpdateWidget(old);
    if (old.message != widget.message) _restart(rebuild: false);
  }

  @override
  void dispose() {
    _typer.dispose();
    _appear.dispose();
    _shown.dispose();
    super.dispose();
  }

  void _restart({bool rebuild = true}) {
    _typer.stop();
    if (_reduceMotion) {
      _appear.value = 1;
    } else {
      _appear.forward(from: 0);
    }
    if (!widget.typewriter || _reduceMotion || _length == 0) {
      _shown.value = _length;
      _typing = false;
      _reportDone();
      return;
    }
    _shown.value = 0;
    _typing = true;
    _typer.start();
    if (rebuild) setState(() {});
  }

  void _onType(Duration elapsed) {
    final n = math.min(_length, (elapsed.inMicroseconds / 1e6 * MaruCharacterBubble.typingSpeed).floor());
    _shown.value = n;
    if (n >= _length) _finishTyping();
  }

  void _finishTyping({bool rebuild = true}) {
    if (!_typing) return;
    _typer.stop();
    _shown.value = _length;
    _typing = false;
    if (rebuild) setState(() {});
    _reportDone();
  }

  /// Always after the frame, so callers may setState in the callback.
  void _reportDone() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onTypingDone?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final left = widget.side == MaruBubbleSide.left;
    final size = widget.size;
    // Tail points at the mouth (≈ half-way down the character box).
    const tailY = 22.0;
    final topPad = math.max(0.0, size * 0.5 - tailY);

    final character = MaruCharacter(
      kind: widget.kind,
      mood: _typing ? MaruMood.talking : widget.mood,
      size: size,
    );

    final textStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(color: scheme.onSurface, height: 1.35);
    final bubble = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _typing ? _finishTyping : null,
      child: CustomPaint(
        painter: _BubblePainter(color: scheme.surfaceContainerHighest, tailLeft: left, tailY: tailY),
        child: Padding(
          padding: EdgeInsets.fromLTRB(left ? 22 : 14, 10, left ? 14 : 22, 11),
          // Laid out with the full message from the start (no layout jumps);
          // not-yet-typed characters are transparent.
          child: ValueListenableBuilder<int>(
            valueListenable: _shown,
            builder: (context, n, _) {
              final glyphs = _glyphs;
              return Text.rich(
                TextSpan(children: [
                  TextSpan(text: glyphs.take(n).join()),
                  TextSpan(
                    text: glyphs.skip(n).join(),
                    style: const TextStyle(color: Colors.transparent),
                  ),
                ]),
                style: textStyle,
                semanticsLabel: widget.message,
              );
            },
          ),
        ),
      ),
    );

    final animatedBubble = FadeTransition(
      opacity: CurvedAnimation(parent: _appear, curve: Curves.easeOut),
      child: ScaleTransition(
        alignment: Alignment(left ? -1 : 1, -0.6),
        scale: Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _appear, curve: Curves.easeOutBack)),
        child: bubble,
      ),
    );

    final children = <Widget>[
      character,
      const SizedBox(width: 6),
      Flexible(child: Padding(padding: EdgeInsets.only(top: topPad), child: animatedBubble)),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: left ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: left ? children : children.reversed.toList(),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.color, required this.tailLeft, required this.tailY});

  final Color color;
  final bool tailLeft;
  final double tailY;

  static const _tail = 8.0;
  static const _radius = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromLTRB(tailLeft ? _tail : 0, 0, size.width - (tailLeft ? 0 : _tail), size.height);
    final y = tailY.clamp(_radius, math.max(_radius, size.height - _radius));
    final path = Path()..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(_radius)));
    final edge = tailLeft ? body.left : body.right;
    final tip = tailLeft ? 0.0 : size.width;
    path.addPath(
      Path()
        ..moveTo(edge, y - 8)
        ..quadraticBezierTo(edge + (tailLeft ? -3 : 3), y - 1, tip, y + 3)
        ..quadraticBezierTo(edge + (tailLeft ? -1 : 1), y + 5, edge, y + 7)
        ..close(),
      Offset.zero,
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.color != color || old.tailLeft != tailLeft || old.tailY != tailY;
}
