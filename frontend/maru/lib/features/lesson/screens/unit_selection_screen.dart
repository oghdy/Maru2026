import 'package:flutter/material.dart';
import 'lesson_list_screen.dart';

class UnitSelectionScreen extends StatelessWidget {
  const UnitSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select a Unit', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildUnitCard(
            context,
            unitId: 0,
            title: 'Basics of Hangeul',
            subtitle: 'Learn vowels, consonants, and combinations.',
            isLocked: false,
          ),
          const SizedBox(height: 16),
          _buildUnitCard(
            context,
            unitId: 1,
            title: 'Basic Greetings',
            subtitle: 'Hello, nice to meet you.',
            isLocked: false, // Unlocked since we have backend logic for this
          ),
          const SizedBox(height: 16),
          _buildUnitCard(
            context,
            unitId: 2,
            title: 'Self Introduction',
            subtitle: 'I am a student.',
            isLocked: false,
          ),
          const SizedBox(height: 16),
          _buildUnitCard(
            context,
            unitId: 3,
            title: 'Ordering Food',
            subtitle: 'Please give me this.',
            isLocked: false,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, {required int unitId, required String title, required String subtitle, required bool isLocked}) {
    return GestureDetector(
      onTap: () {
        // Allow tap even if locked (Duolingo style jump)
        Navigator.push(context, MaterialPageRoute(builder: (_) => LessonListScreen(unitId: unitId)));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isLocked ? Colors.transparent : Colors.grey.shade200, width: 2),
          boxShadow: isLocked ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.shade300 : Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isLocked
                  ? const Icon(Icons.lock, color: Colors.grey)
                  : Text('$unitId', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unit $unitId', style: TextStyle(color: isLocked ? Colors.grey.shade500 : Colors.deepPurple.shade400, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isLocked ? Colors.grey.shade600 : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isLocked ? Colors.transparent : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
