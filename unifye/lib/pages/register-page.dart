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

// ─────────────────────────────────────────────
//  Step metadata
// ─────────────────────────────────────────────
class _Step {
  final String   label;
  final IconData icon;
  const _Step(this.label, this.icon);
}

const _steps = [
  _Step('Account',   Icons.lock_outline_rounded),
  _Step('Profile',   Icons.person_outline_rounded),
  _Step('Interests', Icons.favorite_border_rounded),
];

// ─────────────────────────────────────────────
//  Interest catalogue with emoji
// ─────────────────────────────────────────────
class _Interest {
  final String label;
  final String emoji;
  const _Interest(this.label, this.emoji);
}

const _interestCatalog = [
  _Interest('Music',       '🎵'),
  _Interest('Golf',        '⛳'),
  _Interest('Travel',      '✈️'),
  _Interest('Movies',      '🎬'),
  _Interest('Cooking',     '🍳'),
  _Interest('Fitness',     '💪'),
  _Interest('Reading',     '📚'),
  _Interest('Gaming',      '🎮'),
  _Interest('Art',         '🎨'),
  _Interest('Tech',        '💻'),
  _Interest('Outdoors',    '🌿'),
  _Interest('Dancing',     '💃'),
  _Interest('Photography', '📸'),
  _Interest('Pets',        '🐾'),
  _Interest('Foodie',      '🍜'),
  _Interest('Yoga',        '🧘'),
  _Interest('Hiking',      '🥾'),
  _Interest('Running',     '🏃'),
  _Interest('Fashion',     '👗'),
  _Interest('Theatre',     '🎭'),
];

