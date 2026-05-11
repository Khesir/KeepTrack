import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart'
    show FinanceCategory;
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../../../../../../core/state/stream_state.dart';
import '../../../../presentation/state/finance_category_controller.dart';
import '../../../finance_category/domain/entities/finance_category_enums.dart';
import '../../domain/entities/budget.dart';

class AddCategorySheet extends StatefulWidget {
  final Budget group;
  final FinanceCategoryController categoryController;
  final SupabaseService supabaseService;
  final Future<void> Function(BudgetCategory) onSave;

  const AddCategorySheet({
    super.key,
    required this.group,
    required this.categoryController,
    required this.supabaseService,
    required this.onSave,
  });

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add Category', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              widget.group.title ?? '',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Groceries, Netflix, Salary',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Planned Amount',
                border: OutlineInputBorder(),
                prefixText: '₱ ',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a category name')));
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final budgetId = widget.group.id;
    if (budgetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget group has no ID — please try again.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      // Derive CategoryType from the group's BudgetType
      final catType = widget.group.budgetType == BudgetType.income
          ? CategoryType.income
          : CategoryType.expense;

      // Check if a matching FinanceCategory already exists — reuse it, don't duplicate
      final currentState = widget.categoryController.state;
      final currentCats = currentState is AsyncData<List<FinanceCategory>>
          ? currentState.data
          : <FinanceCategory>[];
      final existing = currentCats
          .where(
            (c) =>
                c.name.toLowerCase() == name.toLowerCase() && c.type == catType,
          )
          .firstOrNull;

      FinanceCategory created;
      if (existing != null) {
        created = existing;
      } else {
        // Create a new FinanceCategory in the DB
        await widget.categoryController.createCategory(
          FinanceCategory(
            name: name,
            type: catType,
            userId: widget.supabaseService.userId,
          ),
        );
        // Find the freshly created category in the updated cache
        final updatedState = widget.categoryController.state;
        final updatedCats = updatedState is AsyncData<List<FinanceCategory>>
            ? updatedState.data
            : <FinanceCategory>[];
        created = updatedCats.firstWhere(
          (c) =>
              c.name.toLowerCase() == name.toLowerCase() && c.type == catType,
          orElse: () => FinanceCategory(name: name, type: catType),
        );
      }

      await widget.onSave(
        BudgetCategory(
          budgetId: budgetId,
          financeCategoryId: created.id ?? '',
          targetAmount: amount,
          financeCategory: created,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }
}
