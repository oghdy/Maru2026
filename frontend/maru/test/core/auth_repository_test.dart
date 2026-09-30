import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/core/repository/auth_repository.dart';
import 'package:maru/core/storage/secure_storage.dart';

class _FakeStorage extends SecureStorage {
  String? saved;
  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async => saved = accessToken;
}

/// Answers every request with [status] and [body], or throws a connection error.
class _FakeAdapter implements HttpClientAdapter {
  final int status;
  final Object? body;
  final bool connectionError;
  _FakeAdapter({this.status = 200, this.body, this.connectionError = false});

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (connectionError) {
      throw DioException.connectionError(requestOptions: options, reason: 'refused');
    }
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

AuthRepository _repo(_FakeAdapter adapter, _FakeStorage storage) =>
    AuthRepository(Dio()..httpClientAdapter = adapter, storage);

void main() {
  test('200 with a JWT → success and token saved', () async {
    final storage = _FakeStorage();
    final error = await _repo(_FakeAdapter(body: {'status': 200, 'message': 'ok', 'data': 'jwt.abc'}), storage)
        .verifyIdToken('google', 'id');
    expect(error, isNull);
    expect(storage.saved, 'jwt.abc');
  });

  test('200 with data: null (old server behaviour) → message, no throw', () async {
    final storage = _FakeStorage();
    final error = await _repo(_FakeAdapter(body: {'status': 401, 'message': 'bad', 'data': null}), storage)
        .verifyIdToken('google', 'id');
    expect(error, contains("couldn't verify"));
    expect(storage.saved, isNull);
  });

  test('401 (new server behaviour) → verify message', () async {
    final error = await _repo(_FakeAdapter(status: 401, body: {'status': 401, 'message': 'bad', 'data': null}), _FakeStorage())
        .verifyIdToken('apple', 'id');
    expect(error, contains("couldn't verify"));
  });

  test('server unreachable → connection message', () async {
    final error = await _repo(_FakeAdapter(connectionError: true), _FakeStorage()).verifyIdToken('google', 'id');
    expect(error, contains("Can't reach Maru"));
  });
}
