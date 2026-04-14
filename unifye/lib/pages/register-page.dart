import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:unifye/core/theme/app_colour.dart';
import 'package:unifye/widgets/app_button.dart';
import 'package:unifye/widgets/app_text_field.dart';
import 'package:unifye/features/auth/providers/registration_provider.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';
import 'package:unifye/features/auth/models/auth_state.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _interestInputController = TextEditingController();

  final List<String> _interestCatalog = const [
    'Music','Golf','Travel','Movies','Cooking','Fitness','Reading','Gaming',
    'Art','Tech','Outdoors','Dancing','Photography','Pets','Foodie','Yoga',
    'Hiking','Running','Fashion','Theatre'
  ];
  File? _profileImageFile;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _universityController.dispose();
    _dobController.dispose();
    _bioController.dispose();
    _interestInputController.dispose();
    super.dispose();
  }

  String? _lastShownError;

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(registrationProvider);

    // Sync controllers with state (only if different to avoid cursor jumping)
    if (_nameController.text != registrationState.name) {
      _nameController.text = registrationState.name;
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    }
    if (_emailController.text != registrationState.email) {
      _emailController.text = registrationState.email;
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: _emailController.text.length),
      );
    }
    if (_passwordController.text != registrationState.password) {
      _passwordController.text = registrationState.password;
      _passwordController.selection = TextSelection.fromPosition(
        TextPosition(offset: _passwordController.text.length),
      );
    }
    if (_universityController.text != registrationState.university) {
      _universityController.text = registrationState.university;
      _universityController.selection = TextSelection.fromPosition(
        TextPosition(offset: _universityController.text.length),
      );
    }
    if (_bioController.text != registrationState.bio) {
      _bioController.text = registrationState.bio;
      _bioController.selection = TextSelection.fromPosition(
        TextPosition(offset: _bioController.text.length),
      );
    }
    if (registrationState.dateOfBirth != null && _dobController.text.isEmpty) {
      _dobController.text = _formatDate(registrationState.dateOfBirth!);
    }

    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      next.when(
        unauthenticated: () {},
        authenticated: (user, token) {
          // Navigate back to login or home screen on successful registration
          if (mounted) {
            _showSuccessMessage('Account created successfully!');
            Navigator.pop(context);
          }
        },
        loading: () {},
      );
    });

    // Show error messages (only once per error)
    if (registrationState.generalError != null && 
        registrationState.generalError != _lastShownError && 
        mounted) {
      _lastShownError = registrationState.generalError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && registrationState.generalError == _lastShownError) {
          _showErrorMessage(registrationState.generalError!);
        }
      });
    } else if (registrationState.generalError == null) {
      _lastShownError = null;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Create Your Profile', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildProgressDots(),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SingleChildScrollView(
                        child: _buildStepOneBasic(),
                      ),
                      SingleChildScrollView(
                        child: _buildStepTwoDetails(),
                      ),
                      SingleChildScrollView(
                        child: _buildStepThreeProfile(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildNavBar(),
                const SizedBox(height: 8),
                _buildSignInLink(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 16),
        const Text(
          'Join UniFye Dating',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Create your profile to start matching',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDots() {
    const total = 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  Widget _buildStepOneBasic() {
    final registrationState = ref.watch(registrationProvider);
    final registrationNotifier = ref.read(registrationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Full Name',
          hint: 'Your name',
          controller: _nameController,
          errorText: registrationState.nameError,
          textInputAction: TextInputAction.next,
          onChanged: (value) => registrationNotifier.updateName(value),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Email',
          hint: 'yourname@university.edu',
          controller: _emailController,
          inputType: AppInputType.email,
          errorText: registrationState.emailError,
          textInputAction: TextInputAction.next,
          onChanged: (value) => registrationNotifier.updateEmail(value),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Password',
          hint: 'Create a strong password',
          controller: _passwordController,
          inputType: AppInputType.password,
          errorText: registrationState.passwordError,
          textInputAction: TextInputAction.done,
          onChanged: (value) => registrationNotifier.updatePassword(value),
        ),
      ],
    );
  }

  Widget _buildStepTwoDetails() {
    final registrationState = ref.watch(registrationProvider);
    final registrationNotifier = ref.read(registrationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'University & Personal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'University',
          hint: 'e.g. University of Oxford',
          controller: _universityController,
          errorText: registrationState.universityError,
          textInputAction: TextInputAction.next,
          onChanged: (value) => registrationNotifier.updateUniversity(value),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Date of Birth',
          hint: 'Select your date of birth',
          controller: _dobController,
          readOnly: true,
          errorText: registrationState.dobError,
          suffixIcon: Icons.calendar_today,
          onSuffixIconTap: _pickDateOfBirth,
          onTap: _pickDateOfBirth,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _buildGenderSelector(),
        if (registrationState.genderError != null) ...[
          const SizedBox(height: 6),
          Text(
            registrationState.genderError!,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildStepThreeProfile() {
    final registrationState = ref.watch(registrationProvider);
    final registrationNotifier = ref.read(registrationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Profile Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Profile Description',
          hint: 'Tell others about you',
          controller: _bioController,
          inputType: AppInputType.multiline,
          maxLines: 5,
          errorText: registrationState.bioError,
          onChanged: (value) => registrationNotifier.updateBio(value),
        ),
        const SizedBox(height: 16),
        _buildInterestCatalog(),
        const SizedBox(height: 16),
        _buildPhotoPicker(),
        const SizedBox(height: 24),
        AppButton(
          text: 'Create Account',
          onPressed: _submit,
          isLoading: registrationState.isLoading,
          isFullWidth: true,
          size: AppButtonSize.large,
        ),
      ],
    );
  }

  Widget _buildNavBar() {
    final registrationState = ref.watch(registrationProvider);
    final isFinalStep = _currentPage == 2;

    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Back',
            type: _currentPage == 0 ? AppButtonType.text : AppButtonType.outline,
            onPressed: _currentPage == 0 ? null : _prevPage,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            text: isFinalStep ? 'Create Account' : 'Next',
            onPressed: registrationState.isLoading
                ? null
                : (isFinalStep ? _submit : _nextPage),
            isLoading: isFinalStep && registrationState.isLoading,
            type: AppButtonType.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    final registrationState = ref.watch(registrationProvider);
    final registrationNotifier = ref.read(registrationProvider.notifier);
    final isMale = registrationState.gender == 'Male';
    final isFemale = registrationState.gender == 'Female';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Male',
                type: isMale ? AppButtonType.primary : AppButtonType.outline,
                onPressed: () => registrationNotifier.updateGender('Male'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Female',
                type: isFemale ? AppButtonType.primary : AppButtonType.outline,
                onPressed: () => registrationNotifier.updateGender('Female'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestCatalog() {
    final registrationState = ref.watch(registrationProvider);
    final registrationNotifier = ref.read(registrationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interests',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _interestCatalog.map((interest) {
            final selected = registrationState.interests.contains(interest);
            return GestureDetector(
              onTap: () => registrationNotifier.toggleInterest(interest),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? Colors.transparent : AppColors.border,
                    width: 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      const Icon(Icons.check, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      interest,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Photo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: _profileImageFile != null
                    ? DecorationImage(
                        image: FileImage(_profileImageFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileImageFile == null
                  ? const Icon(Icons.person, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Choose Photo',
                      type: AppButtonType.outline,
                      onPressed: _pickProfilePhoto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_profileImageFile != null)
                    AppButton(
                      text: 'Remove',
                      type: AppButtonType.text,
                      onPressed: () => setState(() => _profileImageFile = null),
                      size: AppButtonSize.medium,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDateOfBirth() async {
    final registrationState = ref.read(registrationProvider);
    final registrationNotifier = ref.read(registrationProvider.notifier);
    
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = DateTime(now.year - 20, now.month, now.day);
    final first = DateTime(now.year - 100);
    final last = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: registrationState.dateOfBirth ?? initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Select your date of birth',
    );
    if (picked != null) {
      registrationNotifier.updateDateOfBirth(picked);
      _dobController.text = _formatDate(picked);
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

  void _prevPage() {
    if (_currentPage == 0) return;
    setState(() => _currentPage -= 1);
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    final registrationNotifier = ref.read(registrationProvider.notifier);
    bool isValid = false;

    switch (_currentPage) {
      case 0:
        isValid = registrationNotifier.validateStep1();
        break;
      case 1:
        isValid = registrationNotifier.validateStep2();
        break;
    }

    if (!isValid) return;
    if (_currentPage >= 2) return;
    
    setState(() => _currentPage += 1);
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickProfilePhoto() async {
    final registrationNotifier = ref.read(registrationProvider.notifier);
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _profileImageFile = File(picked.path);
      });
      registrationNotifier.updateProfileImage(picked.path);
    }
  }

  Future<void> _submit() async {
    final registrationNotifier = ref.read(registrationProvider.notifier);
    
    // Update state from controllers
    registrationNotifier.updateName(_nameController.text);
    registrationNotifier.updateEmail(_emailController.text);
    registrationNotifier.updatePassword(_passwordController.text);
    registrationNotifier.updateUniversity(_universityController.text);
    registrationNotifier.updateBio(_bioController.text);

    // Validate all steps before submitting
    final registrationState = ref.read(registrationProvider);
    bool step1Valid = registrationNotifier.validateStep1();
    bool step2Valid = registrationNotifier.validateStep2();
    bool step3Valid = registrationNotifier.validateStep3();
    bool hasInterests = registrationState.interests.isNotEmpty;

    if (!step1Valid || !step2Valid || !step3Valid || !hasInterests) {
      // Navigate to first invalid step
      if (!step1Valid) {
        setState(() => _currentPage = 0);
        _pageController.jumpToPage(0);
      } else if (!step2Valid) {
        setState(() => _currentPage = 1);
        _pageController.jumpToPage(1);
      } else {
        setState(() => _currentPage = 2);
        _pageController.jumpToPage(2);
        if (!hasInterests) {
          _showErrorMessage('Please select at least one interest');
        }
      }
      return;
    }

    // Perform registration
    final success = await registrationNotifier.register();

    if (success && mounted) {
      // Success message will be shown via auth state listener
      // Navigation will happen automatically
    }
  }

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
}
