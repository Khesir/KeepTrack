import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../../../../../core/routing/app_router.dart';
import '../../../../modules/budget/domain/entities/budget.dart';
import '../../../../modules/budget/domain/entities/budget_category.dart';
import '../../../../modules/finance_category/domain/entities/finance_category.dart';
import '../../../state/budget_controller.dart';
import '../../../state/finance_category_controller.dart';

class CreateBudgetScreen extends StatefulWidget {
  final Budget? existingBudget;

  const CreateBudgetScreen({super.key, this.existingBudget});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  late final BudgetController _controller;
  late final FinanceCategoryController _financeCategoryController;
  late final SupabaseService _supabaseService;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _customTargetController = TextEditingController();
  final List<BudgetCategory> _categories = [];
  bool _isCreating = false;
  String _selectedMonth = '';
  BudgetType _budgetType = BudgetType.expense;
  BudgetPeriodType _periodType = BudgetPeriodType.monthly;
  bool _copyFromBudget = false;
  String? _sourceBudgetId;
  bool _useCustomTarget = false;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<BudgetController>();
    _financeCategoryController = locator.get<FinanceCategoryController>();
    _supabaseService = locator.get<SupabaseService>();

    // Initialize from existing budget or use current month
    if (widget.existingBudget != null) {
      _selectedMonth = widget.existingBudget!.month;
      _titleController.text = widget.existingBudget!.title ?? '';
      _budgetType = widget.existingBudget!.budgetType;
      _periodType = widget.existingBudget!.periodType;
      _categories.addAll(widget.existingBudget!.categories);
      if (widget.existingBudget!.customTargetAmount != null) {
        _useCustomTarget = true;
        _customTargetController.text = widget.existingBudget!.customTargetAmount.toString();
      }
    } else {
      final now = DateTime.now();
      _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }

    // Load budgets to check for duplicates
    _controller.loadBudgets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customTargetController.dispose();
    super.dispose();
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

