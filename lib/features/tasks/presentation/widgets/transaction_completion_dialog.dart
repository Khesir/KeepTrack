import 'package:flutter/material.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';

class TransactionCompletionDialog extends StatefulWidget {
  final Task task;
  final Function(double actualAmount, bool createTransaction) onConfirm;

  const TransactionCompletionDialog({
    super.key,
    required this.task,
    required this.onConfirm,
  });

  @override
  State<TransactionCompletionDialog> createState() =>
      _TransactionCompletionDialogState();
}

class _TransactionCompletionDialogState
    extends State<TransactionCompletionDialog> {
  late TextEditingController _actualAmountController;
  bool _createTransaction = true;

  @override
  void initState() {
    super.initState();
    _actualAmountController = TextEditingController(
      text: widget.task.expectedAmount?.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _actualAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expectedAmount = widget.task.expectedAmount ?? 0;
    final transactionType = widget.task.transactionType;
    final isIncome = transactionType == TaskTransactionType.income;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Complete Transaction'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 14,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transactionType?.displayName ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          color: isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Expected amount (read-only)
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Expected Amount',
                border: const OutlineInputBorder(),
                prefixText: '₱ ',
                suffixIcon: Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                ),
              ),
              controller: TextEditingController(
                text: expectedAmount.toStringAsFixed(2),
              ),
            ),
            const SizedBox(height: 16),

            // Actual amount (editable)
            TextField(
              controller: _actualAmountController,
              decoration: InputDecoration(
                labelText: 'Actual Amount',
                border: const OutlineInputBorder(),
                prefixText: '₱ ',
                helperText: 'Adjust if the actual amount differs from expected',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.edit),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Create transaction toggle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Create Transaction Record',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Add this to your finance records',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _createTransaction,
                    onChanged: (value) {
                      setState(() => _createTransaction = value);
                    },
                  ),
                  if (!_createTransaction)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 16,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'The transaction won\'t be tracked in your finances',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            final actualAmount = double.tryParse(_actualAmountController.text);
            if (actualAmount == null || actualAmount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid positive amount'),
                ),
              );
              return;
            }

            Navigator.pop(context);
            widget.onConfirm(actualAmount, _createTransaction);
          },
          icon: const Icon(Icons.check),
          label: const Text('Complete'),
        ),
      ],
    );
  }
}
