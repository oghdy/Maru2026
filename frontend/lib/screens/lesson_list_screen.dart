import 'package:flutter/material.dart';
import '../unit0/screens/lesson_screen.dart';

class LessonListScreen extends StatelessWidget {
  final int unitId;

  const LessonListScreen({
    Key? key,
    required this.unitId,
  }) : super(key: key);

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
        title: Text(
          'Unit $unitId Lessons',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Vowels'),
          _buildLessonItem(context, 1, 'Basic Vowels', 'unit0_lesson1.json', Icons.circle_outlined),
          _buildLessonItem(context, 2, 'Derived Vowels', 'unit0_lesson2.json', Icons.circle_outlined),
          _buildLessonItem(context, 3, 'Remaining Vowels', 'unit0_lesson3.json', Icons.circle_outlined),
          _buildLessonItem(context, 4, 'Compound Vowels', 'unit0_lesson4.json', Icons.circle_outlined),
          
          const SizedBox(height: 20),
          _buildSectionHeader('Consonants'),
          _buildLessonItem(context, 5, 'Basic Consonants', 'unit0_lesson5.json', Icons.abc),
          _buildLessonItem(context, 6, 'Aspirated Sounds', 'unit0_lesson6.json', Icons.abc),
          _buildLessonItem(context, 7, 'Tense Sounds + Special', 'unit0_lesson7.json', Icons.abc),
          _buildLessonItem(context, 8, 'Consonant Review', 'unit0_lesson8.json', Icons.refresh),
          
          const SizedBox(height: 20),
          _buildSectionHeader('Final Consonants'),
          _buildLessonItem(context, 9, 'Final Consonant Basics', 'unit0_lesson9.json', Icons.book),
          _buildLessonItem(context, 10, 'Final Consonant Advanced', 'unit0_lesson10.json', Icons.book),
          _buildLessonItem(context, 11, 'Complex Final Consonants', 'unit0_lesson11.json', Icons.book),
          _buildLessonItem(context, 12, 'Complete Review', 'unit0_lesson12.json', Icons.emoji_events),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B7280),
          fontFamily: 'NotoSansKR',
        ),
      ),
    );
  }

  Widget _buildLessonItem(
    BuildContext context,
    int lessonNum,
    String title,
    String jsonFile,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1)),
        ),
        title: Text(
          'Lesson $lessonNum',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansKR',
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9CA3AF)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonScreen(
                jsonPath: 'assets/unit0/data/lessons/$jsonFile',
              ),
            ),
          );
        },
      ),
    );
  }
}


