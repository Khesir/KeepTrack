import 'package:flutter/material.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/features/profile/presentation/widgets/user_info_card.dart';
import 'package:keep_track/features/profile/presentation/widgets/balance_graph.dart';

class ProfileScreen extends ScopedScreen {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ScopedScreenState<ProfileScreen>
    with AppLayoutControlled {
  @override
  void registerServices() {
    // No services needed
  }

  @override
  void onReady() {
    configureLayout(title: 'Profile', showBottomNav: true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Card
          const UserInfoCard(),
          const SizedBox(height: 24),

          // Balance Graph
          Text(
            'Balance Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          const BalanceGraph(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
