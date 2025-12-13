import 'package:flutter/material.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/repositories/budget_repository.dart';

/// Create budget screen
class CreateBudgetScreen extends ScopedScreen {
  const CreateBudgetScreen({super.key});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends ScopedScreenState<CreateBudgetScreen> {
  late BudgetRepository _repository;
  final _formKey = GlobalKey<FormState>();

  String _selectedMonth = '';
  final List<BudgetCategory> _categories = [];

  final _defaultCategories = [
    {'name': 'Salary', 'type': CategoryType.income, 'amount': 5000.0},
    {'name': 'Freelance', 'type': CategoryType.income, 'amount': 1000.0},
    {'name': 'Housing', 'type': CategoryType.expense, 'amount': 1500.0},
    {'name': 'Food', 'type': CategoryType.expense, 'amount': 500.0},
    {'name': 'Transportation', 'type': CategoryType.expense, 'amount': 300.0},
    {'name': 'Stocks', 'type': CategoryType.investment, 'amount': 1000.0},
    {'name': 'Emergency Fund', 'type': CategoryType.savings, 'amount': 500.0},
  ];

  @override
  void onReady() {
    _repository = getService<BudgetRepository>();

    // Generate current month
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Add default categories
    for (var i = 0; i < _defaultCategories.length; i++) {
      final cat = _defaultCategories[i];
      _categories.add(
        BudgetCategory(
          id: 'cat-$i',
          name: cat['name'] as String,
          type: cat['type'] as CategoryType,
          targetAmount: cat['amount'] as double,
        ),
      );
    }

    setState(() {});
  }

  Future<void> _createBudget() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one category')),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final budget = Budget(
        id: 'budget-${now.millisecondsSinceEpoch}',
        month: _selectedMonth,
        categories: _categories,
        records: [],
        status: BudgetStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.createBudget(budget);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating budget: $e')),
        );
      }
    }
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) => _AddCategoryDialog(
        onAdd: (category) {
          setState(() => _categories.add(category));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Budget'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Month (YYYY-MM)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _selectedMonth = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a month';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._categories.map((category) => Card(
                  child: ListTile(
                    title: Text(category.name),
                    subtitle: Text(category.type.displayName),
                    trailing: Text(
                      '\$${category.targetAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => _editCategory(category),
                  ),
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createBudget,
              child: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }

  void _editCategory(BudgetCategory category) {
    // Simple edit - could be enhanced
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: const Text('Tap and hold to delete, or create new budget'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _categories.remove(category));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  final Function(BudgetCategory) onAdd;

  const _AddCategoryDialog({required this.onAdd});

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  CategoryType _selectedType = CategoryType.expense;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Target Amount',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<CategoryType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: CategoryType.values
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _amountController.text.isNotEmpty) {
              final category = BudgetCategory(
                id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
                name: _nameController.text,
                type: _selectedType,
                targetAmount: double.tryParse(_amountController.text) ?? 0,
              );
              widget.onAdd(category);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
