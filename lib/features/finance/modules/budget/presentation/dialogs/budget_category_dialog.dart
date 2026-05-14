import 'package:flutter/material.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';

class BudgetCategoryDialog extends StatefulWidget {
  final FinanceCategoryController controller;
  final BudgetType budgetType;
  final BudgetCategory? category;
  final List<BudgetCategory> existingCategories;
  final void Function(BudgetCategory) onSave;
  final VoidCallback? onDelete;

  const BudgetCategoryDialog({
    super.key,
    required this.controller,
    required this.budgetType,
    this.category,
    this.existingCategories = const [],
    required this.onSave,
    this.onDelete,
  });

  @override
  State<BudgetCategoryDialog> createState() => _BudgetCategoryDialogState();
}

class _BudgetCategoryDialogState extends State<BudgetCategoryDialog> {
  FinanceCategory? _selectedCategory;
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.category != null;

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

  List<FinanceCategory> _filterCategories(List<FinanceCategory> all) {
    final typed = all.where((cat) {
      if (widget.budgetType == BudgetType.income) {
        return cat.type == CategoryType.income;
      }
      return cat.type == CategoryType.expense ||
          cat.type == CategoryType.investment ||
          cat.type == CategoryType.savings ||
          cat.type == CategoryType.transfer;
    });

    return typed.where((cat) {
      if (_isEdit && cat.id == widget.category?.financeCategoryId) return true;
      return !widget.existingCategories
          .any((e) => e.financeCategoryId == cat.id);
    }).toList();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final newCategory = BudgetCategory(
      budgetId: widget.category?.budgetId ?? '',
      financeCategoryId: _selectedCategory!.id!,
      targetAmount: double.parse(_amountController.text),
      financeCategory: _selectedCategory,
    );
    widget.onSave(newCategory);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<FinanceCategory>>(
      state: widget.controller,
      builder: (context, financeCategories) {
        final available = _filterCategories(financeCategories);

        return AlertDialog(
          title: Text(_isEdit ? 'Edit Category' : 'Add Category'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FinanceCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (v) => v == null ? 'Please select a category' : null,
                  items: available
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
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    border: OutlineInputBorder(),
                    prefixText: '₱ ',
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter an amount';
                    if (double.tryParse(v) == null) return 'Enter a valid number';
                    if (double.parse(v) <= 0) return 'Amount must be > 0';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (_isEdit && widget.onDelete != null)
              TextButton(
                onPressed: widget.onDelete,
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isEdit ? 'Save' : 'Add'),
            ),
          ],
        );
      },
      loadingBuilder: (_) => const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      errorBuilder: (_, message) => AlertDialog(
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
