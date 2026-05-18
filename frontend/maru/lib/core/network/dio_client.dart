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
  
  // Set default Base URL. We assume emulator or real device configs.
  // 10.0.2.2 is used for Android emulator to hit localhost, for iOS simulator it's localhost.
  final baseUrl = kIsWeb ? 'http://localhost:8080' : (Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080');

  
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
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
           debugPrint('Dio Global Interceptor: Caught 401/403. Forcing logout...');
           
           // We need to defer the state change slightly to avoid building
           // state modifications during an existing build cycle,
           // but reading the provider here is safe.
           WidgetsBinding.instance.addPostFrameCallback((_) {
             scaffoldMessengerKey.currentState?.showSnackBar(
               const SnackBar(
                 content: Text('세션이 만료되었습니다. 다시 로그인해주세요.'),
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
