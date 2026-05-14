import 'package:flutter/material.dart';

import '../core/theme/app_colour.dart';

// Assuming your AppColors class is in a separate file, e.g., 'app_colors.dart'
// import 'app_colors.dart';

class AppTopTabBar extends StatelessWidget {
  const AppTopTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Unifye'), // Optional: main title
          backgroundColor: AppColors.surface,
          elevation: 0.5,
          shadowColor: AppColors.shadowLight,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Discover'),
              Tab(text: 'Matches'),
              Tab(text: 'Profile'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3.0,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: () {
                // Add your refresh logic here
                // e.g., ref.read(swipeProvider.notifier).loadCandidates(user.id)
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            DiscoverPage(),   // Your Discover content widget
            MatchesPage(),    // Placeholder
            ProfilePage(),    // Placeholder
          ],
        ),
      ),
    );
  }
}

// Example placeholder widgets – replace with your actual pages
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Discover Content'));
  }
}

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Matches Content'));
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile Content'));
  }
}