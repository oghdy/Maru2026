import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../screens/home/main_screen.dart';
import '../providers/profile_provider.dart';
import 'profile_setup_screen.dart';

class ProfileGate extends ConsumerWidget {
  const ProfileGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);

    return profileState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => _GateMessage(
        icon: Icons.cloud_off,
        title: "Can't reach Maru right now",
        message: 'Please check your internet connection and try again.',
        onRetry: () => ref.read(profileProvider.notifier).fetchProfile(),
      ),
      data: (profile) {
        if (profile == null) {
          // /api/me returned 404: the account no longer exists on the server
          return const _GateMessage(
            icon: Icons.person_off_outlined,
            title: 'Account not found',
            message: 'Please log in again.',
          );
        }

        if (profile.isProfileComplete) {
          return const MainScreen();
        } else {
          return const ProfileSetupScreen();
        }
      },
    );
  }
}

/// Full-screen message with optional Retry and an always-available Log out,
/// so the user is never stuck on this screen.
class _GateMessage extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _GateMessage({required this.icon, required this.title, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.error, size: 64),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (onRetry != null) ...[
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
