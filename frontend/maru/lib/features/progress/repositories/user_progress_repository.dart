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
}
