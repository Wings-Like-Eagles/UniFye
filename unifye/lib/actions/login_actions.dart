// import 'package:my_app/states/login_state.dart';

// /// Login controller - manages login state and business logic
// class LoginController extends StateNotifier<LoginState> {
//   LoginController() : super(const LoginState());

//   /// Update email
//   void updateEmail(String email) {
//     state = state.copyWith(
//       email: email,
//       emailError: () => null, // Clear error when user types
//     );
//   }

//   /// Update password
//   void updatePassword(String password) {
//     state = state.copyWith(
//       password: password,
//       passwordError: () => null, // Clear error when user types
//     );
//   }

//   /// Toggle password visibility
//   void togglePasswordVisibility() {
//     state = state.copyWith(
//       obscurePassword: !state.obscurePassword,
//     );
//   }

//   /// Validate email format
//   bool _isValidEmail(String email) {
//     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
//   }

//   /// Validate form
//   bool _validateForm() {
//     String? emailError;
//     String? passwordError;

//     // Validate email
//     if (state.email.isEmpty) {
//       emailError = 'Email is required';
//     } else if (!_isValidEmail(state.email)) {
//       emailError = 'Please enter a valid email';
//     }

//     // Validate password
//     if (state.password.isEmpty) {
//       passwordError = 'Password is required';
//     } else if (state.password.length < 6) {
//       passwordError = 'Password must be at least 6 characters';
//     }

//     // Update state with errors
//     if (emailError != null || passwordError != null) {
//       state = state.copyWith(
//         emailError: () => emailError,
//         passwordError: () => passwordError,
//       );
//       return false;
//     }

//     return true;
//   }

//   /// Clear all errors
//   void clearErrors() {
//     state = state.copyWith(
//       emailError: () => null,
//       passwordError: () => null,
//       generalError: () => null,
//     );
//   }

//   /// Handle login - main authentication logic
//   Future<bool> login() async {
//     // Clear previous errors
//     clearErrors();

//     // Validate form
//     if (!_validateForm()) {
//       return false;
//     }

//     // Set loading state
//     state = state.copyWith(isLoading: true);

//     try {
//       // TODO: Replace with your actual authentication service
//       // Example: await AuthService.signIn(state.email, state.password);
      
//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 2));

//       // Simulate random success/failure for demo
//       // Remove this and use real authentication
//       final random = DateTime.now().second % 3;
//       if (random == 0) {
//         throw Exception('Invalid credentials');
//       }

//       // Success
//       state = state.copyWith(isLoading: false);
//       return true;
//     } catch (e) {
//       // Handle error
//       state = state.copyWith(
//         isLoading: false,
//         generalError: () => e.toString(),
//         passwordError: () => 'Invalid email or password',
//       );
//       return false;
//     }
//   }

//   /// Handle Google Sign In
//   Future<bool> signInWithGoogle() async {
//     state = state.copyWith(isLoading: true);

//     try {
//       // TODO: Implement Google Sign In
//       // Example:
//       // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       // if (googleUser == null) return false;
//       // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//       // await AuthService.signInWithGoogle(googleAuth);

//       await Future.delayed(const Duration(seconds: 2));
      
//       state = state.copyWith(isLoading: false);
//       return true;
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         generalError: () => 'Google sign in failed: ${e.toString()}',
//       );
//       return false;
//     }
//   }

//   /// Handle Apple Sign In
//   Future<bool> signInWithApple() async {
//     state = state.copyWith(isLoading: true);

//     try {
//       // TODO: Implement Apple Sign In
//       await Future.delayed(const Duration(seconds: 2));
      
//       state = state.copyWith(isLoading: false);
//       return true;
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         generalError: () => 'Apple sign in failed: ${e.toString()}',
//       );
//       return false;
//     }
//   }

//   /// Reset state (useful for logout)
//   void reset() {
//     state = const LoginState();
//   }
// }

// /// Provider for login controller
// final loginControllerProvider = StateNotifierProvider<LoginController, LoginState>(
//   (ref) => LoginController(),
// );