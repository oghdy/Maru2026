import 'package:dio/dio.dart';
import 'package:maru/features/stats/models/user_stats_model.dart';

class UserStatsRepository {
  final Dio _dio;

  UserStatsRepository(this._dio);

  Future<UserStatsModel> getUserStats() async {
    try {
      final response = await _dio.get('/api/me/stats');
      
      if (response.statusCode == 200) {
        // API response format: { "status": 200, "message": "...", "data": { ... } }
        final data = response.data['data'];
        return UserStatsModel.fromJson(data);
      } else {
        throw Exception('Failed to load user stats');
      }
    } catch (e) {
      throw Exception('Error fetching user stats: $e');
    }
  }
}
