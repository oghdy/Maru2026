import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/shared/characters/maru_character.dart';
import '../../progress/providers/user_progress_provider.dart';
import '../../vocabulary/widgets/vocab_style.dart' show FadeSlideIn;
import '../providers/lesson_provider.dart';
import '../widgets/lesson_style.dart';
import 'lesson_list_screen.dart';

/// Units shown in the app. Title and lesson count come from the server
/// (`unitTitle` of the unit's lessons); a unit with no lessons is shown locked.
const _unitIds = [0, 1, 2, 3];

class UnitSelectionScreen extends ConsumerWidget {
  const UnitSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = lessonReduceMotion(context);
    Widget entrance(int index, Widget child) =>
        reduceMotion ? child : FadeSlideIn(index: index, child: child);

    return Scaffold(
      backgroundColor: missionPageBackground(context),
      appBar: lessonAppBar(context, title: 'Korean Lessons'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          entrance(0, const _LessonsHero()),
          for (var i = 0; i < _unitIds.length; i++)
            entrance(i + 1, Padding(padding: const EdgeInsets.only(top: 12), child: _UnitCard(unitId: _unitIds[i]))),
        ],
      ),
    );
  }
}

/// Gradient banner, same family as Mission Chat's scenario hero.
class _LessonsHero extends StatelessWidget {
  const _LessonsHero();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: BoxDecoration(
        gradient: missionHeroGradient(context),
        borderRadius: BorderRadius.circular(missionCardRadius),
        boxShadow: [
          BoxShadow(color: colors.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a unit',
                  style: TextStyle(color: colors.onPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tokki builds whole blocks, Turtle splits them into parts.',
                  style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.88), fontSize: 14, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const MaruCharacter(kind: MaruCharacterKind.rabbit, mood: MaruMood.idle, size: 52, interactive: false),
          const MaruCharacter(kind: MaruCharacterKind.turtle, mood: MaruMood.idle, size: 52, interactive: false),
        ],
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
    // Progress is secondary: if it fails to load the card just shows no progress
    final progress = ref.watch(unitProgressProvider(unitId)).asData?.value ?? const {};

    final lessons = lessonsAsync.asData?.value;
    final isLocked = lessons != null && lessons.isEmpty;
    final dbTitle = (lessons != null && lessons.isNotEmpty) ? lessons.first.unitTitle.trim() : '';
    final title = isLocked ? 'Coming soon' : (dbTitle.isNotEmpty ? dbTitle : 'Unit $unitId');

    final total = lessons?.length ?? 0;
    final records = lessons == null ? const [] : lessons.map((l) => progress[l.lessonId]).whereType<Object>().toList();
    final done = lessons?.where((l) => progress[l.lessonId]?.status == 'completed').length ?? 0;
    final started = records.length - done;
    final stars = lessons?.fold<int>(
          0,
          (sum, l) => sum + (progress[l.lessonId]?.status == 'completed' ? progress[l.lessonId]!.starsEarned : 0),
        ) ??
        0;
    final allDone = total > 0 && done == total;

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
      if (done > 0) {
        subtitle = '$done of $n ${n == 1 ? 'lesson' : 'lessons'} complete';
      } else if (started > 0) {
        subtitle = '$n ${n == 1 ? 'lesson' : 'lessons'} · $started in progress';
      } else {
        subtitle = '$n ${n == 1 ? 'lesson' : 'lessons'}';
      }
      onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonListScreen(unitId: unitId)));
    }

    return LessonPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: isLocked
            ? BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(missionCardRadius),
              )
            : missionCardDecoration(context),
        child: Row(
          children: [
            if (isLocked)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
                child: Icon(Icons.lock_rounded, color: colorScheme.outline),
              )
            else
              LessonRing(
                size: 56,
                strokeWidth: 5,
                value: total == 0 ? 0 : done / total,
                color: allDone ? lessonSuccess() : colorScheme.primary,
                trackColor: allDone ? lessonSuccessSoft() : colorScheme.primaryContainer,
                child: allDone
                    ? Icon(Icons.check_rounded, color: lessonSuccess(), size: 28)
                    : Text(
                        '$unitId',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colorScheme.primary),
                      ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LessonOverline('Unit $unitId', color: isLocked ? colorScheme.outline : colorScheme.primary),
                  const SizedBox(height: 3),
                  LessonText(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isLocked ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: lessonsAsync.hasError ? colorScheme.error : colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  if (stars > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: lessonStar()),
                        const SizedBox(width: 3),
                        Text(
                          '$stars / ${total * 3}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null && !lessonsAsync.hasError)
              Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            if (lessonsAsync.hasError) Icon(Icons.refresh_rounded, color: colorScheme.error),
          ],
        ),
      ),
    );
  }
}
