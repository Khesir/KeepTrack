import 'package:flutter/material.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../../modules/budget/domain/entities/budget.dart';
import '../../../modules/budget_profile/domain/entities/budget_profile.dart';
import '../../../modules/finance_category/domain/entities/finance_category.dart';
import '../../../modules/transaction/domain/entities/transaction.dart';
import '../../../modules/budget/presentation/controllers/budget_controller.dart';
import '../../state/budget_profile_controller.dart';
import '../../state/finance_category_controller.dart';
import '../../state/transaction_controller.dart';
import '../../widgets/category_selector_field.dart';
import '../../widgets/transaction_amount_header.dart';
import '../../widgets/transaction_date_row.dart';
import '../../widgets/transaction_fee_section.dart';

class CreateTransactionScreen extends StatefulWidget {
  final String? initialDescription;
  final double? initialAmount;
  final String? initialCategoryId;
  final TransactionType? initialType;

  const CreateTransactionScreen({
    super.key,
    this.initialDescription,
    this.initialAmount,
    this.initialCategoryId,
    this.initialType,
  });

  @override
  State<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  late final TransactionController _transactionController;
  late final FinanceCategoryController _categoryController;
  late final BudgetController _budgetController;
  late final BudgetProfileController _profileController;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _feeDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;

  String? _selectedCategoryId;
  FinanceCategory? _selectedCategory;
  String? _selectedBudgetId;
  String? _selectedProfileId;

  DateTime _selectedDate = DateTime.now();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _transactionController = locator.get<TransactionController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _budgetController = locator.get<BudgetController>();
    _profileController = locator.get<BudgetProfileController>();

    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    if (widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId;
    }
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }

    _categoryController.loadCategories();
    _budgetController.loadBudgets();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _feeDescriptionController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<Budget> _getOnetimeBudgets() {
    final budgets = _budgetController.state is AsyncData<List<Budget>>
        ? (_budgetController.state as AsyncData<List<Budget>>).data
        : <Budget>[];
    return budgets
        .where(
          (b) =>
              b.status == BudgetStatus.active &&
              b.periodType == BudgetPeriodType.oneTime,
        )
        .toList();
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _selectedDate.hour,
            _selectedDate.minute,
          );
        });
      }
    }
  }

  Future<void> _createTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProfileId == null) {
      AppToast.show(context, 'Please select a budget profile');
      return;
    }

    if (_selectedCategoryId == null) {
      AppToast.show(context, 'Please select a category');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final feeAmount = _feeController.text.trim().isEmpty
          ? 0.0
          : double.parse(_feeController.text);

      final desc = _descriptionController.text.trim();
      final autoDesc = _selectedType == TransactionType.income
          ? 'Earns ${_selectedCategory?.name ?? ''}'
          : 'Pays ${_selectedCategory?.name ?? ''}';
      final transaction = Transaction(
        financeCategoryId: _selectedCategoryId,
        amount: double.parse(_amountController.text),
        type: _selectedType,
        description: desc.isEmpty ? autoDesc.trim() : desc,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        fee: feeAmount,
        feeDescription: _feeDescriptionController.text.trim().isEmpty
            ? null
            : _feeDescriptionController.text.trim(),
        budgetId: _selectedBudgetId,
        budgetProfileId: _selectedProfileId,
      );

      await _transactionController.createTransaction(transaction);

      if (mounted) {
        AppToast.success(context, 'Transaction created successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to create: $e');
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TransactionAmountHeader(
              selectedType: _selectedType,
              amountController: _amountController,
              onTypeChanged: (type) => setState(() {
                _selectedType = type;
                _selectedCategoryId = null;
                _selectedCategory = null;
              }),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  _buildProfileSelector(colorScheme),
                  const SizedBox(height: 12),
                  if (_selectedProfileId != null) ...[
                    CategorySelectorField(
                      categoryController: _categoryController,
                      budgetController: _budgetController,
                      selectedType: _selectedType,
                      selectedDate: _selectedDate,
                      selectedProfileId: _selectedProfileId,
                      selectedCategoryId: _selectedCategoryId,
                      selectedCategory: _selectedCategory,
                      onSelect: (cat) => setState(() {
                        _selectedCategoryId = cat.id;
                        _selectedCategory = cat;
                      }),
                      onTypeMismatch: () {
                        if (mounted) {
                          setState(() {
                            _selectedCategory = null;
                            _selectedCategoryId = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TransactionDateRow(
                    selectedDate: _selectedDate,
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      counterText: '',
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 12),
                  TransactionFeeSection(
                    feeController: _feeController,
                    feeDescriptionController: _feeDescriptionController,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      counterText: '',
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 12),
                  _buildBudgetSelector(colorScheme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SafeArea(
                top: false,
                child: FilledButton.icon(
                  onPressed: _isCreating ? null : _createTransaction,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isCreating ? 'Creating...' : 'Create Transaction',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSelector(ColorScheme colorScheme) {
    final s = _profileController.state;
    final profiles = s is AsyncData<List<BudgetProfile>> ? s.data : <BudgetProfile>[];

    final selectedName = profiles.where((p) => p.id == _selectedProfileId).firstOrNull?.name;

    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text('Select Budget'),
          children: profiles.map((p) => SimpleDialogOption(
            onPressed: () { setState(() { _selectedProfileId = p.id; _selectedCategory = null; _selectedCategoryId = null; }); Navigator.pop(context); },
            child: Row(children: [
              Text(p.name),
              if (_selectedProfileId == p.id) ...[const Spacer(), const Icon(Icons.check_rounded, size: 16)],
            ]),
          )).toList(),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Budget *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          suffixIcon: const Icon(Icons.unfold_more_rounded, size: 18),
        ),
        child: Text(selectedName ?? 'Select a budget',
            style: TextStyle(color: selectedName != null ? colorScheme.primary : colorScheme.onSurfaceVariant)),
      ),
    );
  }

  Widget _buildBudgetSelector(ColorScheme colorScheme) {
    return AsyncStreamBuilder<List<Budget>>(
      state: _budgetController,
      loadingBuilder: (context) => const SizedBox.shrink(),
      errorBuilder: (context, message) => const SizedBox.shrink(),
      builder: (context, budgets) {
        final onetimeBudgets = _getOnetimeBudgets();
        if (onetimeBudgets.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedBudgetId,
            decoration: InputDecoration(
              labelText: 'Budget (Optional)',
              hintText: 'Assign to a one-time budget',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('None')),
              ...onetimeBudgets.map((budget) {
                final title = budget.title ?? 'Untitled';
                final parts = budget.month.split('-');
                final monthDate = DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                );
                final monthStr = DateFormat('MMM y').format(monthDate);
                return DropdownMenuItem(
                  value: budget.id,
                  child: Text('$title  •  $monthStr'),
                );
              }),
            ],
            onChanged: (value) => setState(() => _selectedBudgetId = value),
          ),
        );
      },
    );
  }
}
