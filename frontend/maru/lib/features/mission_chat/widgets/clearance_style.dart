import 'package:flutter/material.dart';

/// Shared look for the mission setup form, report pages and certificate list (MSN-1.7.9).
/// Same language as the vocabulary redesign: soft white cards, big radii, tinted icon tiles,
/// and a primary gradient hero.

const double missionCardRadius = 24;

BoxDecoration missionCardDecoration(BuildContext context, {Color? borderColor}) {
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colors.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(missionCardRadius),
    border: borderColor == null ? null : Border.all(color: borderColor, width: 2),
    boxShadow: [
      BoxShadow(
        color: colors.primary.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

LinearGradient missionHeroGradient(BuildContext context) {
  final primary = Theme.of(context).colorScheme.primary;
  final hsl = HSLColor.fromColor(primary);
  final deep = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, deep],
  );
}

/// Rounded square with an emoji or icon, tinted with [color].
class MissionIconTile extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final Color color;
  final double size;

  const MissionIconTile({super.key, this.icon, this.emoji, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.48))
          : Icon(icon, color: color, size: size * 0.55),
    );
  }
}

/// Small rounded status label.
class MissionPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const MissionPill({super.key, required this.label, required this.background, required this.foreground, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(label, style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Section header used inside report cards: icon tile + title (+ optional count).
class MissionSectionHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  final IconData? icon;
  final Color color;
  final int? count;

  const MissionSectionHeader({super.key, required this.title, this.emoji, this.icon, required this.color, this.count});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        MissionIconTile(emoji: emoji, icon: icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (count != null)
          MissionPill(label: '$count', background: color.withValues(alpha: 0.14), foreground: colors.onSurface),
      ],
    );
  }
}
