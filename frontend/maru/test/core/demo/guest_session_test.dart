import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maru/core/demo/demo_mode.dart';
import 'package:maru/core/demo/guest_session.dart';
import 'package:maru/core/storage/secure_storage.dart';

class _FakeStorage extends SecureStorage {
  String? token;
  _FakeStorage([this.token]);

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async => token = accessToken;

  @override
  Future<String?> getAccessToken() async => token;
}

/// Records calls and answers with the next status/body.
class _FakeAdapter implements HttpClientAdapter {
  final int status;
  final Object? body;
  final bool connectionError;
  int calls = 0;
  final List<String?> authHeaders = [];

  _FakeAdapter({this.status = 200, this.body, this.connectionError = false});

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    authHeaders.add(options.headers['Authorization'] as String?);
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

DioException _authError(String sentToken, {Map<String, dynamic>? extra}) {
  final options = RequestOptions(
    path: '/api/me',
    baseUrl: 'http://test',
    headers: {'Authorization': 'Bearer $sentToken'},
    extra: extra,
  );
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: 403),
    type: DioExceptionType.badResponse,
  );
}

Map<String, dynamic> _ok(String token) => {'status': 200, 'message': 'Success', 'data': token};

void main() {
  test('default build: demo mode is off', () {
    // flutter test without --dart-define=DEMO_MODE=true, same as the mobile builds
    expect(kDemoMode, isFalse);
  });

  group('issueToken', () {
    test('saves the token from ApiResponse.data', () async {
      final storage = _FakeStorage();
      final session = GuestSession(Dio()..httpClientAdapter = _FakeAdapter(body: _ok('guest-jwt')), storage);

      expect(await session.issueToken(), 'guest-jwt');
      expect(storage.token, 'guest-jwt');
    });

    test('requests at the same time share one call (one guest, not many)', () async {
      final adapter = _FakeAdapter(body: _ok('guest-jwt'));
      final session = GuestSession(Dio()..httpClientAdapter = adapter, _FakeStorage());

      final tokens = await Future.wait([session.issueToken(), session.issueToken(), session.issueToken()]);

      expect(tokens, ['guest-jwt', 'guest-jwt', 'guest-jwt']);
      expect(adapter.calls, 1);
    });

    test('rate limit: shows the server sentence', () async {
      final adapter = _FakeAdapter(status: 429, body: {'status': 429, 'message': 'Lots of visitors just arrived.', 'data': null});
      final session = GuestSession(Dio()..httpClientAdapter = adapter, _FakeStorage());

      expect(
        session.issueToken(),
        throwsA(isA<GuestEntryFailure>().having((e) => e.message, 'message', 'Lots of visitors just arrived.')),
      );
    });

    test('network failure: a plain sentence, never the exception text', () async {
      final session = GuestSession(Dio()..httpClientAdapter = _FakeAdapter(connectionError: true), _FakeStorage());

      await expectLater(
        session.issueToken(),
        throwsA(isA<GuestEntryFailure>().having((e) => e.message, 'message', isNot(contains('DioException')))),
      );
      // A later Retry starts a new request
      expect(session.issueToken(), throwsA(isA<GuestEntryFailure>()));
    });

    test('a 200 without a token is a failure', () async {
      final session = GuestSession(Dio()..httpClientAdapter = _FakeAdapter(body: {'status': 200, 'data': null}), _FakeStorage());
      expect(session.issueToken(), throwsA(isA<GuestEntryFailure>()));
    });
  });

  group('retryWithNewToken', () {
    test('gets a new token and repeats the request once with it', () async {
      final storage = _FakeStorage('expired');
      final guestApi = _FakeAdapter(body: _ok('fresh'));
      final client = Dio()..httpClientAdapter = _FakeAdapter(body: {'nickname': 'Guest'});
      final session = GuestSession(Dio()..httpClientAdapter = guestApi, storage);

      final response = await session.retryWithNewToken(client, _authError('expired'));

      expect(response?.data['nickname'], 'Guest');
      expect(guestApi.calls, 1);
      expect((client.httpClientAdapter as _FakeAdapter).authHeaders.single, 'Bearer fresh');
    });

    test('a request that was already retried is not retried again (no loop)', () async {
      final guestApi = _FakeAdapter(body: _ok('fresh'));
      final client = Dio()..httpClientAdapter = _FakeAdapter(body: {});
      final session = GuestSession(Dio()..httpClientAdapter = guestApi, _FakeStorage('t'));

      final response = await session.retryWithNewToken(client, _authError('t', extra: {'demoGuestRetried': true}));

      expect(response, isNull);
      expect(guestApi.calls, 0);
      expect((client.httpClientAdapter as _FakeAdapter).calls, 0);
    });

    test('a retry that fails again surfaces as an error and stops', () async {
      final guestApi = _FakeAdapter(body: _ok('fresh'));
      final clientAdapter = _FakeAdapter(status: 403, body: {'status': 403});
      final client = Dio()..httpClientAdapter = clientAdapter;
      final session = GuestSession(Dio()..httpClientAdapter = guestApi, _FakeStorage('expired'));
      final error = _authError('expired');

      await expectLater(session.retryWithNewToken(client, error), throwsA(isA<DioException>()));

      expect(clientAdapter.calls, 1);
      expect(guestApi.calls, 1);
      expect(await session.retryWithNewToken(client, error), isNull); // flagged now
      expect(clientAdapter.calls, 1);
    });

    test('token already renewed by another request: reuses it, no new guest', () async {
      final guestApi = _FakeAdapter(body: _ok('other'));
      final clientAdapter = _FakeAdapter(body: {});
      final session = GuestSession(Dio()..httpClientAdapter = guestApi, _FakeStorage('renewed'));

      await session.retryWithNewToken(Dio()..httpClientAdapter = clientAdapter, _authError('expired'));

      expect(guestApi.calls, 0);
      expect(clientAdapter.authHeaders.single, 'Bearer renewed');
    });

    test('guest API unreachable: keeps the original error (null), no request', () async {
      final clientAdapter = _FakeAdapter(body: {});
      final session = GuestSession(Dio()..httpClientAdapter = _FakeAdapter(connectionError: true), _FakeStorage('expired'));

      expect(await session.retryWithNewToken(Dio()..httpClientAdapter = clientAdapter, _authError('expired')), isNull);
      expect(clientAdapter.calls, 0);
    });
  });
}
