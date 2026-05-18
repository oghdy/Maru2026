import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maru/core/network/dio_client.dart';
import 'package:maru/features/lab/repositories/ai_lab_repository.dart';

final aiLabRepositoryProvider = Provider<AiLabRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AiLabRepository(dio);
});
