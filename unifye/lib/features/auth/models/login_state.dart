/// Login state class - immutable state for login screen
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const LoginState._();  // Private constructor for custom methods
  
  const factory LoginState({
    @Default('') String email,
    @Default('') String password,
    @Default(false) bool isLoading,
    @Default(true) bool obscurePassword,
    String? emailError,
    String? passwordError,
    String? generalError,
  }) = _LoginState;

  /// Check if form is valid
  bool get isValid => emailError == null && passwordError == null;
}