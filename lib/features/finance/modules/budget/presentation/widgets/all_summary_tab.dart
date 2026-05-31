import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../debt/domain/entities/debt.dart';
import '../../../goal/domain/entities/goal.dart';
import '../../../subscriptions/domain/entities/subscription.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../domain/entities/budget.dart';
import '../screens/budget_simple_sections.dart' show SimpleDonutInsightCard;
import '../sections/budget_overall_summary.dart';

class AllSummaryTab extends StatelessWidget {
  final List<Budget> budgets;
  final List<Transaction> transactions;
  final List<Subscription> subscriptions;
  final List<Debt> debts;
  final List<Debt> receivables;
  final List<Goal> goals;
  final DateTime currentMonth;

  const AllSummaryTab({
    super.key,
    required this.budgets,
    required this.transactions,
    required this.subscriptions,
    required this.debts,
    required this.receivables,
    required this.goals,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (budgets.isEmpty) {
      return Center(
        child: Text(
          'No budget groups yet.',
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary),
        ),
      );
    }

    final spentByCategory = <String, double>{};
    for (final t in transactions) {
      if (t.financeCategoryId != null) {
        spentByCategory[t.financeCategoryId!] =
            (spentByCategory[t.financeCategoryId!] ?? 0.0) + t.amount;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BudgetOverallSummary(
            monthBudgets: budgets,
            spentByCategory: spentByCategory,
            subscriptions: subscriptions,
            debts: debts,
            receivables: receivables,
            goals: goals,
            transactions: transactions,
            currentMonth: currentMonth,
            isDark: isDark,
          ),
          SimpleDonutInsightCard(
            isDark: isDark,
            budgets: budgets,
            spentByCategory: spentByCategory,
          ),
        ],
      ),
    );
  }
}
