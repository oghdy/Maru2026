import 'package:flutter/material.dart';
import 'lesson_list_screen.dart';

class UnitSelectionScreen extends StatelessWidget {
  const UnitSelectionScreen({Key? key}) : super(key: key);

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
          'Select Unit',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildUnitCard(
            context,
            unitNumber: 0,
            title: 'Hangeul Basics',
            description: 'Learn consonants, vowels, and final consonants',
            progress: 0.0, // 나중에 실제 데이터 연동 필요
            isLocked: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LessonListScreen(unitId: 0),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildUnitCard(
            context,
            unitNumber: 1,
            title: 'Basic Greetings',
            description: 'Hello, nice to meet you',
            progress: 0.0,
            isLocked: true,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildUnitCard(
            context,
            unitNumber: 2,
            title: 'Self Introduction',
            description: 'I am a student',
            progress: 0.0,
            isLocked: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(
    BuildContext context, {
    required int unitNumber,
    required String title,
    required String description,
    required double progress,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLocked
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please complete the previous unit first!')),
              );
            }
          : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey[300] : const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock, color: Colors.grey)
                    : Text(
                        '$unitNumber',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unit $unitNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey : const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey : const Color(0xFF1F2937),
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                  const SizedBox(height: 4),
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
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}