  Future<void> _saveBudget() async {
    if (_categories.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one category')),
        );
      }
      return;
    }

    final isEditing = widget.existingBudget != null;

    setState(() => _isCreating = true);

    try {
      if (isEditing) {
        // Edit mode: Update existing budget categories
        final budgetId = widget.existingBudget!.id!;

        // Get existing category IDs
        final existingCategoryIds = widget.existingBudget!.categories
            .where((c) => c.id != null)
            .map((c) => c.id!)
            .toSet();

        // Get current category IDs
        final currentCategoryIds = _categories
            .where((c) => c.id != null)
            .map((c) => c.id!)
            .toSet();

        // Delete removed categories
        for (final categoryId in existingCategoryIds) {
          if (!currentCategoryIds.contains(categoryId)) {
            await _controller.deleteCategory(budgetId, categoryId);
          }
        }

        // Update or add categories
        for (final category in _categories) {
          if (category.id != null && existingCategoryIds.contains(category.id)) {
            // Update existing category
            await _controller.updateCategory(budgetId, category);
          } else {
            // Add new category
            final categoryWithIds = category.copyWith(
              budgetId: budgetId,
              userId: _supabaseService.userId,
            );
            await _controller.addCategory(budgetId, categoryWithIds);
          }
        }

        // Update budget custom target amount
        final updatedBudget = widget.existingBudget!.copyWith(
          customTargetAmount: _useCustomTarget && _customTargetController.text.isNotEmpty
              ? double.tryParse(_customTargetController.text)
              : null,
        );
        await _controller.updateBudget(updatedBudget);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget updated successfully!')),
          );
        }
      } else {
        // Create mode: Create new budget
        final budget = Budget(
          month: _selectedMonth,
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          budgetType: _budgetType,
          periodType: _periodType,
          categories: [],
          status: BudgetStatus.active,
          customTargetAmount: _useCustomTarget && _customTargetController.text.isNotEmpty
              ? double.tryParse(_customTargetController.text)
              : null,
          userId: _supabaseService.userId,
        );

        final createdBudget = await _controller.createBudget(budget);

        if (createdBudget.id == null) {
          throw Exception('Failed to get created budget ID');
        }

        // Add each category
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
        }
      }

      // Reload all budgets to ensure we have the latest data
      await _controller.loadBudgets();

      if (mounted) {
        context.goBack();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${isEditing ? 'updating' : 'creating'} budget: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _copyBudgetCategories(String budgetId) async {
    try {
      final budgets = _controller.data ?? [];
      final sourceBudget = budgets.firstWhere((b) => b.id == budgetId);

      setState(() {
        // Copy budget type and period type
        _budgetType = sourceBudget.budgetType;
        _periodType = sourceBudget.periodType;

        _categories.clear();
        // Copy all categories from source budget
        for (final category in sourceBudget.categories) {
          _categories.add(
            BudgetCategory(
              budgetId: '', // Will be set when creating
              financeCategoryId: category.financeCategoryId,
              targetAmount: category.targetAmount,
              financeCategory: category.financeCategory,
            ),
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Copied ${_categories.length} categories from ${sourceBudget.title ?? _formatMonthDisplay(sourceBudget.month)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCategoryDialog({BudgetCategory? category}) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        controller: _financeCategoryController,
        budgetType: _budgetType,
        category: category,
        existingCategories: _categories,
        onSave: (cat) {
          // Check for duplicates (only when adding new category)
          if (category == null) {
            final isDuplicate = _categories.any(
              (existing) => existing.financeCategoryId == cat.financeCategoryId,
            );
            if (isDuplicate) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This category is already added to the budget'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
          }

          setState(() {
            if (category != null) {
              final index = _categories.indexOf(category);
              if (index != -1) _categories[index] = cat;
            } else {
              _categories.add(cat);
            }
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
    final isEditing = widget.existingBudget != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Budget' : 'Create Budget'),
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
            TextButton(onPressed: _saveBudget, child: const Text('SAVE')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Title input field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Budget Title ${_periodType == BudgetPeriodType.oneTime ? '(Required for one-time budgets)' : '(Optional)'}',
                  hintText: 'e.g., Vacation, Monthly Expenses, etc.',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: _periodType == BudgetPeriodType.oneTime
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required for one-time budgets';
                        }
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 16),

              // Budget Type Selection
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category),
                      title: const Text('Budget Type'),
                      subtitle: Text(_budgetType.displayName),
                    ),
                    const Divider(height: 1),
                    Row(
                      children: BudgetType.values.map((type) {
                        return Expanded(
                          child: RadioListTile<BudgetType>(
                            title: Text(type.displayName),
                            value: type,
                            groupValue: _budgetType,
                            onChanged: isEditing ? null : (value) {
                              if (value != null) {
                                setState(() {
                                  _budgetType = value;
                                  _categories.clear(); // Clear categories when changing type
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Period Type Selection
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Period Type'),
                      subtitle: Text(_periodType.description),
                    ),
                    const Divider(height: 1),
                    ...BudgetPeriodType.values.map((type) {
                      return RadioListTile<BudgetPeriodType>(
                        title: Text(type.displayName),
                        subtitle: Text(type.description),
                        value: type,
                        groupValue: _periodType,
                        onChanged: isEditing ? null : (value) {
                          if (value != null) {
                            setState(() => _periodType = value);
                          }
                        },
                      );
                    }),
                  ],
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
              const SizedBox(height: 8),

              // Copy from previous budget option (only in create mode)
              if (!isEditing)
                AsyncStreamBuilder<List<Budget>>(
                state: _controller,
                builder: (context, budgets) {
                  // Filter budgets and exclude current month
                  final availableBudgets = budgets
                      .where((b) =>
                          b.month != _selectedMonth &&
                          b.categories.isNotEmpty)
                      .toList()
                    ..sort((a, b) => b.month.compareTo(a.month)); // Most recent first

                  if (availableBudgets.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.copy_all),
                          title: const Text('Copy from previous budget'),
                          subtitle: const Text('Use an existing budget as template'),
                          value: _copyFromBudget,
                          onChanged: (value) {
                            setState(() {
                              _copyFromBudget = value;
                              if (!value) {
                                _sourceBudgetId = null;
                                _categories.clear();
                              }
                            });
                          },
                        ),
                        if (_copyFromBudget) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: DropdownButtonFormField<String>(
                              value: _sourceBudgetId,
                              decoration: const InputDecoration(
                                labelText: 'Select budget to copy',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.history),
                              ),
                              items: availableBudgets
                                  .map(
                                    (budget) => DropdownMenuItem(
                                      value: budget.id,
                                      child: Text(
                                        _formatMonthDisplay(budget.month),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (budgetId) async {
                                if (budgetId != null) {
                                  setState(() => _sourceBudgetId = budgetId);
                                  await _copyBudgetCategories(budgetId);
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loadingBuilder: (context) => const SizedBox.shrink(),
                errorBuilder: (context, message) => const SizedBox.shrink(),
              ),
              if (!isEditing) const SizedBox(height: 8),

              // Custom Target Amount Card
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.tune),
                      title: const Text('Set Custom Budget Target'),
                      subtitle: Text(
                        _useCustomTarget
                            ? 'Override calculated target from categories'
                            : 'Target calculated from categories: ₱${_categories.fold(0.0, (sum, cat) => sum + cat.targetAmount).toStringAsFixed(2)}',
                      ),
                      value: _useCustomTarget,
                      onChanged: (value) {
                        setState(() {
                          _useCustomTarget = value;
                          if (!value) {
                            _customTargetController.clear();
                          }
                        });
                      },
                    ),
                    if (_useCustomTarget) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _customTargetController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Target Amount',
                            border: OutlineInputBorder(),
                            prefixText: '₱ ',
                            prefixIcon: Icon(Icons.attach_money),
                            helperText: 'Leave empty to use calculated target',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              if (double.parse(value) <= 0) {
                                return 'Amount must be greater than 0';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ],
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
                    onPressed: _showCategoryDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Categories list
              _categories.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
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
                            'No categories added',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Add Category" to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80),
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
            ],
          ),
        ),
      ),
      floatingActionButton: _categories.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isCreating ? null : _saveBudget,
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
              label: Text(_isCreating
                  ? (widget.existingBudget != null ? 'Updating...' : 'Creating...')
                  : (widget.existingBudget != null ? 'Update Budget' : 'Create Budget')),
            )
          : null,
    );
  }

}

/// Category Dialog - Simplified without account selection
class _CategoryDialog extends StatefulWidget {
  final FinanceCategoryController controller;
  final BudgetType budgetType;
  final BudgetCategory? category;
  final List<BudgetCategory> existingCategories;
  final Function(BudgetCategory) onSave; // Back to single parameter
  final VoidCallback? onDelete;

  const _CategoryDialog({
    required this.controller,
    required this.budgetType,
    this.category,
    this.existingCategories = const [],
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
        // Filter categories based on budget type
        final typedCategories = financeCategories.where((cat) {
          if (widget.budgetType == BudgetType.income) {
            return cat.type == CategoryType.income;
          } else {
            // Expense budget includes: expense, investment, savings, transfer
            return cat.type == CategoryType.expense ||
                cat.type == CategoryType.investment ||
                cat.type == CategoryType.savings ||
                cat.type == CategoryType.transfer;
          }
        }).toList();

        // Filter out already selected categories (except when editing)
        final availableCategories = typedCategories.where((cat) {
          if (isEdit && cat.id == widget.category?.financeCategoryId) {
            return true; // Allow current category when editing
          }
          return !widget.existingCategories
              .any((existing) => existing.financeCategoryId == cat.id);
        }).toList();

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
                  items: availableCategories
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
