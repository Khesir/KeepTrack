import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class AccountsTab extends StatelessWidget {
  const AccountsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              // WalletCardRedesign(),
              SizedBox(height: AppSpacing.lg),
              // ExpenseReportCardRedesign(),
              SizedBox(height: AppSpacing.lg),
              // BudgetOverviewCardRedesign(),
              SizedBox(height: AppSpacing.lg),
              // RecentTransactionCardRedesign(),
              SizedBox(height: 80), // Extra space for floating action button
            ],
          ),
        ),
      ),
    );
  }
}
