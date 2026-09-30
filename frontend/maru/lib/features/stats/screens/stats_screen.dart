import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_stats_model.dart';
import '../providers/user_stats_provider.dart';

/// Stats tab: the learner's own numbers from /api/me/stats.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 56, color: colorScheme.error),
                const SizedBox(height: 12),
                const Text("Couldn't load your progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(userStatsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.refresh(userStatsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.25,
                children: [
                  _StatTile(
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                    value: '${stats.currentStreakDays}',
                    label: stats.currentStreakDays == 1 ? 'Day streak' : 'Days streak',
                  ),
                  _StatTile(
                    icon: Icons.star,
                    color: Colors.amber,
                    value: '${stats.totalStarsEarned}',
                    label: 'Stars earned',
                  ),
                  _StatTile(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    value: '${stats.totalLessonsCompleted}',
                    label: stats.totalLessonsCompleted == 1 ? 'Lesson completed' : 'Lessons completed',
                  ),
                  _StatTile(
                    icon: Icons.timer_outlined,
                    color: colorScheme.primary,
                    value: _formatMinutes(stats.totalStudyMinutes),
                    label: 'Study time',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InfoRow(label: 'Longest streak', value: _days(stats.longestStreakDays)),
              _InfoRow(label: 'Last study day', value: _lastStudy(stats)),
              const SizedBox(height: 16),
              Text(
                'Study time counts time spent in lessons. Streaks count days with a finished lesson or a word review.',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _days(int n) => '$n ${n == 1 ? 'day' : 'days'}';

  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60, m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  static String _lastStudy(UserStatsModel stats) {
    final d = stats.lastStudyDate;
    if (d == null) return 'Not yet';
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = today.difference(DateUtils.dateOnly(d)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatTile({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          Text(label, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
