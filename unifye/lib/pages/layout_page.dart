import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/pages/swipe-page.dart';

import '../core/theme/app_colour.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/subscription/models/subscription_plan.dart';
import '../features/subscription/providers/subscription_provider.dart';
import 'change_plan_page.dart';

enum AppTab {
  discover('Discover', Icons.explore_rounded, Icons.explore_outlined),
  events('Events', Icons.event_rounded, Icons.event_outlined),
  community('Community', Icons.groups_rounded, Icons.groups_outlined),
  leaderboard(
      'Rankings', Icons.leaderboard_rounded, Icons.leaderboard_outlined),
  profile('Profile', Icons.person_rounded, Icons.person_outlined);

  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const AppTab(this.label, this.activeIcon, this.inactiveIcon);
}

// ─── Layout Provider ─────────────────────────────────────────────────────────

final activeTabProvider = StateProvider<AppTab>((ref) => AppTab.discover);

// ─── Layout Page ─────────────────────────────────────────────────────────────

class LayoutPage extends ConsumerStatefulWidget {
  const LayoutPage({super.key});

  @override
  ConsumerState<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends ConsumerState<LayoutPage>
    with SingleTickerProviderStateMixin {
  // Each tab gets its own navigator key to preserve page state on tab switch
  final Map<AppTab, GlobalKey<NavigatorState>> _navigatorKeys = {
    for (final tab in AppTab.values) tab: GlobalKey<NavigatorState>(),
  };

  @override
  void initState() {
    super.initState();
    // Load subscription data once on layout mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).loadPlans();
      ref.read(subscriptionProvider.notifier).loadMySubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(activeTabProvider);
    final mySubscription = ref.watch(mySubscriptionProvider);

    return PopScope(
      canPop: false,
      // Handle Android back button — navigate within tab before leaving app
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final navigatorKey = _navigatorKeys[activeTab]!;
        if (navigatorKey.currentState?.canPop() == true) {
          navigatorKey.currentState!.pop();
          return;
        }
        if (activeTab != AppTab.discover) {
          ref.read(activeTabProvider.notifier).state = AppTab.discover;
        }
      },
      child: Scaffold(
        body: Stack(
          children: AppTab.values.map((tab) {
            final isActive = tab == activeTab;
            return Offstage(
              offstage: !isActive,
              child: _TabNavigator(
                navigatorKey: _navigatorKeys[tab]!,
                tab: tab,
              ),
            );
          }).toList(),
        ),
        bottomNavigationBar: _UniFyeBottomNavBar(
          activeTab: activeTab,
          mySubscription: mySubscription,
          onTabSelected: (tab) {
            final currentTab = ref.read(activeTabProvider);
            if (currentTab == tab) {
              // Tap same tab → pop to root of that tab's stack
              _navigatorKeys[tab]?.currentState?.popUntil((r) => r.isFirst);
            } else {
              ref.read(activeTabProvider.notifier).state = tab;
            }
          },
        ),
      ),
    );
  }
}

// ─── Tab Navigator ───────────────────────────────────────────────────────────

class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final AppTab tab;

  const _TabNavigator({required this.navigatorKey, required this.tab});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => _buildTabRoot(tab),
        );
      },
    );
  }

  Widget _buildTabRoot(AppTab tab) {
    switch (tab) {
      case AppTab.discover:
        return const SwipePage();
      case AppTab.events:
        return const _EventsPlaceholderPage();
      case AppTab.community:
        return const _CommunityPlaceholderPage();
      case AppTab.leaderboard:
        return const _LeaderboardPlaceholderPage();
      case AppTab.profile:
        return const _ProfilePlaceholderPage();
    }
  }
}

// ─── Bottom Navigation Bar ───────────────────────────────────────────────────

class _UniFyeBottomNavBar extends ConsumerWidget {
  final AppTab activeTab;
  final UserSubscriptionStatus? mySubscription;
  final ValueChanged<AppTab> onTabSelected;

  const _UniFyeBottomNavBar({
    required this.activeTab,
    required this.mySubscription,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: AppTab.values.map((tab) {
              final isActive = tab == activeTab;
              return _NavItem(
                tab: tab,
                isActive: isActive,
                showPremiumBadge: tab == AppTab.community &&
                    mySubscription != null &&
                    !mySubscription!.permissions.canCreateCommunity,
                onTap: () => onTabSelected(tab),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppTab tab;
  final bool isActive;
  final bool showPremiumBadge;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.showPremiumBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? tab.activeIcon : tab.inactiveIcon,
                    key: ValueKey(isActive),
                    color:
                        isActive ? AppColors.primary : AppColors.textTertiary,
                    size: 24,
                  ),
                ),
                if (showPremiumBadge)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textTertiary,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plan Banner (shown on profile tab when on Free) ─────────────────────────

class PlanUpgradeBanner extends ConsumerWidget {
  const PlanUpgradeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mySubscription = ref.watch(mySubscriptionProvider);
    if (mySubscription == null || !mySubscription.isFree) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_rounded,
              color: Colors.white, size: 28),
          const SizedBox(width: 12),
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
                  'Unlimited swipes, see who liked you & more',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChangePlanPage()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder Pages (replace with real implementations) ───────────────────

class _EventsPlaceholderPage extends ConsumerWidget {
  const _EventsPlaceholderPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mySubscription = ref.watch(mySubscriptionProvider);
    final canCreate = mySubscription?.permissions.canCreateEvents ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Create Event',
              onPressed: () {},
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_rounded,
                size: 64, color: AppColors.secondary),
            const SizedBox(height: 16),
            const Text(
              'Events coming soon!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse and create campus events',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (!canCreate) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChangePlanPage()),
                ),
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Create Events — Upgrade to Pro'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommunityPlaceholderPage extends StatelessWidget {
  const _CommunityPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_rounded, size: 64, color: AppColors.secondary),
            SizedBox(height: 16),
            Text(
              'Communities coming soon!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Join and build campus communities',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardPlaceholderPage extends StatelessWidget {
  const _LeaderboardPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rankings')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_rounded,
                size: 64, color: AppColors.secondary),
            SizedBox(height: 16),
            Text(
              'Leaderboard coming soon!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'See who is most connected on campus',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePlaceholderPage extends ConsumerWidget {
  const _ProfilePlaceholderPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      unauthenticated: () => const SizedBox.shrink(),
      loading: () => const Center(child: CircularProgressIndicator()),
      authenticated: (user, token) => Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {},
            ),
          ],
        ),
        body: ListView(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
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
                              fontSize: 32,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            // Plan upgrade banner
            const PlanUpgradeBanner(),

            // Subscription info tile
            _SubscriptionInfoTile(),

            const Divider(height: 32),

            // Change plan button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChangePlanPage()),
                ),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Change Plan'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.textSecondary),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionInfoTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(mySubscriptionProvider);
    if (sub == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan: ${sub.tierDisplayName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub.isTrialing
                      ? 'Trial ends ${_formatDate(sub.trialEnd)}'
                      : sub.isFree
                          ? 'Free plan — upgrade to unlock more'
                          : sub.daysRemainingInPeriod != null
                              ? '${sub.daysRemainingInPeriod} days remaining'
                              : 'Active',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
