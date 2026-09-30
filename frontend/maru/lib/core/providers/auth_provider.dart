import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/auth_repository.dart';
import '../storage/secure_storage.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => _checkInitialAuth());
    return AuthState.initial;
  }

  Future<void> _checkInitialAuth() async {
    state = AuthState.loading;
    final secureStorage = ref.read(secureStorageProvider);
    // 개발용: `--dart-define=DEV_JWT=<token>` (scripts/dev_token.sh) 로 소셜 로그인 없이 진입.
    const devJwt = String.fromEnvironment('DEV_JWT');
    if (kDebugMode && devJwt.isNotEmpty) {
      await secureStorage.saveTokens(accessToken: devJwt);
    }
    final token = await secureStorage.getAccessToken();
    if (token != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  /// English message for the login screen when [state] is [AuthState.error].
  String? errorMessage;

  Future<void> loginWithBackend(String provider, String idToken) async {
    errorMessage = null;
    state = AuthState.loading;
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final error = await authRepository.verifyIdToken(provider, idToken);
      if (error == null) {
        state = AuthState.authenticated;
      } else {
        setError(error);
      }
    } catch (e) {
      debugPrint('loginWithBackend failed: $e');
      setError('Something went wrong while signing in. Please try again.');
    }
  }

  Future<void> logout() async {
    errorMessage = null;
    state = AuthState.loading;
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();
    state = AuthState.unauthenticated;
  }

  void setError(String? message) {
    errorMessage = message;
    state = AuthState.error;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
