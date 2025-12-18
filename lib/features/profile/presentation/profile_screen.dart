import 'package:flutter/material.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';
import 'package:persona_codex/features/profile/presentation/widgets/user_info_card.dart';
import 'package:persona_codex/features/profile/presentation/widgets/contribution_chart.dart';
import 'package:persona_codex/features/profile/presentation/widgets/balance_graph.dart';

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
      padding: GCashSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Card
          const UserInfoCard(),
          const SizedBox(height: 24),

          // GitHub-like Contribution Chart for Tasks
          Text(
            'Task Activity',
            style: GCashTextStyles.h2,
          ),
          const SizedBox(height: 12),
          const ContributionChart(),
          const SizedBox(height: 24),

          // Balance Graph
          Text(
            'Balance Overview',
            style: GCashTextStyles.h2,
          ),
          const SizedBox(height: 12),
          const BalanceGraph(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
