import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lesson_provider.dart';
import 'lesson_screen.dart';

class LessonListScreen extends ConsumerWidget {
  final int unitId; // E.g., 1

  const LessonListScreen({super.key, required this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch lessons from backend using Riverpod
    final lessonsAsync = ref.watch(unitLessonsProvider(unitId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Unit $unitId Lessons', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                '레슨 데이터를 불러오지 못했습니다.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '인터넷 연결을 확인하고 다시 시도해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        data: (lessons) {
          if (lessons.isEmpty) {
            return const Center(child: Text('No lessons found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.deepPurple.shade50,
                    child: Text('${lesson.orderNum}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
                  ),
                  title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(lesson.description, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMockLessonCard(BuildContext context, int orderNum, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade50,
          child: Text('$orderNum', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
        ),
        title: Text('Lesson $orderNum\n$title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hangeul Lesson mock content coming soon!')));
        },
      ),
    );
  }
}
