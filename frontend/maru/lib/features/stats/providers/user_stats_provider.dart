import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/core/network/dio_client.dart';
import 'package:maru/features/stats/models/user_stats_model.dart';
import 'package:maru/features/stats/repositories/user_stats_repository.dart';

final userStatsRepositoryProvider = Provider<UserStatsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return UserStatsRepository(dio);
});

final userStatsProvider = FutureProvider<UserStatsModel>((ref) async {
  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.getUserStats();
});
