import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../../modules/budget/domain/entities/budget.dart';
import '../../../modules/budget_profile/domain/entities/budget_profile.dart';
import '../../../modules/finance_category/domain/entities/finance_category.dart';
import '../../../modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../../modules/transaction/domain/entities/transaction.dart';
import '../../../modules/budget/presentation/controllers/budget_controller.dart';
import '../../state/budget_profile_controller.dart';
import '../../state/finance_category_controller.dart';
import '../../state/transaction_controller.dart';

class _CategoryGroup {
  final String name;
  final List<FinanceCategory> categories;
  const _CategoryGroup(this.name, this.categories);
}

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
  bool _showFeeFields = false;

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

  List<_CategoryGroup> _getGroupedCategories(
    List<FinanceCategory> allCategories,
  ) {
    final txnMonth = DateFormat('yyyy-MM').format(_selectedDate);

    final CategoryType targetType = _selectedType == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;

    // Exclude archived and non income/expense types; filter by profile if selected
    Set<String>? profileCategoryIds;
    if (_selectedProfileId != null) {
      final bs = _budgetController.state;
      if (bs is AsyncData<List<Budget>>) {
        profileCategoryIds = bs.data
            .where((b) => b.budgetProfileId == _selectedProfileId)
            .expand((b) => b.categories.map((c) => c.financeCategoryId))
            .toSet();
      }
    }

    final typedCategories = allCategories
        .where((c) => c.type == targetType && !c.isArchive)
        .where((c) => profileCategoryIds == null || (c.id != null && profileCategoryIds!.contains(c.id)))
        .toList();

    final budgetState = _budgetController.state;
    final allBudgets = budgetState is AsyncData<List<Budget>>
        ? budgetState.data
        : <Budget>[];

    final targetBudgetType = _selectedType == TransactionType.income
        ? BudgetType.income
        : BudgetType.expense;

    final monthBudgets = allBudgets
        .where(
          (b) =>
              b.month == txnMonth &&
              b.periodType == BudgetPeriodType.monthly &&
              b.status == BudgetStatus.active &&
              b.budgetType == targetBudgetType,
        )
        .toList();

    final groups = <_CategoryGroup>[];
    final seenIds = <String>{};

    for (final budget in monthBudgets) {
      final groupCats = <FinanceCategory>[];
      for (final bc in budget.categories) {
        final idx = typedCategories.indexWhere(
          (c) => c.id == bc.financeCategoryId,
        );
        final cat = idx != -1 ? typedCategories[idx] : null;
        if (cat != null && cat.id != null && !seenIds.contains(cat.id)) {
          groupCats.add(cat);
          seenIds.add(cat.id!);
        }
      }
      if (groupCats.isNotEmpty) {
        groups.add(_CategoryGroup(budget.title ?? 'Untitled', groupCats));
      }
    }

    if (monthBudgets.isNotEmpty) {
      final others = typedCategories
          .where((c) => c.id != null && !seenIds.contains(c.id))
          .toList();
      if (others.isNotEmpty) {
        groups.add(_CategoryGroup('Other', others));
      }
    }

    return groups;
  }

  void _showCategoryDialog(List<FinanceCategory> allCategories) {
    final groups = _getGroupedCategories(allCategories);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (groups.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
            maxWidth: 420,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Select Category',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final group in groups) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: Text(
                            group.name.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        for (final cat in group.categories)
                          ListTile(
                            leading: Icon(
                              cat.type.icon,
                              size: 20,
                              color: cat.type.color,
                            ),
                            title: Text(cat.name),
                            selected: _selectedCategoryId == cat.id,
                            selectedTileColor: colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            trailing: _selectedCategoryId == cat.id
                                ? Icon(
                                    Icons.check,
                                    size: 18,
                                    color: colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = cat.id;
                                _selectedCategory = cat;
                              });
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a budget profile')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final feeAmount = _feeController.text.trim().isEmpty
          ? 0.0
          : double.parse(_feeController.text);

      final transaction = Transaction(
        financeCategoryId: _selectedCategoryId,
        amount: double.parse(_amountController.text),
        type: _selectedType,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        fee: feeAmount,
        feeDescription: _feeDescriptionController.text.trim().isEmpty
            ? null
            : _feeDescriptionController.text.trim(),
        budgetId: _selectedBudgetId,
      );

      await _transactionController.createTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction created successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

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
            _buildHeader(colorScheme, theme),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  _buildProfileSelector(colorScheme),
                  const SizedBox(height: 12),
                  if (_selectedProfileId != null) ...[
                    _buildCategorySelector(colorScheme, theme),
                    const SizedBox(height: 12),
                  ],
                  _buildDateRow(theme, colorScheme),
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
                  _buildFeeSection(colorScheme, theme),
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

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
    final typeColor = _selectedType == TransactionType.income
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
            selected: {_selectedType},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedType = selection.first;
                _selectedCategoryId = null;
                _selectedCategory = null;
              });
            },
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
                  controller: _amountController,
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

  Widget _buildCategorySelector(ColorScheme colorScheme, ThemeData theme) {
    return AsyncStreamBuilder<List<FinanceCategory>>(
      state: _categoryController,
      loadingBuilder: (context) => const LinearProgressIndicator(),
      errorBuilder: (context, message) => Text(
        'Error loading categories: $message',
        style: TextStyle(color: colorScheme.error),
      ),
      builder: (context, categories) {
        final CategoryType targetType = _selectedType == TransactionType.income
            ? CategoryType.income
            : CategoryType.expense;

        final typedCategories = categories
            .where((c) => c.type == targetType)
            .toList();

        if (typedCategories.isEmpty) {
          return Text(
            'No ${_selectedType.displayName.toLowerCase()} categories found.',
            style: TextStyle(color: colorScheme.error),
          );
        }

        if (_selectedCategory != null &&
            _selectedCategory!.type != targetType) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedCategory = null;
                _selectedCategoryId = null;
              });
            }
          });
        }

        final hasSelection = _selectedCategory != null;

        return FormField<String>(
          initialValue: _selectedCategoryId,
          validator: (_) =>
              _selectedCategoryId == null ? 'Please select a category' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _showCategoryDialog(categories),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    errorText: field.errorText,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (hasSelection) ...[
                        Icon(
                          _selectedCategory!.type.icon,
                          size: 18,
                          color: _selectedCategory!.type.color,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          hasSelection
                              ? _selectedCategory!.name
                              : 'Select a category',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: hasSelection
                                ? null
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.unfold_more,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRow(ThemeData theme, ColorScheme colorScheme) {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEE, MMM d y  •  h:mm a').format(_selectedDate),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeSection(ColorScheme colorScheme, ThemeData theme) {
    final hasFee = _feeController.text.isNotEmpty;
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
                        ? 'Fee: ${currencyFormatter.currencySymbol}${_feeController.text}'
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
            controller: _feeController,
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
            controller: _feeDescriptionController,
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
