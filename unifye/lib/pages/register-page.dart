import 'package:flutter/material.dart';
import 'dart:io';
import 'package:my_app/core/theme/app_colour.dart';
import 'package:my_app/widgets/app_button.dart';
import 'package:my_app/widgets/app_text_field.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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

  DateTime? _dateOfBirth;
  String? _gender; // 'Male' | 'Female'
  final Set<String> _selectedInterests = {};
  final List<String> _interestCatalog = const [
    'Music','Golf','Travel','Movies','Cooking','Fitness','Reading','Gaming',
    'Art','Tech','Outdoors','Dancing','Photography','Pets','Foodie','Yoga',
    'Hiking','Running','Fashion','Theatre'
  ];
  bool _isLoading = false;
  File? _profileImageFile;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _universityError;
  String? _dobError;
  String? _genderError;
  String? _bioError;

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

  @override
  Widget build(BuildContext context) {
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
          errorText: _nameError,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _nameError = null),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Email',
          hint: 'yourname@university.edu',
          controller: _emailController,
          inputType: AppInputType.email,
          errorText: _emailError,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _emailError = null),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Password',
          hint: 'Create a strong password',
          controller: _passwordController,
          inputType: AppInputType.password,
          errorText: _passwordError,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _passwordError = null),
        ),
      ],
    );
  }

  Widget _buildStepTwoDetails() {
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
          errorText: _universityError,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _universityError = null),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Date of Birth',
          hint: 'Select your date of birth',
          controller: _dobController,
          readOnly: true,
          errorText: _dobError,
          suffixIcon: Icons.calendar_today,
          onSuffixIconTap: _pickDateOfBirth,
          onTap: _pickDateOfBirth,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _buildGenderSelector(),
        if (_genderError != null) ...[
          const SizedBox(height: 6),
          Text(
            _genderError!,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildStepThreeProfile() {
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
          errorText: _bioError,
          onChanged: (_) => setState(() => _bioError = null),
        ),
        const SizedBox(height: 16),
        _buildInterestCatalog(),
        const SizedBox(height: 16),
        _buildPhotoPicker(),
        const SizedBox(height: 24),
        AppButton(
          text: 'Create Account',
          onPressed: _submit,
          isLoading: _isLoading,
          isFullWidth: true,
          size: AppButtonSize.large,
        ),
      ],
    );
  }

  Widget _buildNavBar() {
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
            text: _currentPage == 2 ? 'Review' : 'Next',
            onPressed: _nextPage,
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
    final isMale = _gender == 'Male';
    final isFemale = _gender == 'Female';

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
                onPressed: () => setState(() {
                  _gender = 'Male';
                  _genderError = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Female',
                type: isFemale ? AppButtonType.primary : AppButtonType.outline,
                onPressed: () => setState(() {
                  _gender = 'Female';
                  _genderError = null;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestCatalog() {
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
            final selected = _selectedInterests.contains(interest);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedInterests.remove(interest);
                  } else {
                    _selectedInterests.add(interest);
                  }
                });
              },
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
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = DateTime(now.year - 20, now.month, now.day);
    final first = DateTime(now.year - 100);
    final last = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Select your date of birth',
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text = _formatDate(picked);
        _dobError = null;
      });
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
    if (!_validateStep(_currentPage)) return;
    if (_currentPage >= 2) return;
    setState(() => _currentPage += 1);
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        setState(() {
          _nameError = _nameController.text.trim().isEmpty ? 'Name is required' : null;
          _emailError = _isValidEmail(_emailController.text.trim()) ? null : 'Enter a valid email';
          _passwordError = _passwordController.text.length < 6 ? 'Min 6 characters' : null;
        });
        return _nameError == null && _emailError == null && _passwordError == null;
      case 1:
        setState(() {
          _universityError = _universityController.text.trim().isEmpty ? 'University is required' : null;
          _dobError = _dateOfBirth == null ? 'Date of birth is required' : null;
          _genderError = (_gender == null) ? 'Please select gender' : null;
        });
        return _universityError == null && _dobError == null && _genderError == null;
      case 2:
        setState(() {
          _bioError = _bioController.text.trim().isEmpty ? 'Please add a short description' : null;
        });
        if (_selectedInterests.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one interest'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return _bioError == null;
      default:
        return true;
    }
  }

  Future<void> _pickProfilePhoto() async {
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
    }
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? 'Name is required' : null;
      _emailError = _isValidEmail(_emailController.text.trim()) ? null : 'Enter a valid email';
      _passwordError = _passwordController.text.length < 6 ? 'Min 6 characters' : null;
      _universityError = _universityController.text.trim().isEmpty ? 'University is required' : null;
      _dobError = _dateOfBirth == null ? 'Date of birth is required' : null;
      _genderError = (_gender == null) ? 'Please select gender' : null;
      _bioError = _bioController.text.trim().isEmpty ? 'Please add a short description' : null;
    });
    // require at least one interest
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one interest'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ok = false;
    }
    ok &= _nameError == null;
    ok &= _emailError == null;
    ok &= _passwordError == null;
    ok &= _universityError == null;
    ok &= _dobError == null;
    ok &= _genderError == null;
    ok &= _bioError == null;
    return ok;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _submit() async {
    // Validate all steps before submitting
    for (int s = 0; s < 3; s++) {
      if (!_validateStep(s)) {
        setState(() {
          _currentPage = s;
        });
        _pageController.jumpToPage(s);
        return;
      }
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }
}
