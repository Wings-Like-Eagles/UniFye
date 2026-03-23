// lib/features/auth/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../services/auth_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthState.unauthenticated()) {
    _checkAuthStatus();
  }

  final AuthService _authService;

  Future<void> _checkAuthStatus() async {
    state = const AuthState.loading();
    
    final token = await _authService.getStoredToken();
    if (token != null) {
      final user = await _authService.getCurrentUser(token);
      state = AuthState.authenticated(user: user, token: token);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    final result = await _authService.login(email: email, password: password);
    state = AuthState.authenticated(user: result.user, token: result.token);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
