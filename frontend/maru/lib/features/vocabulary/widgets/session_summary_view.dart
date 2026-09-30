import 'package:flutter/material.dart';
import '../models/review_request.dart';

/// Word Study / Daily Review 완료 화면 공용 (VOC-1.5.1): 튀어나오는 배지 + 평가 요약 + 버튼.
class SessionSummaryView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Map<ReviewRating, int> ratingCounts;
  final String buttonLabel;
  final VoidCallback onPressed;

  const SessionSummaryView({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.ratingCounts = const {},
    required this.buttonLabel,
    required this.onPressed,
  });

  static const _labels = {
    ReviewRating.again: ('Again', Colors.red),
    ReviewRating.hard: ('Hard', Colors.orange),
    ReviewRating.good: ('Good', Colors.green),
    ReviewRating.easy: ('Easy', Colors.blue),
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rated = ratingCounts.values.fold<int>(0, (a, b) => a + b);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.14),
                  ),
                  child: Icon(icon, size: 60, color: iconColor),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15, height: 1.4),
              ),
              if (rated > 0) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      for (final entry in _labels.entries)
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${ratingCounts[entry.key] ?? 0}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: entry.value.$2.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entry.value.$1,
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: 240,
                child: FilledButton(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(buttonLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
