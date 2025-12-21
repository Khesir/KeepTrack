import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:persona_codex/features/finance/presentation/state/planned_payment_controller.dart';

class PlannedPaymentsManagementScreen extends StatefulWidget {
  const PlannedPaymentsManagementScreen({super.key});

  @override
  State<PlannedPaymentsManagementScreen> createState() =>
      _PlannedPaymentsManagementScreenState();
}

class _PlannedPaymentsManagementScreenState
    extends State<PlannedPaymentsManagementScreen> {
  late final PlannedPaymentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<PlannedPaymentController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCreateEditDialog({PlannedPayment? payment}) {
    final isEdit = payment != null;
    final nameController = TextEditingController(text: payment?.name ?? '');
    final payeeController = TextEditingController(text: payment?.payee ?? '');
    final amountController = TextEditingController(
      text: payment?.amount.toString() ?? '',
    );
    final notesController = TextEditingController(text: payment?.notes ?? '');
    DateTime selectedNextPaymentDate =
        payment?.nextPaymentDate ?? DateTime.now();
    PaymentCategory selectedCategory =
        payment?.category ?? PaymentCategory.bills;
    PaymentFrequency selectedFrequency =
        payment?.frequency ?? PaymentFrequency.monthly;
    PaymentStatus selectedStatus = payment?.status ?? PaymentStatus.active;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Planned Payment' : 'Create Planned Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Name',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Netflix, Electric Bill',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: payeeController,
                  decoration: const InputDecoration(
                    labelText: 'Payee',
                    border: OutlineInputBorder(),
                    hintText: 'Who gets paid?',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<PaymentCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_getCategoryLabel(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Frequency',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<PaymentFrequency>(
                  value: selectedFrequency,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentFrequency.values.map((frequency) {
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(_getFrequencyLabel(frequency)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedFrequency = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Next Payment Date'),
                  subtitle: Text(
                    '${selectedNextPaymentDate.year}-${selectedNextPaymentDate.month.toString().padLeft(2, '0')}-${selectedNextPaymentDate.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedNextPaymentDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (date != null) {
                        setDialogState(() {
                          selectedNextPaymentDate = date;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Payment Status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<PaymentStatus>(
                  segments: const [
                    ButtonSegment(
                      value: PaymentStatus.active,
                      label: Text('Active'),
                      icon: Icon(Icons.play_arrow),
                    ),
                    ButtonSegment(
                      value: PaymentStatus.paused,
                      label: Text('Paused'),
                      icon: Icon(Icons.pause),
                    ),
                    ButtonSegment(
                      value: PaymentStatus.cancelled,
                      label: Text('Cancelled'),
                      icon: Icon(Icons.cancel),
                    ),
                  ],
                  selected: {selectedStatus},
                  onSelectionChanged: (Set<PaymentStatus> newSelection) {
                    setDialogState(() {
                      selectedStatus = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Additional information',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a payment name')),
                  );
                  return;
                }
                if (payeeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a payee')),
                  );
                  return;
                }
                if (amountController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an amount'),
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text) ?? 0;

                final paymentEntity = PlannedPayment(
                  id: payment?.id,
                  name: nameController.text.trim(),
                  payee: payeeController.text.trim(),
                  amount: amount,
                  category: selectedCategory,
                  frequency: selectedFrequency,
                  nextPaymentDate: selectedNextPaymentDate,
                  status: selectedStatus,
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );

                if (isEdit) {
                  _controller.updatePlannedPayment(paymentEntity);
                } else {
                  _controller.createPlannedPayment(paymentEntity);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit ? 'Payment updated' : 'Payment created',
                    ),
                  ),
                );
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePayment(PlannedPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Planned Payment'),
        content: Text('Are you sure you want to delete "${payment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _controller.deletePlannedPayment(payment.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment deleted')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(PaymentCategory category) {
    return switch (category) {
      PaymentCategory.bills => 'Bills',
      PaymentCategory.subscriptions => 'Subscriptions',
      PaymentCategory.insurance => 'Insurance',
      PaymentCategory.loan => 'Loan',
      PaymentCategory.rent => 'Rent',
      PaymentCategory.utilities => 'Utilities',
      PaymentCategory.other => 'Other',
    };
  }

  String _getFrequencyLabel(PaymentFrequency frequency) {
    return switch (frequency) {
      PaymentFrequency.daily => 'Daily',
      PaymentFrequency.weekly => 'Weekly',
      PaymentFrequency.biweekly => 'Bi-weekly',
      PaymentFrequency.monthly => 'Monthly',
      PaymentFrequency.quarterly => 'Quarterly',
      PaymentFrequency.yearly => 'Yearly',
    };
  }

  IconData _getCategoryIcon(PaymentCategory category) {
    return switch (category) {
      PaymentCategory.bills => Icons.receipt_long,
      PaymentCategory.subscriptions => Icons.subscriptions,
      PaymentCategory.insurance => Icons.shield,
      PaymentCategory.loan => Icons.account_balance,
      PaymentCategory.rent => Icons.home,
      PaymentCategory.utilities => Icons.flash_on,
      PaymentCategory.other => Icons.more_horiz,
    };
  }

  Color _getCategoryColor(PaymentCategory category) {
    return switch (category) {
      PaymentCategory.bills => Colors.blue,
      PaymentCategory.subscriptions => Colors.purple,
      PaymentCategory.insurance => Colors.green,
      PaymentCategory.loan => Colors.orange,
      PaymentCategory.rent => Colors.teal,
      PaymentCategory.utilities => Colors.amber,
      PaymentCategory.other => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Planned Payments')),
      body: AsyncStreamBuilder<List<PlannedPayment>>(
        state: _controller,
        builder: (context, payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_repeat_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No planned payments yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up recurring and scheduled payments',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              final categoryColor = _getCategoryColor(payment.category);
              final categoryIcon = _getCategoryIcon(payment.category);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: categoryColor,
                    child: Icon(categoryIcon, color: Colors.white),
                  ),
                  title: Text(payment.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${payment.payee} • ${_getFrequencyLabel(payment.frequency)}'),
                      const SizedBox(height: 4),
                      Text(
                        '\$${payment.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            payment.isUpcoming
                                ? Icons.warning_amber
                                : Icons.schedule,
                            size: 14,
                            color: payment.isUpcoming
                                ? Colors.orange
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Next: ${payment.nextPaymentDate.year}-${payment.nextPaymentDate.month.toString().padLeft(2, '0')}-${payment.nextPaymentDate.day.toString().padLeft(2, '0')}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: payment.isUpcoming
                                          ? Colors.orange
                                          : null,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showCreateEditDialog(payment: payment);
                      } else if (value == 'delete') {
                        _deletePayment(payment);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.loadPlannedPayments(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Payment'),
      ),
    );
  }
}
