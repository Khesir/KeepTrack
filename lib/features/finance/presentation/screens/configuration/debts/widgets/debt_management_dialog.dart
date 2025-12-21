import 'package:flutter/material.dart';
import 'package:persona_codex/features/finance/modules/debt/domain/entities/debt.dart';

class DebtManagementDialog extends StatefulWidget {
  final Debt? debt;
  final String userId;

  final Function(Debt) onSave;

  const DebtManagementDialog({
    this.debt,
    required this.userId,
    required this.onSave,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _DebtManagementDialogState();
}

class _DebtManagementDialogState extends State<DebtManagementDialog> {
  late final TextEditingController personNameController;
  late final TextEditingController descriptionController;
  late final TextEditingController originalAmountController;
  late final TextEditingController remainingAmountController;
  late final TextEditingController notesController;

  late DateTime selectedStartDate;
  late DateTime? selectedDueDate;
  late DebtType selectedType;
  late DebtStatus selectedStatus;

  bool get isEdit => widget.debt != null;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;

    personNameController = TextEditingController(text: d?.personName ?? '');
    descriptionController = TextEditingController(text: d?.description ?? '');
    originalAmountController = TextEditingController(
      text: d?.originalAmount.toString() ?? '',
    );
    remainingAmountController = TextEditingController(
      text: d?.remainingAmount.toString() ?? d?.originalAmount.toString() ?? '',
    );
    notesController = TextEditingController(text: d?.notes ?? '');

    selectedStartDate = d?.startDate ?? DateTime.now();
    selectedDueDate = d?.dueDate;
    selectedType = d?.type ?? DebtType.lending;
    selectedStatus = d?.status ?? DebtStatus.active;
  }

  @override
  void dispose() {
    personNameController.dispose();
    descriptionController.dispose();
    originalAmountController.dispose();
    remainingAmountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _saveDebt() {
    if (personNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a person name')),
      );
      return;
    }
    if (originalAmountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the original amount')),
      );
      return;
    }

    final originalAmount = double.tryParse(originalAmountController.text) ?? 0;
    final remainingAmount =
        double.tryParse(remainingAmountController.text) ?? originalAmount;

    final debtEntity = Debt(
      id: widget.debt?.id,
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
      userId: widget.userId,
    );

    widget.onSave(debtEntity);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEdit ? 'Debt updated' : 'Debt created')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
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
            onPressed: _saveDebt,
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
