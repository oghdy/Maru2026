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
    final token = await secureStorage.getAccessToken();
    if (token != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> loginWithBackend(String provider, String idToken) async {
    state = AuthState.loading;
    final authRepository = ref.read(authRepositoryProvider);
    final success = await authRepository.verifyIdToken(provider, idToken);
    
    if (success) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.error;
    }
  }

  Future<void> logout() async {
    state = AuthState.loading;
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();
    state = AuthState.unauthenticated;
  }

  void setError(String? message) {
    state = AuthState.error;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
