import 'package:flutter/material.dart';
import 'lab_screen.dart'; // AI Grammar Lab
import 'hangeul_lab_screen.dart'; // Hangeul Lab

class LabMenuScreen extends StatelessWidget {
  const LabMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Language Lab', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose a Lab to practice!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _buildMenuCard(
                context,
                title: 'Hangeul Lab',
                subtitle: 'Practice combining consonants and vowels.',
                icon: Icons.font_download_outlined,
                color: Colors.pink,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HangeulLabScreen()));
                },
              ),
              const SizedBox(height: 24),
              _buildMenuCard(
                context,
                title: 'AI Grammar Lab',
                subtitle: 'Explore grammar rules with our AI assistant.',
                icon: Icons.auto_awesome,
                color: Colors.deepPurple,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LabScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.shade100, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color.shade900)),
                  const SizedBox(height: 8),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade700, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
