import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lesson_provider.dart';
import 'lesson_list_screen.dart';

/// Units shown in the app. Title and lesson count come from the server
/// (`unitTitle` of the unit's lessons); a unit with no lessons is shown locked.
const _unitIds = [0, 1, 2, 3];

class UnitSelectionScreen extends ConsumerWidget {
  const UnitSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Unit', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24.0),
        itemCount: _unitIds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _UnitCard(unitId: _unitIds[index]),
      ),
    );
  }
}

class _UnitCard extends ConsumerWidget {
  final int unitId;

  const _UnitCard({required this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final lessonsAsync = ref.watch(unitLessonsProvider(unitId));

    final lessons = lessonsAsync.asData?.value;
    final isLocked = lessons != null && lessons.isEmpty;
    final dbTitle = (lessons != null && lessons.isNotEmpty) ? lessons.first.unitTitle.trim() : '';
    final title = isLocked ? 'Coming soon' : (dbTitle.isNotEmpty ? dbTitle : 'Unit $unitId');

    final String subtitle;
    VoidCallback? onTap;
    if (lessonsAsync.isLoading) {
      subtitle = 'Loading…';
    } else if (lessonsAsync.hasError) {
      subtitle = "Couldn't load lessons. Tap to retry.";
      onTap = () => ref.invalidate(unitLessonsProvider(unitId));
    } else if (isLocked) {
      subtitle = 'New lessons are being prepared.';
    } else {
      final n = lessons!.length;
      subtitle = '$n ${n == 1 ? 'lesson' : 'lessons'}';
      onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonListScreen(unitId: unitId)));
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLocked ? colorScheme.surfaceContainerLow : colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isLocked ? Colors.transparent : colorScheme.outlineVariant, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isLocked ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isLocked
                  ? Icon(Icons.lock, color: colorScheme.outline)
                  : Text(
                      '$unitId',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                    ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unit $unitId',
                    style: TextStyle(
                      color: isLocked ? colorScheme.outline : colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: lessonsAsync.hasError ? colorScheme.error : colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null && !lessonsAsync.hasError) Icon(Icons.chevron_right, color: colorScheme.outline),
            if (lessonsAsync.hasError) Icon(Icons.refresh, color: colorScheme.error),
          ],
        ),
      ),
    );
  }
}
