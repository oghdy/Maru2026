import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../providers/auth_provider.dart';
import '../utils/globals.dart';
import 'package:flutter/material.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final secureStorage = ref.watch(secureStorageProvider);
  
  // Base URL: `--dart-define=API_BASE_URL=https://...` (Railway 등) 이 있으면 우선 사용.
  // 없으면 로컬 개발용: Android 에뮬레이터는 10.0.2.2, iOS 시뮬레이터/웹은 localhost.
  // 로컬 포트는 `--dart-define=API_PORT=8081` 로 바꿀 수 있음 (worktree 세션별 서버 분리용).
  const envBaseUrl = String.fromEnvironment('API_BASE_URL');
  const localPort = String.fromEnvironment('API_PORT', defaultValue: '8080');
  final localHost = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';
  final baseUrl = envBaseUrl.isNotEmpty ? envBaseUrl : 'http://$localHost:$localPort';

  
  dio.options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60), // Gemini API 첫 호출(캐시 미스)은 최대 30초 소요
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    }
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Retrieve token from secure storage
        final token = await secureStorage.getAccessToken();
        
        // If token exists, inject Bearer token to headers
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options); // Continue request
      },
      onError: (DioException e, handler) async {
        // Handle global errors here e.g token expiry (401, 403)
        // A failed sign-in (/api/auth/*) is reported on the login screen, not
        // treated as an expired session.
        final isAuthCall = e.requestOptions.path.startsWith('/api/auth/');
        if (!isAuthCall && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
           debugPrint('Dio Global Interceptor: Caught 401/403. Forcing logout...');
           
           // We need to defer the state change slightly to avoid building
           // state modifications during an existing build cycle,
           // but reading the provider here is safe.
           WidgetsBinding.instance.addPostFrameCallback((_) {
             scaffoldMessengerKey.currentState?.showSnackBar(
               const SnackBar(
                 content: Text('Your session has expired. Please log in again.'),
                 backgroundColor: Colors.redAccent,
                 duration: Duration(seconds: 3),
               ),
             );
             ref.read(authProvider.notifier).logout();
           });
        }
        return handler.next(e); // Continue error
      }
    )
  );
  
  // Logger interceptor (Optional for debugging)
  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

  return dio;
});
