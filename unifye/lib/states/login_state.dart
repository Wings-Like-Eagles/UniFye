/// Login state class - immutable state for login screen
class LoginState {
  final String email;
  final String password;
  final bool isLoading;
  final bool obscurePassword;
  final String? emailError;
  final String? passwordError;
  final String? generalError;

  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.obscurePassword = true,
    this.emailError,
    this.passwordError,
    this.generalError,
  });

  LoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    bool? obscurePassword,
    String? Function()? emailError,
    String? Function()? passwordError,
    String? Function()? generalError,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      emailError: emailError != null ? emailError() : this.emailError,
      passwordError: passwordError != null ? passwordError() : this.passwordError,
      generalError: generalError != null ? generalError() : this.generalError,
    );
  }

  /// Check if form is valid
  bool get isValid => emailError == null && passwordError == null;
}
