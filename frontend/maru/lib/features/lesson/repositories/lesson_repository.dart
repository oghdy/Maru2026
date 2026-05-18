import 'package:dio/dio.dart';
import '../models/lesson_model.dart';

class LessonRepository {
  final Dio _dio;

  LessonRepository(this._dio);

  Future<List<LessonModel>> getLessonsByUnitId(int unitId) async {
    try {
      final response = await _dio.get('/api/units/$unitId/lessons');
      
      // ApiResponse wrapper { status, message, data }
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => LessonModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load lessons: ${e.message}');
    } catch (e) {
      throw Exception('Failed to parse lessons: $e');
    }
  }
}
