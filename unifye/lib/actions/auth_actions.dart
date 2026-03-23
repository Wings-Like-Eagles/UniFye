import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/features/auth/services/auth_service.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';
import 'package:unifye/features/auth/models/user.dart';

/// Auth Actions - handles all authentication operations
/// This file provides Riverpod providers and notifiers for:
/// - Register
/// - Login
/// - Logout
/// - Get Current User (me)

/// ============================================
/// REGISTER ACTION
/// ============================================

/// Register State - tracks registration operation state
class RegisterActionState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final User? user;
  final String? token;

  const RegisterActionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.user,
    this.token,
  });

  RegisterActionState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    User? user,
    String? token,
  }) {
    return RegisterActionState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      user: user ?? this.user,
      token: token ?? this.token,
    );
  }
}

/// Register Action Notifier
class RegisterActionNotifier extends StateNotifier<RegisterActionState> {
  RegisterActionNotifier(this._authService, this._authNotifier)
      : super(const RegisterActionState());

  final AuthService _authService;
  final AuthNotifier _authNotifier;

  /// Register a new user
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    DateTime? dateOfBirth,
    String? gender,
    String? interestedIn,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Convert interestedIn string to interests list (backend expects interestedIn but service uses interests)
      final interests = interestedIn != null ? [interestedIn] : null;
      
      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
        dateOfBirth: dateOfBirth,
        gender: gender,
        interests: interests,
      );

      // Update global auth state
      await _authNotifier.login(email, password);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: result.user,
        token: result.token,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset register state
  void reset() {
    state = const RegisterActionState();
  }
}

/// Register Action Provider
final registerActionProvider =
    StateNotifierProvider<RegisterActionNotifier, RegisterActionState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return RegisterActionNotifier(authService, authNotifier);
});

/// ============================================
/// LOGIN ACTION
/// ============================================

/// Login Action State - tracks login operation state
class LoginActionState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final User? user;
  final String? token;

  const LoginActionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.user,
    this.token,
  });

  LoginActionState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    User? user,
    String? token,
  }) {
    return LoginActionState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      user: user ?? this.user,
      token: token ?? this.token,
    );
  }
}

/// Login Action Notifier
class LoginActionNotifier extends StateNotifier<LoginActionState> {
  LoginActionNotifier(this._authService, this._authNotifier)
      : super(const LoginActionState());

  final AuthService _authService;
  final AuthNotifier _authNotifier;

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      // Update global auth state
      await _authNotifier.login(email, password);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: result.user,
        token: result.token,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset login state
  void reset() {
    state = const LoginActionState();
  }
}

/// Login Action Provider
final loginActionProvider =
    StateNotifierProvider<LoginActionNotifier, LoginActionState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return LoginActionNotifier(authService, authNotifier);
});

/// ============================================
/// LOGOUT ACTION
/// ============================================

/// Logout Action State - tracks logout operation state
class LogoutActionState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const LogoutActionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  LogoutActionState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return LogoutActionState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

/// Logout Action Notifier
class LogoutActionNotifier extends StateNotifier<LogoutActionState> {
  LogoutActionNotifier(this._authService, this._authNotifier)
      : super(const LogoutActionState());

  final AuthService _authService;
  final AuthNotifier _authNotifier;

  /// Logout current user
  /// Requires authentication (protected route)
  Future<bool> logout() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Call logout endpoint (requires auth token)
      await _authService.logout();

      // Update global auth state
      await _authNotifier.logout();

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset logout state
  void reset() {
    state = const LogoutActionState();
  }
}

/// Logout Action Provider
final logoutActionProvider =
    StateNotifierProvider<LogoutActionNotifier, LogoutActionState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return LogoutActionNotifier(authService, authNotifier);
});

/// ============================================
/// GET ME ACTION (Get Current User)
/// ============================================

/// GetMe Action State - tracks get current user operation state
class GetMeActionState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final User? user;

  const GetMeActionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.user,
  });

  GetMeActionState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    User? user,
  }) {
    return GetMeActionState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      user: user ?? this.user,
    );
  }
}

/// GetMe Action Notifier
class GetMeActionNotifier extends StateNotifier<GetMeActionState> {
  GetMeActionNotifier(this._authService) : super(const GetMeActionState());

  final AuthService _authService;

  /// Get current authenticated user
  /// Requires authentication (protected route)
  Future<bool> getMe() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get stored token
      final token = await _authService.getStoredToken();

      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
          error: 'No authentication token found',
        );
        return false;
      }

      // Call getMe endpoint (requires auth token)
      final user = await _authService.getCurrentUser(token);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: user,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset getMe state
  void reset() {
    state = const GetMeActionState();
  }
}

/// GetMe Action Provider
final getMeActionProvider =
    StateNotifierProvider<GetMeActionNotifier, GetMeActionState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return GetMeActionNotifier(authService);
});

