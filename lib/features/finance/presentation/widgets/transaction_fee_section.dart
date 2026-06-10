import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';

class TransactionFeeSection extends StatefulWidget {
  final TextEditingController feeController;
  final TextEditingController feeDescriptionController;

  const TransactionFeeSection({
    super.key,
    required this.feeController,
    required this.feeDescriptionController,
  });

  @override
  State<TransactionFeeSection> createState() => _TransactionFeeSectionState();
}

class _TransactionFeeSectionState extends State<TransactionFeeSection> {
  bool _showFeeFields = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final hasFee = widget.feeController.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showFeeFields = !_showFeeFields),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, size: 18, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasFee
                        ? 'Fee: ${currencyFormatter.currencySymbol}${widget.feeController.text}'
                        : 'Add Fee (Optional)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasFee
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  _showFeeFields ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_showFeeFields) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.feeController,
            decoration: InputDecoration(
              labelText: 'Fee Amount',
              hintText: 'e.g., 18.00',
              prefixText: '${currencyFormatter.currencySymbol} ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) return 'Invalid fee amount';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.feeDescriptionController,
            decoration: InputDecoration(
              labelText: 'Fee Description',
              hintText: 'e.g., Tax, Bank Fee',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              counterText: '',
            ),
            maxLength: 50,
          ),
        ],
      ],
    );
  }
}
