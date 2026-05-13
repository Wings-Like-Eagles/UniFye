import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/core/theme/app_colour.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';
import 'package:unifye/features/subscription/models/subscription_plan.dart';
import 'package:unifye/features/subscription/providers/subscription_provider.dart';
import 'package:unifye/pages/change_plan_page.dart';
import 'package:unifye/widgets/app_button.dart';

import '../features/profile/providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final mySubscription = ref.watch(mySubscriptionProvider);

    return authState.when(
      unauthenticated: () => const SizedBox.shrink(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      authenticated: (user, token) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(user, mySubscription),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 8),
                  if (mySubscription != null && mySubscription.isFree)
                    _buildUpgradeBanner(context),
                  const SizedBox(height: 8),
                  _buildSectionLabel('Account'),
                  _buildTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    subtitle: 'Photos, bio, interests',
                    onTap: () {
                      // TODO: Navigate to edit profile
                    },
                  ),
                  _buildTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    subtitle: 'Manage alerts',
                    onTap: () {},
                  ),
                  _buildTile(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    subtitle: 'Update your campus',
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _buildSectionLabel('Subscription'),
                  _buildSubscriptionTile(context, mySubscription),
                  const SizedBox(height: 8),
                  _buildSectionLabel('App'),
                  _buildTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Privacy & Safety',
                    onTap: () {},
                  ),
                  _buildTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                  _buildTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About UniFye',
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppButton(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      text: 'Sign Out',
                      type: AppButtonType.outline,
                      icon: Icons.logout_rounded,
                      isFullWidth: true,
                      size: AppButtonSize.large,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'UniFye v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sliver App Bar with Profile Header ──────────────────────────────────────

  SliverAppBar _buildSliverAppBar(dynamic user, UserSubscriptionStatus? sub) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
          onPressed: () {
            // TODO: navigate to settings
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.secondary,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                            : null,
                      ),
                    ),
                    // Edit avatar button
                    GestureDetector(
                      onTap: () {
                        // TODO: pick new photo
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Name
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                // Plan chip
                if (sub != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          sub.tierDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('Matches', '24'),
          _buildStatDivider(),
          _buildStat('Likes', '89'),
          _buildStatDivider(),
          _buildStat('Views', '142'),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.border,
    );
  }

  // ─── Upgrade Banner ───────────────────────────────────────────────────────────

  Widget _buildUpgradeBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChangePlanPage()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.rocket_launch_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Plus',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Unlimited swipes · See who liked you',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'R49/mo',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Subscription Tile ────────────────────────────────────────────────────────

  Widget _buildSubscriptionTile(
      BuildContext context, UserSubscriptionStatus? sub) {
    final label = sub == null
        ? 'Loading...'
        : sub.isTrialing
        ? 'Trial ends ${_formatDate(sub.trialEnd)}'
        : sub.isFree
        ? 'Free plan'
        : sub.daysRemainingInPeriod != null
        ? '${sub.daysRemainingInPeriod} days remaining'
        : 'Active';

    return _buildTile(
      icon: Icons.workspace_premium_rounded,
      label: 'Subscription',
      subtitle: label,
      onTap: () => Navigator.of(context).push(       // <-- add this
        MaterialPageRoute(builder: (_) => const ChangePlanPage()),
      ),
      trailing: AppButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChangePlanPage()),
        ),
        text: 'Change',
        type: AppButtonType.outline,
        size: AppButtonSize.small,
      ),
    );
  }
  // ─── Section Label ────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ─── Settings Tile ────────────────────────────────────────────────────────────

  Widget _buildTile({
    required IconData icon,
    required String label,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
