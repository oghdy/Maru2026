import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/login_screen.dart';
import 'core/demo/demo_fonts.dart';
import 'core/demo/demo_mode.dart';
import 'core/providers/auth_provider.dart';
import 'core/utils/globals.dart';
import 'features/profile/screens/profile_gate.dart';
import 'screens/auth/demo_entry_screen.dart';
// Note: We don't strictly need MainScreen here anymore if ProfileGate handles it

Future<void> main() async {
  if (kDemoMode && kIsWeb) {
    WidgetsFlutterBinding.ensureInitialized();
    await preloadDemoFonts();
  }
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

const _brandPurple = Color(0xFF6B4EFF);

class MaruApp extends ConsumerWidget {
  const MaruApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: kDemoMode ? 'Maru - Learn Korean' : 'Maru',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        // fromSeed() turns the seed into a muted tone; keep the exact brand
        // purple as primary (white text on it passes contrast).
        colorScheme: ColorScheme.fromSeed(seedColor: _brandPurple).copyWith(
          primary: _brandPurple,
          onPrimary: Colors.white,
        ),
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
    } else if (kDemoMode) {
      return const DemoEntryScreen();
    } else {
      return const LoginScreen();
    }
  }
}
