import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/features/auth/models/auth_state.dart'; // Ensure this model exists
import 'package:unifye/features/auth/services/auth_service.dart';
import 'package:unifye/features/auth/models/user.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState.unauthenticated()) {
    _checkInitialAuth();
  }

  /// Check if a token exists on app startup
  Future<void> _checkInitialAuth() async {
    final token = await _authService.getStoredToken();
    if (token != null) {
      try {
        state = const AuthState.loading();
        final user = await _authService.getCurrentUser(token);
        state = AuthState.authenticated(user: user, token: token);
      } catch (_) {
        state = const AuthState.unauthenticated();
      }
    }
  }

  /// The login logic that your LoginNotifier calls
  Future<void> login(String email, String password) async {
    try {
      state = const AuthState.loading();
      final result = await _authService.login(email: email, password: password);
      
      // Update state to authenticated
      state = AuthState.authenticated(user: result.user, token: result.token);
    } catch (e) {
      state = const AuthState.unauthenticated();
      rethrow; // Rethrow so LoginNotifier can catch and show the error
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState.unauthenticated();
  }
}

// The global provider for Auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});