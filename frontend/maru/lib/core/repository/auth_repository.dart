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

  Future<bool> verifyIdToken(String provider, String idToken) async {
    try {
      final response = await _dio.post(
        '/api/auth/$provider',
        data: {
          'idToken': idToken,
        },
      );

      if (response.statusCode == 200) {
        // ApiResponse<String> returns JWT string in 'data' field
        final jwtToken = response.data['data'] as String;
        
        // Save the Maru JWT in secure storage
        await _secureStorage.saveTokens(accessToken: jwtToken);
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('AuthRepository Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.deleteTokens();
  }
}
