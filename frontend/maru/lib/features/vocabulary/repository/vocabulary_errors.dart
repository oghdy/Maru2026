import 'package:dio/dio.dart';

/// 사용자에게 보여줄 영어 오류 문구. 예외 원문(DioException ...)은 노출하지 않는다.
String friendlyVocabularyError(Object? error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Couldn't reach the server.\nPlease check your connection and try again.";
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 404) {
          return 'There are no words here yet.';
        }
        break;
      default:
        break;
    }
  }
  return 'Something went wrong.\nPlease try again.';
}
