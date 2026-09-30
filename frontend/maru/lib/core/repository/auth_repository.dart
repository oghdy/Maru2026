import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, secureStorage);
});

class AuthRepository {
  final Dio _dio;
  final SecureStorage _secureStorage;

  AuthRepository(this._dio, this._secureStorage);

  /// Exchanges a Google/Apple id token for a Maru JWT.
  /// Returns null on success, otherwise a short English message for the login
  /// screen. Never throws (a thrown TypeError used to leave the app spinning).
  Future<String?> verifyIdToken(String provider, String idToken) async {
    try {
      final response = await _dio.post(
        '/api/auth/$provider',
        data: {
          'idToken': idToken,
        },
      );

      // ApiResponse<String> returns the JWT in 'data'; the server used to send
      // 200 with data: null when verification failed.
      final body = response.data;
      final jwtToken = body is Map ? body['data'] : null;
      if (response.statusCode == 200 && jwtToken is String && jwtToken.isNotEmpty) {
        await _secureStorage.saveTokens(accessToken: jwtToken);
        return null;
      }
      return "We couldn't verify your account. Please try again.";
    } on DioException catch (e) {
      debugPrint('AuthRepository Error: $e');
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        return "We couldn't verify your account. Please try again.";
      }
      return "Can't reach Maru right now. Please check your connection and try again.";
    } catch (e) {
      debugPrint('AuthRepository unexpected error: $e');
      return 'Something went wrong while signing in. Please try again.';
    }
  }

  Future<void> logout() async {
    await _secureStorage.deleteTokens();
  }
}
