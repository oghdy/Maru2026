import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Keep in sync with `version:` in pubspec.yaml (no package_info plugin in this app).
const _appVersion = '1.0.0';

/// Settings tab: nickname, log out, app version.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).asData?.value;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Nickname'),
            subtitle: Text(profile?.nickname ?? '—'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: profile == null ? null : () => _editNickname(context, ref, profile.nickname ?? ''),
          ),
          if (profile != null && profile.email.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Email'),
              subtitle: Text(profile.email),
            ),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text('Log out', style: TextStyle(color: colorScheme.error)),
            onTap: () => _confirmLogout(context, ref),
          ),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App version'),
            subtitle: Text(_appVersion),
          ),
        ],
      ),
    );
  }

  Future<void> _editNickname(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change nickname'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(hintText: 'Nickname'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == current) return;
    final ok = await ref.read(profileProvider.notifier).updateProfile(newName);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Nickname updated.' : "Couldn't update your nickname. Please try again.")),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue learning.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true) await ref.read(authProvider.notifier).logout();
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
