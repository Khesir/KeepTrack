import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';

class DebtManagementDialog extends StatefulWidget {
  final Debt? debt;
  final String userId;
  final List<Account> accounts;

  final Function(Debt, String?) onSave;

  const DebtManagementDialog({
    this.debt,
    required this.userId,
    required this.accounts,
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
  late final TextEditingController monthlyPaymentController;
  late final TextEditingController feeAmountController;
  late final FinanceCategoryController _categoryController;

  late DateTime selectedStartDate;
  late DateTime? selectedDueDate;
  late DateTime? selectedNextPaymentDate;
  late DebtType selectedType;
  late DebtStatus selectedStatus;
  late PaymentFrequency selectedPaymentFrequency;
  String? selectedAccountId;
  String? selectedCategoryId;

  bool _isSaving = false;
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
    monthlyPaymentController = TextEditingController(
      text: d?.monthlyPaymentAmount != null && d!.monthlyPaymentAmount > 0
          ? d.monthlyPaymentAmount.toString()
          : '',
    );
    feeAmountController = TextEditingController(
      text: d?.feeAmount != null && d!.feeAmount > 0
          ? d.feeAmount.toString()
          : '',
    );

    selectedStartDate = d?.startDate ?? DateTime.now();
    selectedDueDate = d?.dueDate;
    selectedNextPaymentDate = d?.nextPaymentDate;
    selectedType = d?.type ?? DebtType.lending;
    selectedStatus = d?.status ?? DebtStatus.active;
    selectedPaymentFrequency = d?.paymentFrequency ?? PaymentFrequency.monthly;
    selectedAccountId = d?.accountId ?? widget.accounts.firstOrNull?.id;

    _categoryController = locator.get<FinanceCategoryController>();
    _categoryController.loadCategories();
  }

  @override
  void dispose() {
    personNameController.dispose();
    descriptionController.dispose();
    originalAmountController.dispose();
    remainingAmountController.dispose();
    notesController.dispose();
    monthlyPaymentController.dispose();
    feeAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveDebt() async {
    if (_isSaving) return; // Prevent double-submit

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
    if (selectedAccountId == null && !isEdit) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an account')));
      return;
    }
    if (selectedCategoryId == null && !isEdit) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final originalAmount =
          double.tryParse(originalAmountController.text) ?? 0;
      final remainingAmount =
          double.tryParse(remainingAmountController.text) ?? originalAmount;
      final monthlyPayment =
          double.tryParse(monthlyPaymentController.text) ?? 0;
      final feeAmount = double.tryParse(feeAmountController.text) ?? 0;

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
        accountId: selectedAccountId,
        transactionId: widget.debt?.transactionId,
        monthlyPaymentAmount: monthlyPayment,
        feeAmount: feeAmount,
        nextPaymentDate: selectedNextPaymentDate,
        paymentFrequency: selectedPaymentFrequency,
      );

      widget.onSave(debtEntity, selectedCategoryId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Debt updated' : 'Debt created')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get currency symbol from settings
    final currencySymbol = currencyFormatter.currencySymbol;

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
                    // Reset category selection when type changes
                    selectedCategoryId = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (widget.accounts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'No accounts available. Please create an account first.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Account/Wallet',
                    border: OutlineInputBorder(),
                    hintText: 'Select an account',
                  ),
                  items: widget.accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(account.name),
                              const SizedBox(width: 8),
                              Text(
                                '(\$${account.balance.toStringAsFixed(2)})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: isEdit
                      ? null
                      : (value) {
                          setDialogState(() {
                            selectedAccountId = value;
                          });
                        },
                ),
              const SizedBox(height: 16),
              // Category Selector (only for new debts)
              if (!isEdit)
                AsyncStreamBuilder<List<FinanceCategory>>(
                  state: _categoryController,
                  builder: (context, categories) {
                    // Filter categories based on debt type
                    final categoryType = selectedType == DebtType.lending
                        ? CategoryType
                              .expense // Lending = money out
                        : CategoryType.income; // Borrowing = money in

                    final filteredCategories = categories
                        .where((c) => c.type == categoryType)
                        .toList();

                    return DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: const OutlineInputBorder(),
                        hintText: 'Select a category',
                        helperText: selectedType == DebtType.lending
                            ? 'Expense category for money lent out'
                            : 'Income category for money borrowed',
                      ),
                      items: filteredCategories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Row(
                                children: [
                                  Icon(
                                    category.type.icon,
                                    size: 16,
                                    color: category.type.color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategoryId = value;
                        });
                      },
                    );
                  },
                  loadingBuilder: (_) => const CircularProgressIndicator(),
                  errorBuilder: (context, message) => Text(
                    'Error loading categories: $message',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (!isEdit) const SizedBox(height: 16),
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
                decoration: InputDecoration(
                  labelText: 'Original Amount',
                  border: const OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feeAmountController,
                decoration: InputDecoration(
                  labelText: 'Fee Amount (Optional)',
                  border: const OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                  helperText: 'Total fees associated with this debt',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: monthlyPaymentController,
                decoration: InputDecoration(
                  labelText: 'Payment Amount (Optional)',
                  border: const OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                  helperText: 'Fixed amount due each payment period',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Frequency',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<PaymentFrequency>(
                segments: PaymentFrequency.values
                    .map(
                      (freq) => ButtonSegment(
                        value: freq,
                        label: Text(freq.displayName),
                      ),
                    )
                    .toList(),
                selected: {selectedPaymentFrequency},
                onSelectionChanged: (Set<PaymentFrequency> newSelection) {
                  setDialogState(() {
                    selectedPaymentFrequency = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Next Payment Date (Optional)'),
                subtitle: Text(
                  selectedNextPaymentDate != null
                      ? '${selectedNextPaymentDate?.year}-${selectedNextPaymentDate?.month.toString().padLeft(2, '0')}-${selectedNextPaymentDate?.day.toString().padLeft(2, '0')}'
                      : 'No next payment date set',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedNextPaymentDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setDialogState(() {
                            selectedNextPaymentDate = null;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedNextPaymentDate ?? DateTime.now(),
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
                  ],
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
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _saveDebt,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
