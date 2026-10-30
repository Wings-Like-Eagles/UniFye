import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';
import 'package:unifye/features/swipe/providers/swipe_provider.dart';
import 'package:unifye/features/swipe/widgets/swipe_user_card.dart';
import 'package:unifye/core/theme/app_colour.dart';
import 'package:unifye/core/widgets/app_button.dart';
import 'package:unifye/features/swipe/widgets/profile_detail_sheet.dart';

class SwipePage extends ConsumerStatefulWidget {
  const SwipePage({super.key});

  @override
  ConsumerState<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends ConsumerState<SwipePage>
    with SingleTickerProviderStateMixin {
  String? _activeUserId;
  String? _lastToast;

  // Animation for action buttons appearing
  late AnimationController _buttonsAnimController;
  late Animation<Offset> _buttonsSlideAnimation;
  late Animation<double> _buttonsFadeAnimation;

  @override
  void initState() {
    super.initState();
    _buttonsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _buttonsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonsAnimController,
      curve: Curves.easeOutCubic,
    ));
    _buttonsFadeAnimation = CurvedAnimation(
      parent: _buttonsAnimController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _buttonsAnimController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final swipeState = ref.watch(swipeProvider);

    return authState.when(
      unauthenticated: () => const Scaffold(
        body: Center(child: Text('Please login first.')),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      authenticated: (user, token) {
        // Load candidates when user changes
        if (_activeUserId != user.id) {
          _activeUserId = user.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(swipeProvider.notifier).loadCandidates(user.id);
          });
        }

        // Animate buttons in when candidates are available
        if (swipeState.candidates.isNotEmpty) {
          _buttonsAnimController.forward();
        } else {
          _buttonsAnimController.reverse();
        }

        _consumeTransientMessages(swipeState);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F7FA),
          appBar: _buildAppBar(user.id, swipeState),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildBody(user.id, swipeState),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String userId, SwipeState swipeState) {
    return AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text(
            'Discover',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      centerTitle: false,
      backgroundColor: const Color(0xFFF7F7FA),
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        // Candidate counter badge
        if (swipeState.candidates.isNotEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${swipeState.candidates.length} nearby',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        // Refresh button
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: swipeState.isLoading
                ? const SizedBox(
              key: ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
                : const Icon(
              key: ValueKey('icon'),
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
          ),
          onPressed: swipeState.isLoading
              ? null
              : () => ref
              .read(swipeProvider.notifier)
              .loadCandidates(_activeUserId!),
        ),
      ],
    );
  }

  Widget _buildBody(String userId, SwipeState state) {
    // ── Loading (initial) ──────────────────────────────────────────────────
    if (state.isLoading && state.candidates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Finding people near you…',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // ── Error (no candidates loaded) ───────────────────────────────────────
    if (state.error != null && state.candidates.isEmpty) {
      return _buildEmptyState(
        userId: userId,
        icon: Icons.wifi_off_rounded,
        iconColor: Colors.redAccent,
        title: 'Something went wrong',
        subtitle: state.error!,
        primaryLabel: 'Try Again',
        onPrimary: () =>
            ref.read(swipeProvider.notifier).loadCandidates(userId),
      );
    }

    // ── Empty state ────────────────────────────────────────────────────────
    if (state.candidates.isEmpty) {
      return _buildEmptyState(
        userId: userId,
        icon: Icons.people_outline_rounded,
        iconColor: AppColors.secondaryDark,
        title: "You're all caught up!",
        subtitle: state.infoMessage ?? 'No more profiles right now. Come back later.',
        primaryLabel: 'Reload',
        onPrimary: () =>
            ref.read(swipeProvider.notifier).loadCandidates(userId),
        secondaryLabel: 'Change Plan',
        onSecondary: () =>
            ref.read(swipeProvider.notifier).loadCandidates(userId),
      );
    }

    // ── Main card + buttons ────────────────────────────────────────────────
    final candidate = state.candidates.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: SwipeUserCard(
                  candidate: candidate,
                  onTap: () => _showProfileDetail(context, userId, state),
                ),
              ),
              // Swipe overlay
              if (state.isSwiping)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Animated action buttons
        SlideTransition(
          position: _buttonsSlideAnimation,
          child: FadeTransition(
            opacity: _buttonsFadeAnimation,
            child: _buildActionButtons(userId, state),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String userId, SwipeState state) {
    return Row(
      children: [
        // Pass
        Expanded(
          child: AppButton(
            onPressed: state.isSwiping
                ? null
                : () => ref.read(swipeProvider.notifier).swipeCurrent(
              userId: userId,
              isLiked: false,
            ),
            text: state.isSwiping ? 'Wait…' : 'Pass',
            type: AppButtonType.outline,
            icon: Icons.close_rounded,
            isFullWidth: true,
          ),
        ),
        const SizedBox(width: 12),
        // Like
        Expanded(
          child: AppButton(
            onPressed: state.isSwiping
                ? null
                : () => ref.read(swipeProvider.notifier).swipeCurrent(
              userId: userId,
              isLiked: true,
            ),
            text: state.isSwiping ? 'Wait…' : 'Like',
            type: AppButtonType.primary,
            icon: Icons.favorite_rounded,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  void _showProfileDetail(BuildContext context, String userId, swipeState) {
    if (swipeState.candidates.isEmpty) return;
    final candidate = swipeState.candidates.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => ProfileDetailSheet(
        candidate: candidate,
        isSwiping: swipeState.isSwiping,
        onLike: () => ref.read(swipeProvider.notifier).swipeCurrent(
          userId: userId,
          isLiked: true,
        ),
        onPass: () => ref.read(swipeProvider.notifier).swipeCurrent(
          userId: userId,
          isLiked: false,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String userId,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (secondaryLabel != null && onSecondary != null) ...[
                  AppButton(
                    onPressed: onSecondary,
                    text: secondaryLabel,
                    type: AppButtonType.outline,
                  ),
                  const SizedBox(width: 12),
                ],
                AppButton(
                  onPressed: onPrimary,
                  text: primaryLabel,
                  type: AppButtonType.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _consumeTransientMessages(SwipeState swipeState) {
    final notifier = ref.read(swipeProvider.notifier);

    if (swipeState.error != null && swipeState.error != _lastToast) {
      _lastToast = swipeState.error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(swipeState.error!)),
              ],
            ),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
          ),
        );
        notifier.clearMessages();
      });
      return;
    }

    if (swipeState.matchMessage != null &&
        swipeState.matchMessage != _lastToast) {
      _lastToast = swipeState.matchMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(swipeState.matchMessage!)),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
          ),
        );
        notifier.clearMessages();
      });
      return;
    }

    if (swipeState.infoMessage != null &&
        swipeState.infoMessage != _lastToast) {
      _lastToast = swipeState.infoMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(swipeState.infoMessage!)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
          ),
        );
        notifier.clearMessages();
      });
    }
  }
}
