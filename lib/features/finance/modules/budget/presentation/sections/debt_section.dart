import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../debt/domain/entities/debt.dart';
import '../widgets/debt_row.dart';
import '../widgets/ghost_add_row.dart';

class DebtSection extends StatelessWidget {
  final String title;
  final List<Debt> debts;
  final bool isReceivable;
  final Debt? selectedDebt;
  final VoidCallback onAdd;
  final void Function(Debt) onPay;
  final void Function(Debt) onEdit;
  final void Function(Debt) onSelect;
  final Future<void> Function(Debt, double) onUpdateMonthlyPayment;

  const DebtSection({
    super.key,
    required this.title,
    required this.debts,
    required this.isReceivable,
    required this.onAdd,
    required this.onPay,
    required this.onEdit,
    required this.onSelect,
    required this.onUpdateMonthlyPayment,
    this.selectedDebt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          child: Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  isReceivable ? 'Outstanding' : 'Balance',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: Text(
                  isReceivable ? 'Expected' : 'Planned',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: Text(
                  isReceivable ? 'Received' : 'Paid',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(
                width: 78,
              ), // spacer for Edit + Pay/Collect button columns
            ],
          ),
        ),
        ...debts.map(
          (d) => DebtRow(
            key: ValueKey(d.id),
            debt: d,
            isReceivable: isReceivable,
            isSelected: selectedDebt?.id == d.id,
            onSelect: () => onSelect(d),
            onPay: () => onPay(d),
            onEdit: () => onEdit(d),
            onUpdateMonthlyPayment: (amount) =>
                onUpdateMonthlyPayment(d, amount),
          ),
        ),
        // Ghost add button
        GhostAddRow(
          label: isReceivable ? 'Add Receivable' : 'Add Debt',
          onTap: onAdd,
        ),
      ],
    );
  }
}
