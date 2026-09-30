import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/login_screen.dart';
import 'core/providers/auth_provider.dart';
import 'core/utils/globals.dart';
import 'features/profile/screens/profile_gate.dart';
// Note: We don't strictly need MainScreen here anymore if ProfileGate handles it

void main() {
  runApp(
    ProviderScope(
      // No automatic retries: Riverpod 3 retries failed providers for ~40s while
      // staying in `loading`, so an unreachable server looked like an endless
      // spinner. Screens show an error with a Retry button instead.
      retry: (retryCount, error) => null,
      child: const MaruApp(),
    ),
  );
}

class MaruApp extends ConsumerWidget {
  const MaruApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Maru',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B4EFF)),
        useMaterial3: true,
      ),
      home: _getHomeForState(authState),
    );
  }

  Widget _getHomeForState(AuthState state) {
    if (state == AuthState.loading || state == AuthState.initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (state == AuthState.authenticated) {
      return const ProfileGate();
    } else {
      return const LoginScreen();
    }
  }
}
