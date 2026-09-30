import 'package:dio/dio.dart';
import 'package:maru/features/progress/models/user_progress_model.dart';

class UserProgressRepository {
  final Dio _dio;

  UserProgressRepository(this._dio);

  Future<UserProgressResponseModel> saveProgress(String lessonId, UserProgressRequestModel request) async {
    try {
      final response = await _dio.post(
        '/api/progress/lessons/$lessonId',
        data: request.toJson(),
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        return UserProgressResponseModel.fromJson(data);
      } else {
        throw Exception('Failed to save progress');
      }
    } catch (e) {
      throw Exception('Error saving progress: $e');
    }
  }

  /// My progress records for a unit. Lessons without a record are not started.
  Future<List<UserProgressResponseModel>> getUnitProgress(int unitId) async {
    final response = await _dio.get('/api/progress/lessons', queryParameters: {'unitId': unitId});
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => UserProgressResponseModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
