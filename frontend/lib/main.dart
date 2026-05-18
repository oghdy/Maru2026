import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    // Wrap app with ProviderScope for Riverpod state management
    const ProviderScope(
      child: MaruApp(),
    ),
  );
}

/// Main app widget for Maru Korean learning application
class MaruApp extends StatelessWidget {
  const MaruApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maru - Hangeul Master',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        // Primary color scheme
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF6366F1),

        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6366F1),
          elevation: 0,
          centerTitle: true,
        ),

        // Text theme with Korean fonts support
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'NotoSansKR',
          ),
          bodyMedium: TextStyle(
            fontFamily: 'NotoSansKR',
          ),
        ),

        // Visual density for comfortable touch targets
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // Scaffold background
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),

        // Color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF8B5CF6),
        ),
      ),

      // Set the home screen to HomeScreen
      home: const HomeScreen(),
    );
  }
}
