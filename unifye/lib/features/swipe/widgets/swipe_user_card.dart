import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unifye/core/theme/app_colour.dart';
import 'package:unifye/features/swipe/models/swipe_candidate.dart';

class SwipeUserCard extends StatelessWidget {
  const SwipeUserCard({
    super.key,
    required this.candidate,
  });

  final SwipeCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-bleed photo ──────────────────────────────────
          _buildProfilePhoto(),

          // ── Bottom gradient scrim ─────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.45, 0.75, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // ── Profile info overlay ──────────────────────────────
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _buildInfoOverlay(context),
          ),

          // ── Top gradient (subtle) for any future top badges ───
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoOverlay(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Interests
        if (candidate.interests.isNotEmpty) ...[
          _buildInterestChips(),
          const SizedBox(height: 10),
        ],

        // Name row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                candidate.fullName,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                  shadows: [
                    const Shadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Gender + DOB row
        Row(
          children: [
            _buildMetaPill(
              icon: _genderIcon(candidate.gender),
              label: candidate.gender,
            ),
            const SizedBox(width: 8),
            _buildMetaPill(
              icon: Icons.cake_outlined,
              label: _formatDob(candidate.dateOfBirth),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestChips() {
    // Show at most 4 chips to avoid overflow
    final shown = candidate.interests.take(4).toList();
    final overflow = candidate.interests.length - shown.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...shown.map(
              (interest) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              interest,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (overflow > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white38, width: 1),
            ),
            child: Text(
              '+$overflow more',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetaPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    final imageUrl = candidate.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPhotoFallback();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingState(loadingProgress);
      },
      errorBuilder: (_, __, ___) => _buildPhotoFallback(),
    );
  }

  Widget _buildLoadingState(ImageChunkEvent loadingProgress) {
    final total = loadingProgress.expectedTotalBytes;
    final loaded = loadingProgress.cumulativeBytesLoaded;
    final progress = total != null ? loaded / total : null;

    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                backgroundColor: Colors.white12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading profile...',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoFallback() {
    // Derive initials from name
    final parts = candidate.fullName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : candidate.fullName.isNotEmpty
        ? candidate.fullName[0].toUpperCase()
        : '?';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B33), Color(0xFF1A1A2E)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No photo yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Converts a raw DOB string/DateTime into something readable.
  /// Adjust this logic to match your actual `candidate.dateOfBirth` type.
  String _formatDob(dynamic dob) {
    if (dob == null) return 'Unknown';
    // If it's already a DateTime:
    if (dob is DateTime) {
      final age = DateTime.now().year - dob.year;
      return '$age yrs';
    }
    // If it's a String like "1995-04-16":
    try {
      final parsed = DateTime.parse(dob.toString());
      final age = DateTime.now().year - parsed.year;
      return '$age yrs';
    } catch (_) {
      return dob.toString();
    }
  }

  IconData _genderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'm':
        return Icons.male;
      case 'female':
      case 'f':
        return Icons.female;
      default:
        return Icons.transgender;
    }
  }
}