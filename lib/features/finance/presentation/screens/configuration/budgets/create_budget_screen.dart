import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import 'package:persona_codex/features/finance/modules/account/domain/entities/account.dart';
import 'package:persona_codex/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';
import '../../../../../../core/routing/app_router.dart';
import '../../../../modules/budget/domain/entities/budget.dart';
import '../../../../modules/budget/domain/entities/budget_category.dart';
import '../../../../modules/finance_category/domain/entities/finance_category.dart';
import '../../../state/account_controller.dart';
import '../../../state/budget_controller.dart';
import '../../../state/finance_category_controller.dart';

class CreateBudgetScreen extends StatefulWidget {
  const CreateBudgetScreen({super.key});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  late final BudgetController _controller;
  late final FinanceCategoryController _financeCategoryController;
  late final SupabaseService _supabaseService;
  late final AccountController _accountController;
  final _formKey = GlobalKey<FormState>();
  final List<BudgetCategory> _categories = [];
  bool _isCreating = false;
  String _selectedMonth = '';
  String? _selectedAccountId; // Add this

  @override
  void initState() {
    super.initState();
    _controller = locator.get<BudgetController>();
    _financeCategoryController = locator.get<FinanceCategoryController>();
    _supabaseService = locator.get<SupabaseService>();
    _accountController = locator.get<AccountController>();

    // Initialize with current month only
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _formatMonthDisplay(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      const monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${monthNames[month - 1]} $year';
    } catch (e) {
      return monthStr;
    }
  }

