import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../debt/domain/entities/debt.dart';
import '../../../planned_payment/domain/entities/planned_payment.dart';
import '../../domain/entities/budget.dart';
import '../helpers/currency_formatter.dart';

class BudgetSummaryBar extends StatelessWidget {
  // Month navigation
  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  // Budget data
  final List<Budget> monthBudgets;
  final Map<String, double> spentByCategory;
  final List<PlannedPayment> activePayments;
  final List<Debt> activeDebts;
  final List<Debt> activeReceivables;
  final VoidCallback onCommitmentsTab;

  // Tab counts
  final int budgetGroupCount;
  final int subsCount;
  final int debtsCount;
  final int receivablesCount;
  final int goalsCount;

  // Tab selection
  final int selectedTab;
  final void Function(int) onTabSelect;

  // Narrow-only actions (hidden on wide where they live in the side panel)
  final VoidCallback? onToggleView;
  final VoidCallback? onSettings;
  final VoidCallback? onSummaryTap;

  const BudgetSummaryBar({
    super.key,
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
    required this.selectedTab,
    required this.onTabSelect,
    required this.monthBudgets,
    required this.spentByCategory,
    required this.activePayments,
    required this.activeDebts,
    required this.activeReceivables,
    required this.onCommitmentsTab,
    required this.budgetGroupCount,
    required this.subsCount,
    required this.debtsCount,
    required this.receivablesCount,
    required this.goalsCount,
    this.onToggleView,
    this.onSettings,
    this.onSummaryTap,
  });

  String _tabTitle(String monthLabel) => switch (selectedTab) {
    0 => 'Summary',
    1 => monthLabel,
    2 => 'Subscriptions',
    3 => 'Debts',
    4 => 'Receivables',
    5 => 'Goals',
    _ => monthLabel,
  };

  String _tabSubtitle(String leftLabel) => switch (selectedTab) {
    0 => 'Financial overview',
    1 => leftLabel,
    2 => '$subsCount active',
    3 => '$debtsCount active',
    4 => '$receivablesCount active',
    5 => '$goalsCount active',
    _ => leftLabel,
  };

  Color _tabSubtitleColor(Color leftColor) =>
      selectedTab == 1 ? leftColor : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = AppColors.border.withValues(alpha: isDark ? 0.15 : 0.35);
    final borderColor = AppColors.border.withValues(alpha: isDark ? 0.2 : 0.6);

    double plannedIncome = 0;
    double plannedExpenses = 0;
    for (final b in monthBudgets) {
      if (b.budgetType == BudgetType.income) {
        plannedIncome += b.budgetTarget;
      } else {
        plannedExpenses += b.budgetTarget;
      }
    }

    // Left to budget is purely budget-based (income groups vs expense groups).
    // Debts and receivables are tracked separately and excluded here.
    final leftToBudget = plannedIncome - plannedExpenses;
    final leftColor = leftToBudget > 0
        ? AppColors.success
        : leftToBudget < 0
            ? AppColors.error
            : AppColors.textSecondary;
    final leftLabel = leftToBudget == 0
        ? 'On budget'
        : '${formatCurrency(leftToBudget.abs())} left to budget';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Main header row ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title + subtitle — updates based on selected tab
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _tabTitle(monthLabel),
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tabSubtitle(leftLabel),
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _tabSubtitleColor(leftColor),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Narrow-only action buttons
              if (onSummaryTap != null)
                IconButton(
                  icon: Icon(Icons.bar_chart_rounded, color: AppColors.textSecondary),
                  onPressed: onSummaryTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              if (onToggleView != null)
                IconButton(
                  icon: Icon(Icons.view_list_outlined, color: AppColors.textSecondary),
                  onPressed: onToggleView,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              if (onSettings != null)
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                  onPressed: onSettings,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),

              const SizedBox(width: 8),

              // < > bordered nav buttons
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
                    Container(width: 0.5, height: 28, color: borderColor),
                    _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
                  ],
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: divColor),

        // ── Tab pills — responsive (wrap on narrow, scroll on wide) ──────
        LayoutBuilder(
          builder: (context, constraints) {
            final pills = [
              _TabPill(label: 'Summary', count: 0, color: AppColors.info, selected: selectedTab == 0, onTap: () => onTabSelect(0)),
              _TabPill(label: 'Budget', count: budgetGroupCount, color: AppColors.accent, selected: selectedTab == 1, onTap: () => onTabSelect(1)),
              _TabPill(label: 'Subs', count: subsCount, color: AppColors.warning, selected: selectedTab == 2, onTap: () => onTabSelect(2)),
              _TabPill(label: 'Debts', count: debtsCount, color: AppColors.error, selected: selectedTab == 3, onTap: () => onTabSelect(3)),
              _TabPill(label: 'Receivables', count: receivablesCount, color: AppColors.success, selected: selectedTab == 4, onTap: () => onTabSelect(4)),
              _TabPill(label: 'Goals', count: goalsCount, color: AppColors.accent, selected: selectedTab == 5, onTap: () => onTabSelect(5)),
              if (activePayments.isNotEmpty)
                _TabPill(label: 'Commitments', count: activePayments.length, color: AppColors.info, selected: false, onTap: onCommitmentsTab),
            ];

            if (constraints.maxWidth < 520) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Wrap(spacing: 6, runSpacing: 6, children: pills),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: pills
                    .map((p) => Padding(padding: const EdgeInsets.only(right: 6), child: p))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Icon(icon, size: 18, color: AppColors.textSecondary),
    ),
  );
}

class _TabPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _TabPill({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected
        ? color
        : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white);
    final borderColor = selected
        ? Colors.transparent
        : AppColors.border.withValues(alpha: isDark ? 0.2 : 1.0);
    final textColor = selected
        ? Colors.white
        : (count > 0
            ? (isDark ? AppColors.primaryForeground : AppColors.textPrimary)
            : AppColors.textTertiary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!selected)
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: count > 0 ? color : AppColors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              count > 0 ? '$label ($count)' : label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
