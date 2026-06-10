import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import '../../modules/transaction/domain/entities/transaction.dart';

class TransactionAmountHeader extends StatelessWidget {
  final TransactionType selectedType;
  final TextEditingController amountController;
  final ValueChanged<TransactionType> onTypeChanged;

  const TransactionAmountHeader({
    super.key,
    required this.selectedType,
    required this.amountController,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final typeColor = selectedType == TransactionType.income
        ? Colors.green.shade600
        : colorScheme.error;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Income'),
                icon: Icon(Icons.arrow_downward, size: 16),
              ),
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Expense'),
                icon: Icon(Icons.arrow_upward, size: 16),
              ),
            ],
            selected: {selectedType},
            onSelectionChanged: (selection) => onTypeChanged(selection.first),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                currencyFormatter.currencySymbol,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: amountController,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: theme.textTheme.displaySmall?.copyWith(
                      color: colorScheme.outlineVariant,
                      fontWeight: FontWeight.w300,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter an amount';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