  Future<void> _selectMonth() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You can only create a budget for the current month.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              _formatMonthDisplay(_selectedMonth),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBudget() async {
    if (_selectedAccountId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an account')),
        );
      }
      return;
    }

    if (_categories.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one category')),
        );
      }
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Create the budget WITHOUT categories first
      final budget = Budget(
        month: _selectedMonth,
        categories: [],
        status: BudgetStatus.active,
        userId: _supabaseService.userId,
        accountId: _selectedAccountId, // Add accountId here
      );

      await _controller.createBudget(budget);

      // Get the created budget to get its ID
      final createdBudget = (_controller.data ?? []).firstWhere(
        (b) => b.month == _selectedMonth && b.accountId == _selectedAccountId,
      );

      if (createdBudget.id == null) {
        throw Exception('Failed to get created budget ID');
      }

      // Now add each category with the budgetId
      for (final category in _categories) {
        final categoryWithIds = category.copyWith(
          budgetId: createdBudget.id!,
          userId: _supabaseService.userId,
        );
        await _controller.addCategory(createdBudget.id!, categoryWithIds);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget created successfully!')),
        );
        context.goBack();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating budget: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showCategoryDialog({BudgetCategory? category}) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        controller: _financeCategoryController,
        category: category,
        onSave: (cat) {
          // Remove accountId parameter
          setState(() {
            if (category != null) {
              final index = _categories.indexOf(category);
              if (index != -1) _categories[index] = cat;
            } else {
              _categories.add(cat);
            }
            // Removed the accountId logic since it's handled at budget level
          });
        },
        onDelete: category != null
            ? () {
                setState(() {
                  _categories.remove(category);
                });
                Navigator.pop(context);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _categories
        .where((c) => c.financeCategory?.type == CategoryType.expense)
        .fold(0.0, (sum, c) => sum + c.targetAmount);
    final totalIncome = _categories
        .where((c) => c.financeCategory?.type == CategoryType.income)
        .fold(0.0, (sum, c) => sum + c.targetAmount);
    final balance = totalIncome - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Budget'),
        actions: [
          if (_isCreating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _createBudget, child: const Text('SAVE')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Account Selection Card
              AsyncStreamBuilder<List<Account>>(
                state: _accountController,
                builder: (context, accounts) {
                  // Auto-select first account if none selected
                  if (_selectedAccountId == null && accounts.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedAccountId = accounts.first.id;
                      });
                    });
                  }

                  final selectedAccount = accounts
                      .where((acc) => acc.id == _selectedAccountId)
                      .firstOrNull;

                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedAccount?.colorHex != null
                              ? Color(
                                  int.parse(
                                    selectedAccount!.colorHex!.replaceFirst(
                                      '#',
                                      '0xFF',
                                    ),
                                  ),
                                ).withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance_wallet),
                      ),
                      title: const Text('Account'),
                      subtitle: Text(
                        selectedAccount?.name ?? 'Select an account',
                        style: TextStyle(
                          fontWeight: selectedAccount != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () => _showAccountPicker(accounts),
                    ),
                  );
                },
                loadingBuilder: (context) => const Card(
                  child: ListTile(
                    leading: Icon(Icons.account_balance_wallet),
                    title: Text('Loading accounts...'),
                  ),
                ),
                errorBuilder: (context, message) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Error loading accounts'),
                    subtitle: Text(message),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Month selection card
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Month'),
                  subtitle: Text(_formatMonthDisplay(_selectedMonth)),
                  trailing: const Icon(Icons.info_outline),
                  onTap: _selectMonth,
                ),
              ),
              const SizedBox(height: 16),

              // Summary Card
              Card(
                color: (balance >= 0 ? Colors.green : Colors.red).withOpacity(
                  0.1,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            'Income',
                            totalIncome,
                            Colors.green,
                          ),
                          _buildSummaryItem(
                            'Expenses',
                            totalExpenses,
                            Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Balance: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '₱${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Categories header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _selectedAccountId != null
                        ? _showCategoryDialog
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Categories list
              Expanded(
                child: _categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedAccountId == null
                                  ? 'Select an account first'
                                  : 'No categories added',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedAccountId == null
                                  ? 'Choose an account to start adding categories'
                                  : 'Tap "Add Category" to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isIncome =
                              category.financeCategory?.type ==
                              CategoryType.income;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isIncome ? Colors.green : Colors.red)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isIncome
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isIncome ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(category.financeCategory?.name ?? ''),
                              subtitle: Text(
                                category.financeCategory?.type.displayName ??
                                    '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Text(
                                '₱${category.targetAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                              ),
                              onTap: () =>
                                  _showCategoryDialog(category: category),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _categories.isNotEmpty && _selectedAccountId != null
          ? FloatingActionButton.extended(
              onPressed: _isCreating ? null : _createBudget,
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isCreating ? 'Creating...' : 'Create Budget'),
            )
          : null,
    );
  }

  void _showAccountPicker(List<Account> accounts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Account'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              final isSelected = account.id == _selectedAccountId;
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: account.colorHex != null
                        ? Color(
                            int.parse(
                              account.colorHex!.replaceFirst('#', '0xFF'),
                            ),
                          )
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(account.name),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedAccountId = account.id;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Category Dialog - Simplified without account selection
class _CategoryDialog extends StatefulWidget {
  final FinanceCategoryController controller;
  final BudgetCategory? category;
  final Function(BudgetCategory) onSave; // Back to single parameter
  final VoidCallback? onDelete;

  const _CategoryDialog({
    required this.controller,
    this.category,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  FinanceCategory? _selectedCategory;
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _selectedCategory = widget.category!.financeCategory;
      _amountController.text = widget.category!.targetAmount.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return AsyncStreamBuilder<List<FinanceCategory>>(
      state: widget.controller,
      builder: (context, financeCategories) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Category' : 'Add Category'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Selection Dropdown
                DropdownButtonFormField<FinanceCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                  items: financeCategories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.type == CategoryType.income
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                size: 16,
                                color: cat.type == CategoryType.income
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(cat.name),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                ),
                const SizedBox(height: 16),

                // Amount Input
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    border: OutlineInputBorder(),
                    prefixText: '₱ ',
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (isEdit && widget.onDelete != null)
              TextButton(
                onPressed: widget.onDelete,
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final newCategory = BudgetCategory(
                    budgetId: widget.category?.budgetId ?? '',
                    financeCategoryId: _selectedCategory!.id!,
                    targetAmount: double.parse(_amountController.text),
                    financeCategory: _selectedCategory,
                  );
                  widget.onSave(newCategory);
                  Navigator.pop(context);
                }
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        );
      },
      loadingBuilder: (context) => const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      errorBuilder: (context, message) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
