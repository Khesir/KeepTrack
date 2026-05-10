import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../debt/domain/entities/debt.dart';
import '../../../planned_payment/domain/entities/planned_payment.dart';
import '../../domain/entities/budget.dart';
import '../utils/currency_formatter.dart';

class BudgetSummaryBar extends StatelessWidget {
  final List<Budget> monthBudgets;
  final Map<String, double> spentByCategory;
  final List<PlannedPayment> activePayments;
  final List<Debt> activeDebts;
  final List<Debt> activeReceivables;
  final VoidCallback onCommitmentsTab;

  const BudgetSummaryBar({
    super.key,
    required this.monthBudgets,
    required this.spentByCategory,
    required this.activePayments,
    required this.activeDebts,
    required this.activeReceivables,
    required this.onCommitmentsTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double incomeReceived = 0;
    double expenseSpent = 0;
    double plannedIncome = 0;
    double plannedExpenses = 0;

    // Budget targets
    for (final b in monthBudgets) {
      if (b.budgetType == BudgetType.income) {
        for (final cat in b.categories) {
          incomeReceived += spentByCategory[cat.financeCategoryId] ?? 0.0;
        }
        plannedIncome += b.budgetTarget;
      } else {
        for (final cat in b.categories) {
          expenseSpent += spentByCategory[cat.financeCategoryId] ?? 0.0;
        }
        plannedExpenses += b.budgetTarget;
      }
    }

    // Receivables: expected incoming payments from people who owe the user
    for (final r in activeReceivables) {
      if (r.monthlyPaymentAmount > 0) {
        plannedIncome += r.monthlyPaymentAmount;
      }
    }

    // Debts: expected outgoing payments the user owes
    for (final d in activeDebts) {
      if (d.monthlyPaymentAmount > 0) {
        plannedExpenses += d.monthlyPaymentAmount;
      }
    }

    // Planned payments: recurring/scheduled expense commitments
    for (final p in activePayments) {
      plannedExpenses += p.amount;
    }

    final net = incomeReceived - expenseSpent;
    final netColor = net >= 0 ? AppColors.success : AppColors.error;

    // Planned net (how much should be left if plan is followed)
    final plannedNet = plannedIncome - plannedExpenses;
    final plannedNetColor = plannedNet >= 0
        ? AppColors.success
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actual row
          Row(
            children: [
              _SummaryChip(
                label: 'Income',
                value: formatCurrency(incomeReceived),
                valueColor: AppColors.success,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Expenses',
                value: formatCurrency(expenseSpent),
                valueColor: AppColors.error,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: net >= 0 ? 'Left' : 'Over',
                value: formatCurrency(net.abs()),
                valueColor: netColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Planned row
          Row(
            children: [
              _SummaryChip(
                label: 'Planned Inc.',
                value: formatCurrency(plannedIncome),
                valueColor: AppColors.success.withValues(alpha: 0.7),
                isPlanned: true,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Planned Exp.',
                value: formatCurrency(plannedExpenses),
                valueColor: AppColors.error.withValues(alpha: 0.7),
                isPlanned: true,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: plannedNet >= 0 ? 'Planned Left' : 'Planned Over',
                value: formatCurrency(plannedNet.abs()),
                valueColor: plannedNetColor.withValues(alpha: 0.7),
                isPlanned: true,
              ),
            ],
          ),
          () {
            final debtCount = activeDebts.length;
            final receivableCount = activeReceivables.length;
            final hasAny =
                activePayments.isNotEmpty ||
                debtCount > 0 ||
                receivableCount > 0;
            if (!hasAny) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (activePayments.isNotEmpty)
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      avatar: CircleAvatar(
                        radius: 9,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          '${activePayments.length}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      label: const Text(
                        'Planned Payments',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: onCommitmentsTab,
                    ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: CircleAvatar(
                      radius: 9,
                      backgroundColor: debtCount > 0
                          ? AppColors.error
                          : AppColors.textTertiary,
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                    label: Text(
                      '$debtCount Debt${debtCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: debtCount > 0 ? null : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: CircleAvatar(
                      radius: 9,
                      backgroundColor: receivableCount > 0
                          ? AppColors.success
                          : AppColors.textTertiary,
                      child: const Icon(
                        Icons.arrow_downward,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                    label: Text(
                      '$receivableCount Receivable${receivableCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: receivableCount > 0
                            ? null
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }(),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isPlanned;

  const _SummaryChip({
    required this.label,
    required this.value,
    this.valueColor,
    this.isPlanned = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPlanned
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
          borderRadius: BorderRadius.circular(8),
          border: isPlanned
              ? Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                  width: 0.5,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isPlanned) ...[
                  Icon(
                    Icons.schedule_outlined,
                    size: 9,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 2),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: isPlanned ? 9 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: isPlanned ? FontWeight.w500 : FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
                fontSize: isPlanned ? 11 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
