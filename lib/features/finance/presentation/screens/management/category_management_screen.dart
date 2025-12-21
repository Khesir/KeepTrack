import 'package:flutter/material.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';
import 'package:persona_codex/features/finance/modules/budget/domain/entities/budget_category.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  // Temporary local state - will be replaced with database later
  final List<BudgetCategory> _categories = [
    BudgetCategory(id: '1', name: 'Salary', type: CategoryType.income, targetAmount: 0),
    BudgetCategory(id: '2', name: 'Groceries', type: CategoryType.expense, targetAmount: 5000),
    BudgetCategory(id: '3', name: 'Transportation', type: CategoryType.expense, targetAmount: 2000),
    BudgetCategory(id: '4', name: 'Stocks', type: CategoryType.investment, targetAmount: 10000),
    BudgetCategory(id: '5', name: 'Emergency Fund', type: CategoryType.savings, targetAmount: 50000),
  ];

  void _showCreateEditDialog({BudgetCategory? category}) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final targetController = TextEditingController(
      text: category?.targetAmount.toString() ?? '0',
    );
    CategoryType selectedType = category?.type ?? CategoryType.expense;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Category' : 'Create Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                    helperText: 'e.g., Groceries, Rent, Salary',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category Type',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...CategoryType.values.map((type) {
                  return RadioListTile<CategoryType>(
                    title: Text(type.displayName),
                    subtitle: Text(_getCategoryTypeDescription(type)),
                    value: type,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (Optional)',
                    border: OutlineInputBorder(),
                    prefixText: '₱ ',
                    helperText: 'Set a budget target for this category',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a category name')),
                  );
                  return;
                }

                final targetAmount = double.tryParse(targetController.text) ?? 0;

                setState(() {
                  if (isEdit) {
                    final index = _categories.indexWhere((c) => c.id == category.id);
                    _categories[index] = BudgetCategory(
                      id: category.id,
                      name: nameController.text.trim(),
                      type: selectedType,
                      targetAmount: targetAmount,
                    );
                  } else {
                    _categories.add(BudgetCategory(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      type: selectedType,
                      targetAmount: targetAmount,
                    ));
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Category updated' : 'Category created'),
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

  void _deleteCategory(BudgetCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _categories.removeWhere((c) => c.id == category.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Category deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getCategoryTypeDescription(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return 'Money coming in';
      case CategoryType.expense:
        return 'Money going out';
      case CategoryType.investment:
        return 'Long-term growth';
      case CategoryType.savings:
        return 'Money set aside';
    }
  }

  Color _getCategoryTypeColor(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return Colors.green;
      case CategoryType.expense:
        return Colors.red;
      case CategoryType.investment:
        return Colors.blue;
      case CategoryType.savings:
        return Colors.orange;
    }
  }

  IconData _getCategoryTypeIcon(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return Icons.arrow_downward;
      case CategoryType.expense:
        return Icons.arrow_upward;
      case CategoryType.investment:
        return Icons.trending_up;
      case CategoryType.savings:
        return Icons.savings;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group categories by type
    final groupedCategories = <CategoryType, List<BudgetCategory>>{};
    for (final category in _categories) {
      groupedCategories.putIfAbsent(category.type, () => []).add(category);
    }

    return Scaffold(
      backgroundColor: GCashColors.background,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEditDialog(),
            tooltip: 'Create Category',
          ),
        ],
      ),
      body: _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create categories to organize income and expenses',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showCreateEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Category'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: GCashSpacing.screenPadding,
              children: CategoryType.values.map((type) {
                final categoriesOfType = groupedCategories[type] ?? [];
                if (categoriesOfType.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _getCategoryTypeColor(type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _getCategoryTypeIcon(type),
                              color: _getCategoryTypeColor(type),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.displayName,
                            style: GCashTextStyles.h3.copyWith(
                              color: _getCategoryTypeColor(type),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryTypeColor(type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${categoriesOfType.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getCategoryTypeColor(type),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...categoriesOfType.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getCategoryTypeColor(category.type).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getCategoryTypeIcon(category.type),
                                color: _getCategoryTypeColor(category.type),
                              ),
                            ),
                            title: Text(
                              category.name,
                              style: GCashTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: category.targetAmount > 0
                                ? Text(
                                    'Target: ₱${category.targetAmount.toStringAsFixed(2)}',
                                    style: GCashTextStyles.bodySmall.copyWith(
                                      color: GCashColors.textSecondary,
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showCreateEditDialog(category: category),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCategory(category),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
      floatingActionButton: _categories.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showCreateEditDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
