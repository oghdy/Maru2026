import 'package:flutter/material.dart';
import '../unit0/screens/hangeul_master_screen.dart';

class LabMenuScreen extends StatelessWidget {
  const LabMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Korean Lab',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildLabCard(
              context,
              title: 'Hangeul Lab',
              description: 'Freely combine consonants and vowels',
              icon: Icons.science,
              color: const Color(0xFFEC4899),
              isLocked: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HangeulMasterScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildLabCard(
              context,
              title: 'Grammar Lab',
              description: 'Understand and experiment with sentence structure',
              icon: Icons.rule,
              color: const Color(0xFF8B5CF6),
              isLocked: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLocked
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon!')),
              );
            }
          : onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey[300] : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isLocked ? Icons.lock : icon,
                color: isLocked ? Colors.grey : color,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey : const Color(0xFF1F2937),
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isLocked ? Colors.grey[400] : const Color(0xFF6B7280),
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


