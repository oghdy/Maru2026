import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      error: (err, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Failed to load profile.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => ref.read(profileProvider.notifier).fetchProfile(),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('User profile not found.')));
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
