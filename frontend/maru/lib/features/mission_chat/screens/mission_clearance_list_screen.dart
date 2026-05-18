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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: clearancesAsync.when(
        data: (clearances) {
          if (clearances.isEmpty) {
            return const Center(
              child: Text(
                'No missions cleared yet.\nStart a Mission Chat to earn certificates! 🏆',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: clearances.length,
            itemBuilder: (context, index) {
              final clearance = clearances[index];
              return _buildClearanceCard(context, ref, clearance);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading certificates: $err')),
      ),
    );
  }

  Widget _buildClearanceCard(BuildContext context, WidgetRef ref, MissionClearanceModel clearance) {
    final dateStr = clearance.clearedAt != null 
        ? DateFormat('yyyy.MM.dd').format(clearance.clearedAt!)
        : 'Unknown Date';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.workspace_premium, color: Colors.white),
        ),
        title: Text(
          clearance.missionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('Role: ${clearance.persona}\nCleared on: $dateStr'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        isThreeLine: true,
        onTap: () {
          // Setting the state manually to reuse the same screen
          ref.read(missionChatProvider.notifier).state = 
              MissionChatState(status: MissionChatStatus.cleared, clearance: clearance);
          
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MissionClearanceScreen()),
          );
        },
      ),
    );
  }
}
