import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/core/theme/app_colour.dart';
import 'package:unifye/widgets/app_button.dart';
import 'package:unifye/widgets/app_text_field.dart';
import 'package:unifye/actions/login_actions.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';
import 'package:unifye/features/auth/models/auth_state.dart';
import 'forgot_password_page.dart';
import 'register-page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final loginNotifier = ref.read(loginProvider.notifier);

    // Sync controllers with state (only if different to avoid cursor jumping)
    if (_emailController.text != loginState.email) {
      _emailController.text = loginState.email;
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: _emailController.text.length),
      );
    }
    if (_passwordController.text != loginState.password && !loginState.obscurePassword) {
      _passwordController.text = loginState.password;
      _passwordController.selection = TextSelection.fromPosition(
        TextPosition(offset: _passwordController.text.length),
      );
    }

    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      next.when(
        unauthenticated: () {},
        authenticated: (user, token) {
          // Navigation is handled by AppRouter when auth state changes.
          if (mounted) {
            _showSuccessMessage('Login successful!');
          }
        },
        loading: () {},
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon Section
                  _buildHeader(),
                  
                  const SizedBox(height: 48),
                  
                  // Email Field
                  AppTextField(
                    label: 'Email Address',
                    hint: 'Enter your email',
                    controller: _emailController,
                    inputType: AppInputType.email,
                    prefixIcon: Icons.email_outlined,
                    errorText: loginState.emailError,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) {
                      loginNotifier.updateEmail(value);
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password Field
                  AppTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    inputType: loginState.obscurePassword 
                        ? AppInputType.password 
                        : AppInputType.text,
                    prefixIcon: Icons.lock_outline,
                    errorText: loginState.passwordError,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                    onChanged: (value) {
                      loginNotifier.updatePassword(value);
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      text: 'Forgot Password?',
                      type: AppButtonType.text,
                      size: AppButtonSize.medium,
                      onPressed: _handleForgotPassword,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Sign In Button
                  AppButton(
                    text: 'Sign In',
                    onPressed: _handleLogin,
                    isLoading: loginState.isLoading,
                    isFullWidth: true,
                    size: AppButtonSize.large,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Divider with "OR"
                  _buildDivider(),
                  
                  const SizedBox(height: 24),
                  
                  // Social Login Buttons
                  AppButton(
                    text: 'Continue with Google',
                    type: AppButtonType.outline,
                    icon: Icons.g_mobiledata,
                    onPressed: _handleGoogleSignIn,
                    isFullWidth: true,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  AppButton(
                    text: 'Continue with Apple',
                    type: AppButtonType.outline,
                    icon: Icons.apple,
                    onPressed: _handleAppleSignIn,
                    isFullWidth: true,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Sign Up Link
                  _buildSignUpLink(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Logo/Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        
        // Welcome Text
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to continue your journey',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Don\'t have an account? ',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
        GestureDetector(
          onTap: _handleSignUp,
          child: const Text(
            'Sign Up',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // Button Handlers
  Future<void> _handleLogin() async {
    final loginNotifier = ref.read(loginProvider.notifier);
    
    // Update state from controllers
    loginNotifier.updateEmail(_emailController.text);
    loginNotifier.updatePassword(_passwordController.text);

    // Perform login
    final success = await loginNotifier.login();

    if (!success && mounted) {
      final loginState = ref.read(loginProvider);
      if (loginState.generalError != null) {
        _showErrorMessage(loginState.generalError!);
      } else if (loginState.passwordError != null) {
        _showErrorMessage(loginState.passwordError!);
      } else if (loginState.emailError != null) {
        _showErrorMessage(loginState.emailError!);
      }
    }
  }

  void _handleForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
    );
  }


  void _handleGoogleSignIn() {
    // TODO: Implement Google Sign In
    _showInfoMessage('Google Sign In coming soon!');
  }

  void _handleAppleSignIn() {
    // TODO: Implement Apple Sign In
    _showInfoMessage('Apple Sign In coming soon!');
  }

  void _handleSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  // Snackbar Messages
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
