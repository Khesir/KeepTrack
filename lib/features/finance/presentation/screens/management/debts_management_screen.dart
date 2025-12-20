import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/features/finance/domain/entities/debt.dart';
import 'package:persona_codex/features/finance/presentation/state/debt_controller.dart';

class DebtsManagementScreen extends StatefulWidget {
  const DebtsManagementScreen({super.key});

  @override
  State<DebtsManagementScreen> createState() => _DebtsManagementScreenState();
}

class _DebtsManagementScreenState extends State<DebtsManagementScreen> {
  late final DebtController _controller;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<DebtController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCreateEditDialog({Debt? debt}) {
    final isEdit = debt != null;
    final personNameController = TextEditingController(
      text: debt?.personName ?? '',
    );
    final descriptionController = TextEditingController(
      text: debt?.description ?? '',
    );
    final originalAmountController = TextEditingController(
      text: debt?.originalAmount.toString() ?? '',
    );
    final remainingAmountController = TextEditingController(
      text:
          debt?.remainingAmount.toString() ??
          debt?.originalAmount.toString() ??
          '',
    );
    final notesController = TextEditingController(text: debt?.notes ?? '');
    DateTime selectedStartDate = debt?.startDate ?? DateTime.now();
    DateTime? selectedDueDate = debt?.dueDate;
    DebtType selectedType = debt?.type ?? DebtType.lending;
    DebtStatus selectedStatus = debt?.status ?? DebtStatus.active;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Debt' : 'Create Debt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debt Type',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<DebtType>(
                  segments: const [
                    ButtonSegment(
                      value: DebtType.lending,
                      label: Text('Lending'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: DebtType.borrowing,
                      label: Text('Borrowing'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (Set<DebtType> newSelection) {
                    setDialogState(() {
                      selectedType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: personNameController,
                  decoration: InputDecoration(
                    labelText: selectedType == DebtType.lending
                        ? 'Borrower Name'
                        : 'Lender Name',
                    border: const OutlineInputBorder(),
                    hintText: 'Name of the person',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'What is this debt for?',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: originalAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Original Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: remainingAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Remaining Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text(
                    '${selectedStartDate.year}-${selectedStartDate.month.toString().padLeft(2, '0')}-${selectedStartDate.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedStartDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() {
                          selectedStartDate = date;
                        });
                      }
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Date (Optional)'),
                  subtitle: Text(
                    selectedDueDate != null
                        ? '${selectedDueDate?.year}-${selectedDueDate?.month.toString().padLeft(2, '0')}-${selectedDueDate?.day.toString().padLeft(2, '0')}'
                        : 'No due date set',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedDueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setDialogState(() {
                              selectedDueDate = null;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (date != null) {
                            setDialogState(() {
                              selectedDueDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Debt Status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<DebtStatus>(
                  segments: const [
                    ButtonSegment(
                      value: DebtStatus.active,
                      label: Text('Active'),
                    ),
                    ButtonSegment(
                      value: DebtStatus.overdue,
                      label: Text('Overdue'),
                    ),
                    ButtonSegment(
                      value: DebtStatus.settled,
                      label: Text('Settled'),
                    ),
                  ],
                  selected: {selectedStatus},
                  onSelectionChanged: (Set<DebtStatus> newSelection) {
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
                if (personNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a person name')),
                  );
                  return;
                }
                if (originalAmountController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter the original amount'),
                    ),
                  );
                  return;
                }

                final originalAmount =
                    double.tryParse(originalAmountController.text) ?? 0;
                final remainingAmount =
                    double.tryParse(remainingAmountController.text) ??
                    originalAmount;

                final debtEntity = Debt(
                  id: debt?.id,
                  type: selectedType,
                  personName: personNameController.text.trim(),
                  description: descriptionController.text.trim(),
                  originalAmount: originalAmount,
                  remainingAmount: remainingAmount,
                  startDate: selectedStartDate,
                  dueDate: selectedDueDate,
                  status: selectedStatus,
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );

                if (isEdit) {
                  _controller.updateDebt(debtEntity);
                } else {
                  _controller.createDebt(debtEntity);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Debt updated' : 'Debt created'),
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

  void _deleteDebt(Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Debt'),
        content: Text(
          'Are you sure you want to delete the debt with "${debt.personName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _controller.deleteDebt(debt.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debt deleted')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Debts')),
      body: AsyncStreamBuilder<List<Debt>>(
        state: _controller,
        builder: (context, debts) {
          if (debts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No debts yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your lending and borrowing',
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
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];
              final isLending = debt.type == DebtType.lending;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isLending ? Colors.green : Colors.orange,
                    child: Icon(
                      isLending ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(debt.personName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.description),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: debt.progress / 100,
                        backgroundColor:
                            (isLending ? Colors.green : Colors.orange)
                                .withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLending ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${debt.paidAmount.toStringAsFixed(2)} paid of \$${debt.originalAmount.toStringAsFixed(2)} (${debt.progress.toStringAsFixed(1)}%)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (debt.dueDate != null)
                        Text(
                          'Due: ${debt.dueDate!.year}-${debt.dueDate!.month.toString().padLeft(2, '0')}-${debt.dueDate!.day.toString().padLeft(2, '0')}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: debt.isOverdue ? Colors.red : null,
                              ),
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
                        _showCreateEditDialog(debt: debt);
                      } else if (value == 'delete') {
                        _deleteDebt(debt);
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
                onPressed: () => _controller.loadDebts(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Debt'),
      ),
    );
  }
}
