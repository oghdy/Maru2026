import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maru/shared/characters/maru_character.dart';

import '../../mission_chat/widgets/clearance_style.dart';

export '../../mission_chat/widgets/clearance_style.dart'
    show MissionPill, missionCardDecoration, missionCardRadius, missionHeroGradient, missionPageBackground;

/// Shared look and touch feel of the Korean Lesson screens. Page, card and hero
/// tokens are the ones Mission Chat uses (clearance_style.dart) so the features match.

/// Brand-neutral state colors (the color scheme has no "success").
Color lessonSuccess() => Colors.green.shade700;
Color lessonSuccessSoft() => Colors.green.shade50;
Color lessonStar() => Colors.amber.shade600;

bool lessonReduceMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context);

/// Motion length that collapses to zero when the system asks for reduced motion.
Duration lessonMotion(BuildContext context, int milliseconds) =>
    lessonReduceMotion(context) ? Duration.zero : Duration(milliseconds: milliseconds);

/// Transparent, flat app bar on the page background (no purple bar).
PreferredSizeWidget lessonAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  VoidCallback? onBack,
}) {
  final background = missionPageBackground(context);
  return AppBar(
    backgroundColor: background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.chevron_left_rounded, size: 32),
      tooltip: 'Back',
      onPressed: onBack ?? () => Navigator.maybePop(context),
    ),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
    ),
    actions: actions,
  );
}

/// Small upper-case label above a title ("UNIT 1").
class LessonOverline extends StatelessWidget {
  final String text;
  final Color? color;

  const LessonOverline(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Shrinks its child slightly while a pointer is down. Listens to raw pointers so it
/// works around buttons, draggables and tap detectors without joining the gesture arena.
class LessonPressEffect extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double pressedScale;

  const LessonPressEffect({super.key, required this.child, this.enabled = true, this.pressedScale = 0.96});

  @override
  State<LessonPressEffect> createState() => _LessonPressEffectState();
}

class _LessonPressEffectState extends State<LessonPressEffect> {
  bool _pressed = false;
  Offset? _downAt;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _downAt = e.position;
        if (widget.enabled) _set(true);
      },
      // A drag or scroll started here is not a press any more.
      onPointerMove: (e) {
        final start = _downAt;
        if (start != null && (e.position - start).distance > kTouchSlop) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: lessonMotion(context, 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Tappable surface: press effect, click cursor, button semantics.
class LessonPressable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const LessonPressable({super.key, required this.child, this.onTap, this.pressedScale = 0.97});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: LessonPressEffect(enabled: enabled, pressedScale: pressedScale, child: child),
        ),
      ),
    );
  }
}

/// The large action at the bottom of a lesson step.
class LessonPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const LessonPrimaryButton({super.key, required this.label, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = color ?? colors.primary;
    final enabled = onPressed != null;
    return LessonPressEffect(
      enabled: enabled,
      child: AnimatedContainer(
        duration: lessonMotion(context, 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (enabled) BoxShadow(color: background.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: colors.onPrimary,
            disabledBackgroundColor: colors.surfaceContainerHighest,
            disabledForegroundColor: colors.onSurfaceVariant,
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

/// Secondary action next to [LessonPrimaryButton].
class LessonSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const LessonSecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LessonPressEffect(
      enabled: onPressed != null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          backgroundColor: colors.surface,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(color: colors.primary.withValues(alpha: onPressed == null ? 0.12 : 0.3), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

/// Round speaker button with a soft primary fill.
class LessonSpeakerButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  final IconData icon;
  final String tooltip;

  const LessonSpeakerButton({
    super.key,
    required this.onPressed,
    this.size = 48,
    this.icon = Icons.volume_up_rounded,
    this.tooltip = 'Listen',
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: LessonPressable(
        pressedScale: 0.9,
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
          child: Icon(icon, color: colors.primary, size: size * 0.52),
        ),
      ),
    );
  }
}

/// Thin rounded bar that glides to its new value.
class LessonProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;

  const LessonProgressBar({super.key, required this.value, this.height = 8, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: lessonMotion(context, 250),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: colors.primaryContainer,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? colors.primary),
        ),
      ),
    );
  }
}

/// Progress ring with something in the middle.
class LessonRing extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget child;

  const LessonRing({
    super.key,
    required this.value,
    required this.child,
    this.size = 48,
    this.strokeWidth = 4,
    this.color,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: lessonMotion(context, 450),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => CircularProgressIndicator(
              value: v,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              color: color ?? colors.primary,
              backgroundColor: trackColor ?? colors.primaryContainer,
            ),
          ),
          Center(child: child),
        ],
      ),
    );
  }
}

/// Earned stars out of 3.
class LessonStars extends StatelessWidget {
  final int earned;
  final double size;

  const LessonStars({super.key, required this.earned, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '$earned of 3 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Icon(
            i < earned ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < earned ? lessonStar() : colors.outlineVariant,
          ),
        ),
      ),
    );
  }
}

/// Pops in when first built (used by blocks arriving somewhere).
class LessonPopIn extends StatelessWidget {
  final Widget child;
  final int milliseconds;

  const LessonPopIn({super.key, required this.child, this.milliseconds = 180});

  @override
  Widget build(BuildContext context) {
    if (lessonReduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(
        scale: 0.86 + 0.14 * v,
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: child,
    );
  }
}

/// Short sideways shake each time [trigger] changes (a wrong answer).
class LessonShake extends StatefulWidget {
  final int trigger;
  final Widget child;

  const LessonShake({super.key, required this.trigger, required this.child});

  @override
  State<LessonShake> createState() => _LessonShakeState();
}

class _LessonShakeState extends State<LessonShake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  @override
  void didUpdateWidget(LessonShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger && !lessonReduceMotion(context)) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = _controller.isAnimating ? math.sin(t * math.pi * 4) * 5 * (1 - t) : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Feedback that opens smoothly above the step's button. Pass null to close it.
class LessonReveal extends StatelessWidget {
  final Widget? child;
  final Alignment alignment;

  const LessonReveal({super.key, this.child, this.alignment = Alignment.bottomCenter});

  @override
  Widget build(BuildContext context) {
    final duration = lessonMotion(context, 200);
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: alignment,
      // Characters may jump past the box while they react.
      clipBehavior: Clip.none,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: child ?? const SizedBox(key: ValueKey('lesson_reveal_empty'), width: double.infinity),
      ),
    );
  }
}

/// A right/wrong message with a character: 🐰 praises, 🐢 coaches (same as sentence building).
class LessonFeedbackCard extends StatelessWidget {
  final String message;
  final bool correct;
  final int reactionKey;

  const LessonFeedbackCard({super.key, required this.message, required this.correct, this.reactionKey = 0});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      decoration: BoxDecoration(
        color: correct ? lessonSuccessSoft() : colors.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          MaruCharacter(
            kind: correct ? MaruCharacterKind.rabbit : MaruCharacterKind.turtle,
            mood: correct ? MaruMood.happy : MaruMood.thinking,
            size: 48,
            reactionKey: reactionKey,
            interactive: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: correct ? lessonSuccess() : colors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
