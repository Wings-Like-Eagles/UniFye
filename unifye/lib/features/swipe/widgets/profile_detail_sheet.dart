import 'package:flutter/material.dart';
import 'package:unifye/features/swipe/models/swipe_candidate.dart';
import 'package:unifye/core/theme/app_colour.dart';
import 'package:unifye/core/widgets/app_button.dart';

/// Call via:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => ProfileDetailSheet(...),
/// );
/// ```
class ProfileDetailSheet extends StatelessWidget {
  final SwipeCandidate candidate;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final bool isSwiping;

  const ProfileDetailSheet({
    super.key,
    required this.candidate,
    required this.onLike,
    required this.onPass,
    required this.isSwiping,
  });

  int? _calculateAge(String dateOfBirth) {
    try {
      final dob = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(candidate.dateOfBirth);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 6),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Scrollable content ────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: bottomPadding + 12,
                  ),
                  children: [
                    // Profile image
                    _ProfileHeroImage(candidate: candidate),
                    const SizedBox(height: 20),

                    // Name + age
                    Text(
                      age != null
                          ? '${candidate.fullName}, $age'
                          : candidate.fullName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Gender row
                    if (candidate.gender.isNotEmpty)
                      _InfoRow(
                        icon: _genderIcon(candidate.gender),
                        label: candidate.gender,
                      ),

                    // Date of birth row (only if parseable)
                    if (age != null)
                      _InfoRow(
                        icon: Icons.cake_rounded,
                        label: _formatDob(candidate.dateOfBirth),
                      ),

                    const SizedBox(height: 24),

                    // Interests section
                    if (candidate.interests.isNotEmpty) ...[
                      _SectionLabel(label: 'Interests'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: candidate.interests
                            .map((interest) => _InterestChip(label: interest))
                            .toList(),
                      ),
                      const SizedBox(height: 28),
                    ] else
                      const SizedBox(height: 28),

                    // ── Action buttons ─────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            onPressed: isSwiping
                                ? null
                                : () {
                              Navigator.pop(context);
                              onPass();
                            },
                            text: 'Pass',
                            type: AppButtonType.outline,
                            icon: Icons.close_rounded,
                            isFullWidth: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            onPressed: isSwiping
                                ? null
                                : () {
                              Navigator.pop(context);
                              onLike();
                            },
                            text: 'Like',
                            type: AppButtonType.primary,
                            icon: Icons.favorite_rounded,
                            isFullWidth: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _genderIcon(String gender) {
    final lower = gender.toLowerCase();
    if (lower == 'female') return Icons.female_rounded;
    if (lower == 'male') return Icons.male_rounded;
    return Icons.person_rounded;
  }

  String _formatDob(String dateOfBirth) {
    try {
      final dob = DateTime.parse(dateOfBirth);
      // e.g. "12 March 2000"
      const months = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${dob.day} ${months[dob.month]} ${dob.year}';
    } catch (_) {
      return dateOfBirth;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeroImage extends StatelessWidget {
  final SwipeCandidate candidate;
  const _ProfileHeroImage({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 320,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            _image(),
            // Bottom gradient for name legibility
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.55, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    final url = candidate.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final initial = candidate.firstName.isNotEmpty
        ? candidate.firstName[0].toUpperCase()
        : '?';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8FAB), AppColors.primary, Color(0xFFB03A6F)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  const _InterestChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