// ═══════════════════════════════════════════════════════════════════════════
//  Page
// ═══════════════════════════════════════════════════════════════════════════
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin {

  final _formKey        = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage      = 0;

  final _nameController       = TextEditingController();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _universityController = TextEditingController();
  final _dobController        = TextEditingController();
  final _bioController        = TextEditingController();

  File?   _profileImageFile;
  String? _lastShownError;

  late final AnimationController _headerAnim = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 700),
  )..forward();
  late final Animation<double> _headerFade = CurvedAnimation(
    parent: _headerAnim, curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _pageController.dispose();
    _headerAnim.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _universityController.dispose();
    _dobController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  void _syncControllers(dynamic state) {
    void sync(TextEditingController c, String v) {
      if (c.text != v) {
        c.value = c.value.copyWith(
          text:      v,
          selection: TextSelection.collapsed(offset: v.length),
        );
      }
    }
    sync(_nameController,       state.name);
    sync(_emailController,      state.email);
    sync(_passwordController,   state.password);
    sync(_universityController, state.university);
    sync(_bioController,        state.bio);
    if (state.dateOfBirth != null && _dobController.text.isEmpty) {
      _dobController.text = _formatDate(state.dateOfBirth!);
    }
  }

  void _prevPage() {
    if (_currentPage == 0) return;
    setState(() => _currentPage--);
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    final notifier = ref.read(registrationProvider.notifier);
    final valid    = _currentPage == 0
        ? notifier.validateStep1()
        : notifier.validateStep2();
    if (!valid) return;
    if (_currentPage >= 2) return;
    setState(() => _currentPage++);
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickDateOfBirth() async {
    FocusScope.of(context).unfocus();
    final state    = ref.read(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);
    final now      = DateTime.now();
    final picked   = await showDatePicker(
      context:     context,
      initialDate: state.dateOfBirth ?? DateTime(now.year - 20, now.month, now.day),
      firstDate:   DateTime(now.year - 100),
      lastDate:    DateTime(now.year - 18, now.month, now.day),
      helpText:    'Select your date of birth',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      notifier.updateDateOfBirth(picked);
      _dobController.text = _formatDate(picked);
    }
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    final notifier = ref.read(registrationProvider.notifier);
    final picker   = ImagePicker();
    final picked   = await picker.pickImage(
      source:       source,
      maxWidth:     1024,
      maxHeight:    1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _profileImageFile = File(picked.path));
      notifier.updateProfileImage(picked.path);
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSourceSheet(
        onGallery: () {
          Navigator.pop(context);
          _pickProfilePhoto(ImageSource.gallery);
        },
        onCamera: () {
          Navigator.pop(context);
          _pickProfilePhoto(ImageSource.camera);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _submit() async {
    final notifier = ref.read(registrationProvider.notifier);
    notifier.updateName(_nameController.text);
    notifier.updateEmail(_emailController.text);
    notifier.updatePassword(_passwordController.text);
    notifier.updateUniversity(_universityController.text);
    notifier.updateBio(_bioController.text);

    final state        = ref.read(registrationProvider);
    final s1           = notifier.validateStep1();
    final s2           = notifier.validateStep2();
    final s3           = notifier.validateStep3();
    final hasInterests = state.interests.isNotEmpty;

    if (!s1 || !s2 || !s3 || !hasInterests) {
      if (!s1)      { setState(() => _currentPage = 0); _pageController.jumpToPage(0); }
      else if (!s2) { setState(() => _currentPage = 1); _pageController.jumpToPage(1); }
      else {
        setState(() => _currentPage = 2);
        _pageController.jumpToPage(2);
        if (!hasInterests) _showErrorMessage('Please select at least one interest');
      }
      return;
    }

    final success = await notifier.register();
    if (success && mounted) {
      // Success handled via authProvider listener
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: const TextStyle(fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: AppColors.error,
        behavior:        SnackBarBehavior.floating,
        shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: const TextStyle(fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: AppColors.success,
        behavior:        SnackBarBehavior.floating,
        shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationProvider);
    _syncControllers(state);

    ref.listen<AuthState>(authProvider, (_, next) {
      next.when(
        unauthenticated: () {},
        loading:         () {},
        authenticated:   (_, __) {
          if (!mounted) return;
          _showSuccessMessage('Account created successfully! 🎉');
          Navigator.pop(context);
        },
      );
    });

    if (state.generalError != null &&
        state.generalError != _lastShownError &&
        mounted) {
      _lastShownError = state.generalError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && state.generalError == _lastShownError) {
          _showErrorMessage(state.generalError!);
        }
      });
    } else if (state.generalError == null) {
      _lastShownError = null;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildGradientHeader(),
          _buildStepIndicator(),
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics:    const NeverScrollableScrollPhysics(),
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _buildStepOneBasic(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _buildStepTwoDetails(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _buildStepThreeProfile(),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ── Gradient header ───────────────────────────────────────────────────────

  static const _headerTitles = [
    'Create Account', 'Your Profile', 'Your Interests',
  ];
  static const _headerSubtitles = [
    'Start your UniFye journey',
    'Tell us about yourself',
    'What makes you, you?',
  ];

  Widget _buildGradientHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: FadeTransition(
        opacity: _headerFade,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.maybePop(context),
                  padding:     EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color:  Colors.white.withOpacity(0.2),
                    shape:  BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey(_currentPage),
                children: [
                  Text(
                    _headerTitles[_currentPage],
                    style: const TextStyle(
                      fontSize:      26,
                      fontWeight:    FontWeight.w800,
                      color:         Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _headerSubtitles[_currentPage],
                    style: TextStyle(
                      fontSize: 14,
                      color:    Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final done = (i ~/ 2) < _currentPage;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                decoration: BoxDecoration(
                  color:        done ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final idx    = i ~/ 2;
          final active = idx == _currentPage;
          final done   = idx < _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width:  active ? 36 : 28,
            height: active ? 36 : 28,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              color:  done || active ? AppColors.primary : AppColors.surface,
              border: Border.all(
                color: done || active ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
              boxShadow: active
                  ? [BoxShadow(
                color:        AppColors.primary.withOpacity(0.3),
                blurRadius:   8,
                spreadRadius: 1,
              )]
                  : null,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : Icon(
                _steps[idx].icon,
                size:  active ? 18 : 14,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1: Account ───────────────────────────────────────────────────────

  Widget _buildStepOneBasic() {
    final state    = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel(label: 'Your credentials'),
        const SizedBox(height: 16),
        AppTextField(
          label:           'Full Name',
          hint:            'e.g. Alex Johnson',
          controller:      _nameController,
          errorText:       state.nameError,
          textInputAction: TextInputAction.next,
          onChanged:       notifier.updateName,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label:           'University Email',
          hint:            'you@university.edu',
          controller:      _emailController,
          inputType:       AppInputType.email,
          errorText:       state.emailError,
          textInputAction: TextInputAction.next,
          onChanged:       notifier.updateEmail,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label:           'Password',
          hint:            'Min. 8 characters',
          controller:      _passwordController,
          inputType:       AppInputType.password,
          errorText:       state.passwordError,
          textInputAction: TextInputAction.done,
          onChanged:       notifier.updatePassword,
        ),
        const SizedBox(height: 10),
        _PasswordStrength(password: state.password),
        const SizedBox(height: 20),
        const _InfoTile(
          icon: Icons.school_outlined,
          text: 'Your university email verifies that you\'re a genuine student.',
        ),
      ],
    );
  }

  // ── Step 2: Profile details ───────────────────────────────────────────────

  Widget _buildStepTwoDetails() {
    final state    = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel(label: 'About you'),
        const SizedBox(height: 16),
        AppTextField(
          label:           'University',
          hint:            'e.g. University of Cape Town',
          controller:      _universityController,
          errorText:       state.universityError,
          textInputAction: TextInputAction.next,
          onChanged:       notifier.updateUniversity,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label:           'Date of Birth',
          hint:            'Tap to select',
          controller:      _dobController,
          readOnly:        true,
          errorText:       state.dobError,
          suffixIcon:      Icons.calendar_month_rounded,
          onSuffixIconTap: _pickDateOfBirth,
          onTap:           _pickDateOfBirth,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        _buildGenderSelector(),
      ],
    );
  }

  Widget _buildGenderSelector() {
    final state    = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);
    final isMale   = state.gender == 'Male';
    final isFemale = state.gender == 'Female';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I identify as',
          style: TextStyle(
            fontSize:   14,
            fontWeight: FontWeight.w600,
            color:      AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text:      'Male',
                type:      isMale ? AppButtonType.primary : AppButtonType.outline,
                onPressed: () => notifier.updateGender('Male'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text:      'Female',
                type:      isFemale ? AppButtonType.primary : AppButtonType.outline,
                onPressed: () => notifier.updateGender('Female'),
              ),
            ),
          ],
        ),
        if (state.genderError != null) ...[
          const SizedBox(height: 6),
          Text(
            state.genderError!,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],
    );
  }

  // ── Step 3: Interests & photo ─────────────────────────────────────────────

  Widget _buildStepThreeProfile() {
    final state    = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhotoPicker(),
        const SizedBox(height: 20),
        const _SectionLabel(label: 'Your bio'),
        const SizedBox(height: 10),
        AppTextField(
          label:      'About Me',
          hint:       'Share something interesting about yourself…',
          controller: _bioController,
          inputType:  AppInputType.multiline,
          maxLines:   4,
          errorText:  state.bioError,
          onChanged:  notifier.updateBio,
        ),
        const SizedBox(height: 20),
        _buildInterestCatalog(),
        if (state.interests.isEmpty) ...[
          const SizedBox(height: 6),
          const Text(
            'Select at least one interest',
            style: TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel(label: 'Profile photo'),
        const SizedBox(height: 12),
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _showPhotoSourceSheet,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(
                      color: _profileImageFile != null
                          ? AppColors.primary
                          : AppColors.border,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:      AppColors.primary.withOpacity(
                            _profileImageFile != null ? 0.2 : 0.06),
                        blurRadius: 16,
                        offset:     const Offset(0, 6),
                      ),
                    ],
                    image: _profileImageFile != null
                        ? DecorationImage(
                      image: FileImage(_profileImageFile!),
                      fit:   BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _profileImageFile == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          color: AppColors.textSecondary, size: 28),
                      SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize:   11,
                          color:      AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                      : null,
                ),
              ),
              if (_profileImageFile != null)
                Positioned(
                  bottom: 0, right: 0,
                  child: GestureDetector(
                    onTap: _showPhotoSourceSheet,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape:  BoxShape.circle,
                        color:  AppColors.primary,
                        border: Border.all(
                            color: AppColors.background, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_profileImageFile != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton(
                text:      'Change Photo',
                type:      AppButtonType.outline,
                size:      AppButtonSize.medium,
                onPressed: _showPhotoSourceSheet,
              ),
              const SizedBox(width: 12),
              AppButton(
                text:      'Remove',
                type:      AppButtonType.text,
                size:      AppButtonSize.medium,
                onPressed: () => setState(() => _profileImageFile = null),
              ),
            ],
          )
        else ...[
          AppButton(
            text:        'Choose Photo',
            type:        AppButtonType.outline,
            isFullWidth: true,
            onPressed:   _showPhotoSourceSheet,
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Profiles with a photo get 5× more matches',
              style: TextStyle(
                fontSize:  12,
                color:     AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInterestCatalog() {
    final state    = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel(label: 'Interests'),
            const Spacer(),
            Text(
              '${state.interests.length} selected',
              style: TextStyle(
                fontSize:   12,
                color:      state.interests.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Select everything that excites you',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing:    8,
          runSpacing: 8,
          children: _interestCatalog.map((interest) {
            final isSelected = state.interests.contains(interest.label);
            return GestureDetector(
              onTap: () => notifier.toggleInterest(interest.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.border,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                    color:      AppColors.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset:     const Offset(0, 4),
                  )]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(interest.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      interest.label,
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
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

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final state   = ref.watch(registrationProvider);
    final bottom  = MediaQuery.of(context).padding.bottom;
    final isFinal = _currentPage == 2;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 12),
      decoration: BoxDecoration(
        color:  AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentPage > 0) ...[
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text:      'Back',
                    type:      AppButtonType.outline,
                    onPressed: _prevPage,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 3,
                child: AppButton(
                  text:        isFinal ? 'Create Account ✨' : 'Continue',
                  type:        AppButtonType.primary,
                  isLoading:   isFinal && state.isLoading,
                  onPressed:   state.isLoading ? null : (isFinal ? _submit : _nextPage),
                  isFullWidth: true,
                  size:        AppButtonSize.large,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSignInLink(),
        ],
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color:      AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize:   13,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Photo source bottom sheet — uses AppButton
// ═══════════════════════════════════════════════════════════════════════════
class _PhotoSourceSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onCancel;

  const _PhotoSourceSheet({
    required this.onGallery,
    required this.onCamera,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color:        AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Add Profile Photo',
            style: TextStyle(
              fontSize:   18,
              fontWeight: FontWeight.w700,
              color:      AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how to add your photo',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text:        'Gallery',
                  type:        AppButtonType.outline,
                  isFullWidth: true,
                  onPressed:   onGallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text:        'Camera',
                  type:        AppButtonType.primary,
                  isFullWidth: true,
                  onPressed:   onCamera,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppButton(
            text:        'Cancel',
            type:        AppButtonType.text,
            isFullWidth: true,
            onPressed:   onCancel,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Password strength indicator
// ═══════════════════════════════════════════════════════════════════════════
class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  int get _strength {
    if (password.isEmpty) return 0;
    int s = 0;
    if (password.length >= 8)                               s++;
    if (RegExp(r'[A-Z]').hasMatch(password))                s++;
    if (RegExp(r'[0-9]').hasMatch(password))                s++;
    if (RegExp(r'[!@#\$&*~%^()_+\-=]').hasMatch(password)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final s      = _strength;
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    final colors = [AppColors.error, Colors.orange, Colors.amber, AppColors.success];
    final label  = s > 0 ? labels[s - 1] : '';
    final color  = s > 0 ? colors[s - 1] : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(4, (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color:        i < s ? color : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Password strength: $label',
            style: TextStyle(
              fontSize:   11,
              color:      color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reusable small widgets
// ═══════════════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label, super.key});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      fontSize:      11,
      fontWeight:    FontWeight.w700,
      color:         AppColors.textSecondary,
      letterSpacing: 0.8,
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoTile({required this.icon, required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color:    AppColors.textSecondary,
                height:   1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
