import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/features/auth/models/login_state.dart';
import 'package:unifye/features/auth/services/auth_service.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';

/// Login Notifier - manages login form state and actions
class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier(this._authService, this._authNotifier) : super(const LoginState());

  final AuthService _authService;
  final AuthNotifier _authNotifier;

  /// Update email field
  void updateEmail(String email) {
    state = state.copyWith(
      email: email,
      emailError: null,
      generalError: null,
    );
  }

  /// Update password field
  void updatePassword(String password) {
    state = state.copyWith(
      password: password,
      passwordError: null,
      generalError: null,
    );
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate form fields
  bool _validateForm() {
    bool isValid = true;
    String? emailError;
    String? passwordError;

    // Validate Email
    if (state.email.isEmpty) {
      emailError = 'Email is required';
      isValid = false;
    } else if (!_isValidEmail(state.email)) {
      emailError = 'Please enter a valid email';
      isValid = false;
    }

    // Validate Password
    if (state.password.isEmpty) {
      passwordError = 'Password is required';
      isValid = false;
    } else if (state.password.length < 6) {
      passwordError = 'Password must be at least 6 characters';
      isValid = false;
    }

    state = state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
    );

    return isValid;
  }

  /// Perform login
  Future<bool> login() async {
    // Clear previous errors
    state = state.copyWith(
      emailError: null,
      passwordError: null,
      generalError: null,
    );

    // Validate form
    if (!_validateForm()) {
      return false;
    }

    // Set loading state
    state = state.copyWith(isLoading: true);

    try {
      // Call auth service and update auth state via auth notifier
      await _authNotifier.login(state.email, state.password);

      // Login successful
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      // Handle error
      state = state.copyWith(
        isLoading: false,
        passwordError: 'Invalid email or password',
        generalError: e.toString(),
      );
      return false;
    }
  }

  /// Clear all errors
  void clearErrors() {
    state = state.copyWith(
      emailError: null,
      passwordError: null,
      generalError: null,
    );
  }
}

/// Login Provider
final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return LoginNotifier(authService, authNotifier);
});

