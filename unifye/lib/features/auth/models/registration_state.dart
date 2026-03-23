import 'package:freezed_annotation/freezed_annotation.dart';

part 'registration_state.freezed.dart';

@freezed
class RegistrationState with _$RegistrationState {
  const RegistrationState._();
  
  const factory RegistrationState({
    @Default('') String name,
    @Default('') String email,
    @Default('') String password,
    @Default('') String university,
    DateTime? dateOfBirth,
    String? gender,
    @Default('') String bio,
    @Default(<String>[]) List<String> interests,
    String? profileImagePath,
    @Default(false) bool isLoading,
    String? nameError,
    String? emailError,
    String? passwordError,
    String? universityError,
    String? dobError,
    String? genderError,
    String? bioError,
    String? generalError,
  }) = _RegistrationState;

  /// Check if form is valid
  bool get isValid => 
      nameError == null && 
      emailError == null && 
      passwordError == null && 
      universityError == null && 
      dobError == null && 
      genderError == null && 
      bioError == null;
}
