import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/core/network/dio_client.dart';
import 'package:maru/features/progress/models/user_progress_model.dart';
import 'package:maru/features/progress/repositories/user_progress_repository.dart';

final userProgressRepositoryProvider = Provider<UserProgressRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return UserProgressRepository(dio);
});

final progressServiceProvider = Provider<UserProgressService>((ref) {
  final repository = ref.watch(userProgressRepositoryProvider);
  return UserProgressService(repository);
});

class UserProgressService {
  final UserProgressRepository _repository;

  UserProgressService(this._repository);

  Future<UserProgressResponseModel> submitCompletion({
    required String lessonId,
    required int score,
    required int timeSpentSeconds,
  }) async {
    final request = UserProgressRequestModel(
      status: 'completed',
      currentStep: 999, // Max step to mark as finished
      score: score,
      timeSpentSeconds: timeSpentSeconds,
    );
    
    return _repository.saveProgress(lessonId, request);
  }
}
