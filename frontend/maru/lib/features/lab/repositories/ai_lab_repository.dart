import 'package:dio/dio.dart';
import 'package:maru/features/lab/models/ai_lab_model.dart';

class AiLabRepository {
  final Dio _dio;

  AiLabRepository(this._dio);

  Future<List<AiLabExploreResponseModel>> explore(AiLabExploreRequestModel request) async {
    try {
      final response = await _dio.post(
        '/api/lab/explore',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        // Expected an ApiResponse<List<AiLabExploreResponseDto>>
        final List<dynamic> data = response.data['data'];
        return data.map((json) => AiLabExploreResponseModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to explore AI Lab variations');
      }
    } catch (e) {
      throw Exception('Error exploring AI Lab: $e');
    }
  }

  Future<AiLabCombineResponseModel> combine(AiLabCombineRequestModel request) async {
    try {
      final response = await _dio.post(
        '/api/lab/combine',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        // Expected an ApiResponse<AiLabCombineResponseDto>
        final Map<String, dynamic> data = response.data['data'];
        return AiLabCombineResponseModel.fromJson(data);
      } else {
        throw Exception('Failed to combine AI Lab modifiers');
      }
    } catch (e) {
      throw Exception('Error combining AI Lab modifiers: $e');
    }
  }
}
