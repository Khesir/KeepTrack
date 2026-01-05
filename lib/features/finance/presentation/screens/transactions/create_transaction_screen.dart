import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../../modules/account/domain/entities/account.dart';
import '../../../modules/budget/domain/entities/budget.dart';
import '../../../modules/finance_category/domain/entities/finance_category.dart';
import '../../../modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../../modules/transaction/domain/entities/transaction.dart';
import '../../state/account_controller.dart';
import '../../state/budget_controller.dart';
import '../../state/finance_category_controller.dart';
import '../../state/transaction_controller.dart';

/// Screen for creating a new transaction
class CreateTransactionScreen extends StatefulWidget {
  final String? initialDescription;
  final double? initialAmount;
  final String? initialCategoryId;
  final String? initialAccountId;
  final TransactionType? initialType;

  const CreateTransactionScreen({
    super.key,
    this.initialDescription,
    this.initialAmount,
    this.initialCategoryId,
    this.initialAccountId,
    this.initialType,
  });

  @override
  State<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  late final TransactionController _transactionController;
  late final AccountController _accountController;
  late final FinanceCategoryController _categoryController;
  late final BudgetController _budgetController;
  late final SupabaseService supabaseService;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _feeDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedBudgetId; // For manually assigning to one-time budgets only
  DateTime _selectedDate = DateTime.now();
  bool _isCreating = false;
  bool _showFeeFields = false;

  @override
  void initState() {
    super.initState();
    _transactionController = locator.get<TransactionController>();
    _accountController = locator.get<AccountController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _budgetController = locator.get<BudgetController>();
    supabaseService = locator.get<SupabaseService>();

    // Initialize with provided values
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    if (widget.initialAccountId != null) {
      _selectedAccountId = widget.initialAccountId;
    }
    if (widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId;
    }
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }

