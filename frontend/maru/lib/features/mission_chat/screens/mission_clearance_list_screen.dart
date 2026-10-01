import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/mission_chat_provider.dart';
import '../models/mission_clearance_model.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../widgets/clearance_style.dart';
import 'mission_clearance_screen.dart';

class MissionClearanceListScreen extends ConsumerWidget {
  const MissionClearanceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clearancesAsync = ref.watch(clearancesProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: missionPageBackground(context),
      appBar: AppBar(
        backgroundColor: missionPageBackground(context),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('My Certificates', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: clearancesAsync.when(
        data: (clearances) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(clearancesProvider.future),
            child: clearances.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      // Top gap for the character's motion (CHARACTER_API 3.0 rule 4).
                      const SizedBox(height: 90),
                      const Center(
                        child: MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.idle, size: 120),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No missions yet',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Finish a Mission Chat to get your feedback report!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: clearances.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildSummaryHero(context, clearances);
                      return _buildClearanceCard(context, clearances[index - 1]);
                    },
                  ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 40, color: colors.error),
                const SizedBox(height: 12),
                Text(
                  "Couldn't load your certificates. ${missionErrorMessage(err)}",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(clearancesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Real counts from the list (no fixed numbers).
  Widget _buildSummaryHero(BuildContext context, List<MissionClearanceModel> clearances) {
    final colors = Theme.of(context).colorScheme;
    final clearedCount = clearances.where((c) => c.cleared == true).length;
    final total = clearances.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        gradient: missionHeroGradient(context),
        borderRadius: BorderRadius.circular(missionCardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your mission reports',
                  style: TextStyle(color: colors.onPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total ${total == 1 ? 'mission' : 'missions'} · $clearedCount cleared',
                  style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.9), fontSize: 15),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.workspace_premium_rounded, color: colors.onPrimary, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildClearanceCard(BuildContext context, MissionClearanceModel clearance) {
    final colors = Theme.of(context).colorScheme;
    final dateStr = clearance.clearedAt != null
        ? DateFormat('yyyy.MM.dd').format(clearance.clearedAt!)
        : 'Unknown date';
    final (label, icon, accent, pillBg, pillFg) = switch (clearance.cleared) {
      true => ('Cleared', Icons.workspace_premium_rounded, Colors.amber.shade700, colors.primary, colors.onPrimary),
      false => ('Not cleared', Icons.replay_rounded, colors.primary, colors.secondaryContainer, colors.onSecondaryContainer),
      null => ('Completed', Icons.check_rounded, colors.outline, colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: missionCardDecoration(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(missionCardRadius),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MissionClearanceScreen(clearance: clearance)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                MissionIconTile(icon: icon, color: accent, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clearance.missionTitle,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${clearance.persona} · $dateStr',
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      MissionPill(label: label, background: pillBg, foreground: pillFg),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
