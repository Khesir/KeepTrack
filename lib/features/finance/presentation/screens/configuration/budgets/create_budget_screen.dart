import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/state.dart';
import 'package:persona_codex/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../../../../../core/ui/scoped_screen.dart';
import '../../../../../../core/routing/app_router.dart';
import '../../../../modules/budget/domain/entities/budget.dart';
import '../../../../modules/budget/domain/entities/budget_category.dart';
import '../../../../modules/finance_category/domain/entities/finance_category.dart';
import '../../../state/budget_controller.dart';
import '../../../state/finance_category_controller.dart';

class CreateBudgetScreen extends ScopedScreen {
  const CreateBudgetScreen({super.key});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends ScopedScreenState<CreateBudgetScreen> {
  late final BudgetController _controller;
  late final FinanceCategoryController _financeCategoryController;
  final _formKey = GlobalKey<FormState>();
  final List<BudgetCategory> _categories = [];

  String _selectedMonth = '';

  @override
  void registerServices() {
    _controller = locator.get<BudgetController>();
    _financeCategoryController = locator.get<FinanceCategoryController>();
  }

  @override
  void initState() {
    super.initState();

    // Initialize with current month only
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _formatMonthDisplay(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      final monthNames = [
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
    // Only allow current month
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
    // if (!_formKey.currentState!.validate()) return;

    // final categories = _controller.data ?? [];
    // if (categories.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please add at least one category')),
    //   );
    //   return;
    // }

    // try {
    //   // Check for duplicate month
    //   final existingBudgets = await _controller.getBudgets();
    //   final isDuplicate = existingBudgets.any((b) => b.month == _selectedMonth);

    //   if (isDuplicate) {
    //     if (mounted) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(
    //           content: Text(
    //             'Budget for ${_formatMonthDisplay(_selectedMonth)} already exists!',
    //           ),
    //         ),
    //       );
    //     }
    //     return;
    //   }

    //   final budget = Budget(
    //     month: _selectedMonth,
    //     categories: categories,
    //     status: BudgetStatus.active,
    //   );

    //   await _controller.createBudget(budget);

    //   if (mounted) {
    //     context.goBack();
    //   }
    // } catch (e) {
    //   if (mounted) {
    //     ScaffoldMessenger.of(
    //       context,
    //     ).showSnackBar(SnackBar(content: Text('Error creating budget: $e')));
    //   }
    // }
  }

  void _showCategoryDialog({BudgetCategory? category}) {
    showDialog(
      context: context,
      builder: (context) => AsyncStreamBuilder<List<FinanceCategory>>(
        state: _financeCategoryController,
        builder: (context, financeCategories) {
          return _CategoryDialog(
            financeCategories: financeCategories,
            category: category,
            onSave: (cat) {
              setState(() {
                if (category != null) {
                  // Edit existing category
                  final index = _categories.indexOf(category);
                  if (index != -1) _categories[index] = cat;
                } else {
                  // Add new category
                  _categories.add(cat);
                }
              });
            },
          );
        },
        loadingBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    double totalExpenses = _categories
        .where((c) => c.financeCategory?.type == CategoryType.expense)
        .fold(0, (sum, c) => sum + c.targetAmount);
    double totalIncome = _categories
        .where((c) => c.financeCategory?.type == CategoryType.income)
        .fold(0, (sum, c) => sum + c.targetAmount);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Budget')),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ), // horizontal spacing
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
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

              // --- Visualizer card ---
              Card(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Income',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₱${totalIncome.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Expenses',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₱${totalExpenses.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _showCategoryDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _categories.isEmpty
                    ? const Center(child: Text('No categories added'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(category.financeCategory?.name ?? ''),
                              subtitle: Text(
                                category.financeCategory?.type.displayName ??
                                    '',
                              ),
                              trailing: Text(
                                '₱${category.targetAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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
    );
  }
}

/// --- AddCategoryDialog ---
class _CategoryDialog extends StatefulWidget {
  final List<FinanceCategory> financeCategories;
  final BudgetCategory? category; // if null, it's Add mode
  final Function(BudgetCategory) onSave;

  const _CategoryDialog({
    required this.financeCategories,
    this.category,
    required this.onSave,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  FinanceCategory? _selectedCategory;
  final _amountController = TextEditingController();

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

    return AlertDialog(
      title: Text(isEdit ? 'Edit Category' : 'Add Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<FinanceCategory>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: widget.financeCategories
                .map(
                  (cat) => DropdownMenuItem(value: cat, child: Text(cat.name)),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Target Amount',
              border: OutlineInputBorder(),
              prefixText: '₱ ',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        if (isEdit)
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'delete'); // return 'delete' flag
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedCategory != null &&
                _amountController.text.isNotEmpty) {
              final newCategory = BudgetCategory(
                budgetId: '',
                financeCategoryId: _selectedCategory!.id!,
                targetAmount: double.tryParse(_amountController.text) ?? 0,
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
  }
}
