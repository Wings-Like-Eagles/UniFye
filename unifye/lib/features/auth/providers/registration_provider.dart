import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/features/auth/models/registration_state.dart';
import 'package:unifye/features/auth/services/auth_service.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';

/// Registration Notifier - manages registration form state and actions
class RegistrationNotifier extends StateNotifier<RegistrationState> {
  RegistrationNotifier(this._authService, this._authNotifier) : super(const RegistrationState());

  final AuthService _authService;
  final AuthNotifier _authNotifier;

  /// Update name field
  void updateName(String name) {
    state = state.copyWith(
      name: name,
      nameError: null,
      generalError: null,
    );
  }

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

  /// Update university field
  void updateUniversity(String university) {
    state = state.copyWith(
      university: university,
      universityError: null,
      generalError: null,
    );
  }

  /// Update date of birth
  void updateDateOfBirth(DateTime? dateOfBirth) {
    state = state.copyWith(
      dateOfBirth: dateOfBirth,
      dobError: null,
      generalError: null,
    );
  }

  /// Update gender
  void updateGender(String? gender) {
    state = state.copyWith(
      gender: gender,
      genderError: null,
      generalError: null,
    );
  }

  /// Update bio
  void updateBio(String bio) {
    state = state.copyWith(
      bio: bio,
      bioError: null,
      generalError: null,
    );
  }

  /// Toggle interest
  void toggleInterest(String interest) {
    final currentInterests = List<String>.from(state.interests);
    if (currentInterests.contains(interest)) {
      currentInterests.remove(interest);
    } else {
      currentInterests.add(interest);
    }
    state = state.copyWith(interests: currentInterests);
  }

  /// Update profile image path
  void updateProfileImage(String? imagePath) {
    state = state.copyWith(profileImagePath: imagePath);
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate step 1 (Basic Information)
  bool validateStep1() {
    bool isValid = true;
    String? nameError;
    String? emailError;
    String? passwordError;

    if (state.name.trim().isEmpty) {
      nameError = 'Name is required';
      isValid = false;
    }

    if (state.email.trim().isEmpty) {
      emailError = 'Email is required';
      isValid = false;
    } else if (!_isValidEmail(state.email.trim())) {
      emailError = 'Enter a valid email';
      isValid = false;
    }

    if (state.password.isEmpty) {
      passwordError = 'Password is required';
      isValid = false;
    } else if (state.password.length < 8) {
      passwordError = 'Min 8 characters';
      isValid = false;
    }

    state = state.copyWith(
      nameError: nameError,
      emailError: emailError,
      passwordError: passwordError,
    );

    return isValid;
  }

  /// Validate step 2 (University & Personal)
  bool validateStep2() {
    bool isValid = true;
    String? universityError;
    String? dobError;
    String? genderError;

    if (state.university.trim().isEmpty) {
      universityError = 'University is required';
      isValid = false;
    }

    if (state.dateOfBirth == null) {
      dobError = 'Date of birth is required';
      isValid = false;
    }

    if (state.gender == null) {
      genderError = 'Please select gender';
      isValid = false;
    }

    state = state.copyWith(
      universityError: universityError,
      dobError: dobError,
      genderError: genderError,
    );

    return isValid;
  }

  /// Validate step 3 (Profile Details)
  bool validateStep3() {
    bool isValid = true;
    String? bioError;

    if (state.bio.trim().isEmpty) {
      bioError = 'Please add a short description';
      isValid = false;
    }

    state = state.copyWith(bioError: bioError);

    return isValid;
  }

  /// Validate all steps
  bool validateAll() {
    final step1Valid = validateStep1();
    final step2Valid = validateStep2();
    final step3Valid = validateStep3();
    final hasInterests = state.interests.isNotEmpty;

    return step1Valid && step2Valid && step3Valid && hasInterests;
  }

  /// Perform registration
  Future<bool> register() async {
    // Clear previous errors
    state = state.copyWith(generalError: null);

    // Validate all steps
    if (!validateAll()) {
      if (state.interests.isEmpty) {
        state = state.copyWith(
          generalError: 'Please select at least one interest',
        );
      }
      return false;
    }

    // Set loading state
    state = state.copyWith(isLoading: true);

    try {
      // Call auth service
      await _authService.register(
        email: state.email.trim(),
        password: state.password,
        name: state.name.trim(),
        university: state.university.trim().isNotEmpty 
            ? state.university.trim() 
            : null,
        dateOfBirth: state.dateOfBirth,
        gender: state.gender,
        bio: state.bio.trim().isNotEmpty ? state.bio.trim() : null,
        interests: state.interests.isNotEmpty ? state.interests : null,
        profileImagePath: state.profileImagePath,
      );

      // Update auth state via auth notifier
      await _authNotifier.login(state.email.trim(), state.password);

      // Registration successful
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      // Handle error
      state = state.copyWith(
        isLoading: false,
        generalError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Clear all errors
  void clearErrors() {
    state = state.copyWith(
      nameError: null,
      emailError: null,
      passwordError: null,
      universityError: null,
      dobError: null,
      genderError: null,
      bioError: null,
      generalError: null,
    );
  }

  /// Reset state
  void reset() {
    state = const RegistrationState();
  }
}

/// Registration Provider
final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return RegistrationNotifier(authService, authNotifier);
});