    // Load accounts, categories, and budgets
    _accountController.loadAccounts();
    _categoryController.loadCategories();
    _budgetController.loadBudgets();
  }

  /// Get list of active one-time budgets for manual selection
  /// Monthly budgets should NOT be manually assigned - they auto-calculate
  List<Budget> _getOnetimeBudgets() {
    final budgets = _budgetController.state is AsyncData<List<Budget>>
        ? (_budgetController.state as AsyncData<List<Budget>>).data
        : <Budget>[];

    return budgets
        .where((b) =>
          b.status == BudgetStatus.active &&
          b.periodType == BudgetPeriodType.oneTime
        )
        .toList();
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

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      // Now select time
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
        // User cancelled time picker, use picked date with current time
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if account is selected (required)
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an account')));
      return;
    }

    // Check if category is selected (required)
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Parse fee amount (default to 0 if empty)
      final feeAmount = _feeController.text.trim().isEmpty
          ? 0.0
          : double.parse(_feeController.text);

      // Only assign budget_id for one-time budgets (manual selection)
      // Monthly budgets should have budget_id = null so they auto-calculate
      final budgetId = _selectedBudgetId; // Only set if one-time budget selected

      final transaction = Transaction(
        accountId: _selectedAccountId,
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
        budgetId: budgetId, // Only for one-time budgets, null for monthly
        userId: supabaseService.userId,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create transaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Transaction'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Transaction Type Selector
            _buildTransactionTypeSelector(colorScheme),
            const SizedBox(height: 24),

            // Amount Field
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₱',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fee Section (Optional - Expandable)
            _buildFeeSection(colorScheme),
            const SizedBox(height: 16),

            // Account Selector
            AsyncStreamBuilder<List<Account>>(
              state: _accountController,
              loadingBuilder: (context) => const LinearProgressIndicator(),
              errorBuilder: (context, message) => Card(
                color: Colors.red.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading accounts: $message',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              builder: (context, accounts) {
                if (accounts.isEmpty) {
                  return Card(
                    color: Colors.orange.withValues(alpha: 0.1),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No accounts found. Please create an account first.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: InputDecoration(
                    labelText: 'Account',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  items: accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an account';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Category Selector
            AsyncStreamBuilder<List<FinanceCategory>>(
              state: _categoryController,
              loadingBuilder: (context) => const LinearProgressIndicator(),
              errorBuilder: (context, message) => Card(
                color: Colors.red.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading categories: $message',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              builder: (context, categories) {
                // Filter categories based on transaction type
                final CategoryType targetCategoryType;
                switch (_selectedType) {
                  case TransactionType.income:
                    targetCategoryType = CategoryType.income;
                    break;
                  case TransactionType.expense:
                    targetCategoryType = CategoryType.expense;
                    break;
                  case TransactionType.transfer:
                    targetCategoryType = CategoryType.transfer;
                    break;
                }

                final filteredCategories = categories
                    .where((c) => c.type == targetCategoryType)
                    .toList();

                if (filteredCategories.isEmpty) {
                  return Card(
                    color: Colors.orange.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No ${_selectedType.displayName.toLowerCase()} categories found.',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value:
                      _selectedCategoryId != null &&
                          filteredCategories.any(
                            (c) => c.id == _selectedCategoryId,
                          )
                      ? _selectedCategoryId
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
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
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // One-Time Budget Selector (Optional)
            AsyncStreamBuilder<List<Budget>>(
              state: _budgetController,
              loadingBuilder: (context) => const SizedBox.shrink(),
              errorBuilder: (context, message) => const SizedBox.shrink(),
              builder: (context, budgets) {
                final onetimeBudgets = _getOnetimeBudgets();

                // Only show if there are one-time budgets available
                if (onetimeBudgets.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    // Info card explaining budget assignment
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Budget Assignment: Monthly budgets automatically track unassigned transactions. '
                              'Only assign to one-time budgets for specific expenses like vacations or events.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedBudgetId,
                      decoration: InputDecoration(
                        labelText: 'Budget (Optional - One-Time Only)',
                        hintText: 'Assign to a one-time budget',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        helperText: 'Only one-time budgets shown. Monthly budgets auto-calculate.',
                        helperMaxLines: 2,
                      ),
                      items: [
                        // Add "None" option to clear selection
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None (Monthly budget will auto-calculate)'),
                        ),
                        ...onetimeBudgets.map(
                          (budget) {
                            final title = budget.title ?? 'Untitled';
                            // Parse month string (format: "2024-12") to DateTime for formatting
                            final parts = budget.month.split('-');
                            final monthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                            final monthStr = DateFormat('MMM y').format(monthDate);
                            return DropdownMenuItem(
                              value: budget.id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '$monthStr • ${budget.budgetType.displayName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedBudgetId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Date & Time Selector
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date & Time',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d, y • h:mm a').format(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Notes Field
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 24),

            // Create Button
            FilledButton.icon(
              onPressed: _isCreating ? null : _createTransaction,
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isCreating ? 'Creating...' : 'Create Transaction'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Type',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                type: TransactionType.income,
                icon: Icons.arrow_downward,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                type: TransactionType.expense,
                icon: Icons.arrow_upward,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                type: TransactionType.transfer,
                icon: Icons.swap_horiz,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required TransactionType type,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        // Redirect to transfer screen if transfer type is selected
        if (type == TransactionType.transfer) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.transferCreate,
          );
          return;
        }

        setState(() {
          _selectedType = type;
          // Reset category when type changes
          _selectedCategoryId = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
            const SizedBox(height: 4),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeSection(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header with expand/collapse button
          InkWell(
            onTap: () {
              setState(() {
                _showFeeFields = !_showFeeFields;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fees & Charges (Optional)',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (!_showFeeFields && _feeController.text.isNotEmpty)
                          Text(
                            '₱${_feeController.text} fee added',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                          )
                        else if (!_showFeeFields)
                          Text(
                            'Tap to add tax, service charge, or transfer fee',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _showFeeFields ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Expandable fee fields
          if (_showFeeFields) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fee Amount Field
                  TextFormField(
                    controller: _feeController,
                    decoration: InputDecoration(
                      labelText: 'Fee Amount',
                      hintText: 'e.g., 154 for tax, 18 for transfer fee',
                      prefixText: '₱',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
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
                      if (value != null && value.isNotEmpty) {
                        final amount = double.tryParse(value);
                        if (amount == null || amount < 0) {
                          return 'Please enter a valid fee amount';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Fee Description Field
                  TextFormField(
                    controller: _feeDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Fee Description (Optional)',
                      hintText: 'e.g., Tax, Service Charge, Transfer Fee',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                    maxLength: 50,
                  ),

                  // Helper text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getFeeHelperText(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
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
        ],
      ),
    );
  }

  String _getFeeHelperText() {
    switch (_selectedType) {
      case TransactionType.expense:
        return 'For expenses: fees are added to the total cost (e.g., 2000 + 154 tax = 2154 total)';
      case TransactionType.income:
        return 'For income: fees are deducted from amount received (e.g., 5000 - 250 commission = 4750 received)';
      case TransactionType.transfer:
        return 'For transfers: source account pays amount + fee, destination receives amount only';
    }
  }
}
