import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:maru/features/lab/models/ai_lab_model.dart';

/// Failure shown to the learner. [message] is always a user-facing English sentence
/// (never the raw exception text).
class AiLabFailure implements Exception {
  final String message;

  /// false = the input itself was rejected (400); sending it again won't help.
  final bool retryable;

  const AiLabFailure(this.message, {this.retryable = true});

  static const generic = AiLabFailure('Something went wrong. Please try again.');
  static const network = AiLabFailure("Couldn't reach the server. Check your connection and try again.");
  static const timeout = AiLabFailure('The AI took too long to respond. Please try again.');
  static const badResponse = AiLabFailure('The AI returned an unexpected answer. Please try again.');

  @override
  String toString() => message;
}

class AiLabRepository {
  final Dio _dio;

  AiLabRepository(this._dio);

  Future<List<AiLabExploreResponseModel>> explore(AiLabExploreRequestModel request) async {
    final data = await _post('/api/lab/explore', request.toJson());
    if (data is! List || data.isEmpty) throw AiLabFailure.badResponse;
    return data.whereType<Map<String, dynamic>>().map(AiLabExploreResponseModel.fromJson).toList();
  }

  Future<AiLabCombineResponseModel> combine(AiLabCombineRequestModel request) async {
    final data = await _post('/api/lab/combine', request.toJson());
    if (data is! Map<String, dynamic>) throw AiLabFailure.badResponse;
    return AiLabCombineResponseModel.fromJson(data);
  }

  /// POSTs and returns `ApiResponse.data`. Every failure is converted to [AiLabFailure].
  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(path, data: body);
      final json = response.data;
      if (json is! Map<String, dynamic>) throw AiLabFailure.badResponse;
      return json['data'];
    } on DioException catch (e) {
      debugPrint('AI Lab $path failed: ${e.type} ${e.response?.statusCode}');
      throw _toFailure(e);
    } on AiLabFailure {
      rethrow;
    } catch (e) {
      debugPrint('AI Lab $path failed: $e');
      throw AiLabFailure.badResponse;
    }
  }

  AiLabFailure _toFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return AiLabFailure.network;
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AiLabFailure.timeout;
      default:
        break;
    }

    final status = e.response?.statusCode;
    // 401/403 are handled globally by dioProvider (logout + snackbar).
    if (status == 401 || status == 403) {
      return const AiLabFailure('Your session has expired. Please sign in again.');
    }
    // For these statuses the server sends an English user-facing message (API_CONTRACT §1-5).
    const userMessageStatuses = {400, 502, 503, 504};
    final serverMessage = _serverMessage(e.response?.data);
    if (status != null && userMessageStatuses.contains(status) && serverMessage != null) {
      return AiLabFailure(serverMessage, retryable: status != 400);
    }
    switch (status) {
      case 400:
        return const AiLabFailure('Please check your sentence and try again.', retryable: false);
      case 504:
        return AiLabFailure.timeout;
      case 502:
        return AiLabFailure.badResponse;
      case 503:
        return const AiLabFailure('The AI service is unavailable right now. Please try again in a moment.');
      default:
        return AiLabFailure.generic;
    }
  }

  String? _serverMessage(dynamic data) {
    if (data is Map && data['message'] is String) {
      final message = (data['message'] as String).trim();
      if (message.isNotEmpty) return message;
    }
    return null;
  }
}
