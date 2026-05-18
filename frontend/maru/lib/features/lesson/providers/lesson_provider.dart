import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/lesson_model.dart';
import '../repositories/lesson_repository.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LessonRepository(dio);
});

// A FutureProvider that fetches the lessons for a specific unit (e.g., Unit 1)
final unitLessonsProvider = FutureProvider.family<List<LessonModel>, int>((ref, unitId) async {
  final repository = ref.read(lessonRepositoryProvider);
  return repository.getLessonsByUnitId(unitId);
});
