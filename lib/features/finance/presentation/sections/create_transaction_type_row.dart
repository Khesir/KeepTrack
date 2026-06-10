import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/widgets/create_transaction_chips.dart';

class CreateTransactionTypeRow extends StatelessWidget {
  final TransactionType type;
  final bool isPlan;
  final bool splitMode;
  final bool isDark;
  final VoidCallback onSelectExpense;
  final VoidCallback onSelectIncome;
  final VoidCallback onTogglePlan;
  final VoidCallback onToggleSplit;

  const CreateTransactionTypeRow({
    super.key,
    required this.type,
    required this.isPlan,
    required this.splitMode,
    required this.isDark,
    required this.onSelectExpense,
    required this.onSelectIncome,
    required this.onTogglePlan,
    required this.onToggleSplit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TransactionTypePill(
          label: 'Expense',
          color: AppColors.error,
          selected: type == TransactionType.expense,
          onTap: onSelectExpense,
        ),
        const SizedBox(width: 8),
        TransactionTypePill(
          label: 'Income',
          color: AppColors.success,
          selected: type == TransactionType.income,
          onTap: onSelectIncome,
        ),
        const Spacer(),
        PlanTogglePill(active: isPlan, onTap: onTogglePlan),
        if (!isPlan) ...[
          const SizedBox(width: 8),
          TransactionTypeChip(
            icon: Icons.call_split_rounded,
            label: 'Split',
            color: splitMode ? AppColors.accent : AppColors.textSecondary,
            isDark: isDark,
            highlighted: splitMode,
            onTap: onToggleSplit,
          ),
        ],
      ],
    );
  }
}
