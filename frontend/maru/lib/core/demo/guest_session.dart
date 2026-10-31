import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../storage/secure_storage.dart';

/// Guest entry could not finish. [message] is a sentence for the visitor.
class GuestEntryFailure implements Exception {
  final String message;
  const GuestEntryFailure(this.message);

  @override
  String toString() => message;
}

final Provider<GuestSession> guestSessionProvider = Provider<GuestSession>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ref.read(dioProvider).options.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));
  return GuestSession(dio, ref.watch(secureStorageProvider));
});

/// Web demo only: gets a guest token from `POST /api/demo/guest` and recovers once when it stops working.
class GuestSession {
  static const _guestPath = '/api/demo/guest';
  static const _retriedKey = 'demoGuestRetried';

  final Dio _dio;
  final SecureStorage _storage;
  Future<String>? _inFlight;

  GuestSession(this._dio, this._storage);

  /// Asks for a new guest token and saves it. Requests that arrive at the same time share one call,
  /// so a screen with several failing requests does not create several guests.
  Future<String> issueToken() {
    return _inFlight ??= _requestToken().whenComplete(() => _inFlight = null);
  }

  Future<String> _requestToken() async {
    try {
      final response = await _dio.post(_guestPath);
      final body = response.data;
      final token = body is Map ? body['data'] : null;
      if (token is String && token.isNotEmpty) {
        await _storage.saveTokens(accessToken: token);
        return token;
      }
    } on DioException catch (e) {
      debugPrint('Guest entry failed: ${e.type} ${e.response?.statusCode}');
      if (e.response?.statusCode == 429) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) {
          throw GuestEntryFailure(data['message'] as String);
        }
      }
      throw const GuestEntryFailure("Can't reach Maru right now. Please check your connection and try again.");
    }
    throw const GuestEntryFailure('Something went wrong while opening the demo. Please try again.');
  }

  /// Handles a 401/403: repeats the request once with a working token, using [client].
  /// Returns null when it should not or cannot retry, so the caller keeps the original error.
  /// A second failure comes out as the DioException of the retried request and is never retried again.
  Future<Response<dynamic>?> retryWithNewToken(Dio client, DioException error) async {
    final options = error.requestOptions;
    if (options.extra[_retriedKey] == true) return null;

    String? token = await _storage.getAccessToken();
    // Another request may have renewed the token while this one was on its way.
    if (token == null || options.headers['Authorization'] == 'Bearer $token') {
      try {
        token = await issueToken();
      } on GuestEntryFailure {
        return null;
      }
    }
    options.extra[_retriedKey] = true;
    options.headers['Authorization'] = 'Bearer $token';
    return client.fetch<dynamic>(options);
  }
}
