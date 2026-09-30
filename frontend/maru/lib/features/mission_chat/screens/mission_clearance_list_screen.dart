import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/mission_chat_provider.dart';
import '../models/mission_clearance_model.dart';
import 'mission_clearance_screen.dart';

class MissionClearanceListScreen extends ConsumerWidget {
  const MissionClearanceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clearancesAsync = ref.watch(clearancesProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
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
                      const SizedBox(height: 120),
                      Text(
                        'No missions yet.\nFinish a Mission Chat to get your feedback report! 🏆',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: clearances.length,
                    itemBuilder: (context, index) {
                      return _buildClearanceCard(context, clearances[index]);
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

  Widget _buildClearanceCard(BuildContext context, MissionClearanceModel clearance) {
    final colors = Theme.of(context).colorScheme;
    final dateStr = clearance.clearedAt != null
        ? DateFormat('yyyy.MM.dd').format(clearance.clearedAt!)
        : 'Unknown date';
    final (label, icon, bg, fg) = switch (clearance.cleared) {
      true => ('Cleared', Icons.workspace_premium, colors.primary, colors.onPrimary),
      false => ('Not cleared', Icons.replay, colors.secondaryContainer, colors.onSecondaryContainer),
      null => ('Completed', Icons.check, colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: bg,
          child: Icon(icon, color: fg),
        ),
        title: Text(
          clearance.missionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('$label · ${clearance.persona}\n$dateStr'),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colors.onSurfaceVariant),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MissionClearanceScreen(clearance: clearance)),
          );
        },
      ),
    );
  }
}
