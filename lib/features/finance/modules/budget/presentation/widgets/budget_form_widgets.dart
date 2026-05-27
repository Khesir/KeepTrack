import 'package:flutter/material.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import '../controllers/budget_controller.dart';
import '../helpers/month_formatter.dart';

class BudgetTitleField extends StatelessWidget {
  final TextEditingController controller;
  final BudgetPeriodType periodType;

  const BudgetTitleField({
    super.key,
    required this.controller,
    required this.periodType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: periodType == BudgetPeriodType.oneTime
            ? 'Budget Title (Required for one-time budgets)'
            : 'Budget Title (Optional)',
        hintText: 'e.g., Vacation, Monthly Expenses, etc.',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.title),
      ),
      validator: periodType == BudgetPeriodType.oneTime
          ? (v) => (v == null || v.trim().isEmpty)
                ? 'Title is required for one-time budgets'
                : null
          : null,
    );
  }
}

class BudgetTypeCard extends StatelessWidget {
  final BudgetType budgetType;
  final bool isEditing;
  final void Function(BudgetType) onChanged;

  const BudgetTypeCard({
    super.key,
    required this.budgetType,
    required this.isEditing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Budget Type'),
            subtitle: Text(budgetType.displayName),
          ),
          const Divider(height: 1),
          Row(
            children: BudgetType.values.map((type) {
              return Expanded(
                child: RadioListTile<BudgetType>(
                  title: Text(type.displayName),
                  value: type,
                  groupValue: budgetType,
                  onChanged: isEditing
                      ? null
                      : (v) {
                          if (v != null) onChanged(v);
                        },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class BudgetPeriodTypeCard extends StatelessWidget {
  final BudgetPeriodType periodType;
  final bool isEditing;
  final void Function(BudgetPeriodType) onChanged;

  const BudgetPeriodTypeCard({
    super.key,
    required this.periodType,
    required this.isEditing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Period Type'),
            subtitle: Text(periodType.description),
          ),
          const Divider(height: 1),
          ...BudgetPeriodType.values.map((type) {
            return RadioListTile<BudgetPeriodType>(
              title: Text(type.displayName),
              subtitle: Text(type.description),
              value: type,
              groupValue: periodType,
              onChanged: isEditing
                  ? null
                  : (v) {
                      if (v != null) onChanged(v);
                    },
            );
          }),
        ],
      ),
    );
  }
}

class BudgetCopyFromCard extends StatelessWidget {
  final BudgetController controller;
  final String selectedMonth;
  final bool copyFromBudget;
  final String? sourceBudgetId;
  final void Function(bool) onToggle;
  final void Function(String) onSourceSelected;

  const BudgetCopyFromCard({
    super.key,
    required this.controller,
    required this.selectedMonth,
    required this.copyFromBudget,
    required this.sourceBudgetId,
    required this.onToggle,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Budget>>(
      state: controller,
      builder: (context, budgets) {
        final available = budgets
            .where((b) => b.month != selectedMonth && b.categories.isNotEmpty)
            .toList()
          ..sort((a, b) => b.month.compareTo(a.month));

        if (available.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.copy_all),
                title: const Text('Copy from previous budget'),
                subtitle: const Text('Use an existing budget as template'),
                value: copyFromBudget,
                onChanged: onToggle,
              ),
              if (copyFromBudget) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: sourceBudgetId,
                    decoration: const InputDecoration(
                      labelText: 'Select budget to copy',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.history),
                    ),
                    items: available
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(formatMonthDisplay(b.month)),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id != null) onSourceSelected(id);
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loadingBuilder: (_) => const SizedBox.shrink(),
      errorBuilder: (_, __) => const SizedBox.shrink(),
    );
  }
}

class BudgetCustomTargetCard extends StatelessWidget {
  final bool useCustomTarget;
  final TextEditingController customTargetController;
  final double categoryTotal;
  final void Function(bool) onToggle;

  const BudgetCustomTargetCard({
    super.key,
    required this.useCustomTarget,
    required this.customTargetController,
    required this.categoryTotal,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.tune),
            title: const Text('Set Custom Budget Target'),
            subtitle: Text(
              useCustomTarget
                  ? 'Override calculated target from categories'
                  : 'Target calculated from categories: ₱${categoryTotal.toStringAsFixed(2)}',
            ),
            value: useCustomTarget,
            onChanged: onToggle,
          ),
          if (useCustomTarget) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: customTargetController,
                decoration: const InputDecoration(
                  labelText: 'Custom Target Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₱ ',
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Leave empty to use calculated target',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (double.tryParse(v) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(v) <= 0) return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BudgetCategoryFormList extends StatelessWidget {
  final List<BudgetCategory> categories;
  final VoidCallback onAdd;
  final void Function(BudgetCategory) onEdit;

  const BudgetCategoryFormList({
    super.key,
    required this.categories,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (categories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                SizedBox(height: 16),
                Text(
                  'No categories added',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap "Add Category" to get started',
                  style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isIncome = cat.financeCategory?.type == CategoryType.income;
              final color = isIncome ? AppColors.income : AppColors.expense;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(cat.financeCategory?.name ?? ''),
                  subtitle: Text(
                    cat.financeCategory?.type.displayName ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  trailing: Text(
                    '₱${cat.targetAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  onTap: () => onEdit(cat),
                ),
              );
            },
          ),
      ],
    );
  }
}
