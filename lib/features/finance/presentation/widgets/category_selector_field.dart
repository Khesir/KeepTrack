import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/budget/domain/entities/budget.dart';
import '../../modules/budget/presentation/controllers/budget_controller.dart';
import '../../modules/finance_category/domain/entities/finance_category.dart';
import '../../modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../modules/transaction/domain/entities/transaction.dart';
import '../state/finance_category_controller.dart';

class _CategoryGroup {
  final String name;
  final List<FinanceCategory> categories;
  const _CategoryGroup(this.name, this.categories);
}

class CategorySelectorField extends StatelessWidget {
  final FinanceCategoryController categoryController;
  final BudgetController budgetController;
  final TransactionType selectedType;
  final DateTime selectedDate;
  final String? selectedProfileId;
  final String? selectedCategoryId;
  final FinanceCategory? selectedCategory;
  final ValueChanged<FinanceCategory> onSelect;
  final VoidCallback onTypeMismatch;

  const CategorySelectorField({
    super.key,
    required this.categoryController,
    required this.budgetController,
    required this.selectedType,
    required this.selectedDate,
    required this.selectedProfileId,
    required this.selectedCategoryId,
    required this.selectedCategory,
    required this.onSelect,
    required this.onTypeMismatch,
  });

  List<_CategoryGroup> _getGroupedCategories(
    List<FinanceCategory> allCategories,
  ) {
    final txnMonth = DateFormat('yyyy-MM').format(selectedDate);

    final CategoryType targetType = selectedType == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;

    // Exclude archived and non income/expense types; filter by profile if selected
    Set<String>? profileCategoryIds;
    if (selectedProfileId != null) {
      final bs = budgetController.state;
      if (bs is AsyncData<List<Budget>>) {
        profileCategoryIds = bs.data
            .where((b) => b.budgetProfileId == selectedProfileId)
            .expand((b) => b.categories.map((c) => c.financeCategoryId))
            .toSet();
      }
    }

    final typedCategories = allCategories
        .where((c) => c.type == targetType && !c.isArchive)
        .where((c) => profileCategoryIds == null || (c.id != null && profileCategoryIds!.contains(c.id)))
        .toList();

    final budgetState = budgetController.state;
    final allBudgets = budgetState is AsyncData<List<Budget>>
        ? budgetState.data
        : <Budget>[];

    final targetBudgetType = selectedType == TransactionType.income
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

  void _showCategoryDialog(BuildContext context, List<FinanceCategory> allCategories) {
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
                            selected: selectedCategoryId == cat.id,
                            selectedTileColor: colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            trailing: selectedCategoryId == cat.id
                                ? Icon(
                                    Icons.check,
                                    size: 18,
                                    color: colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              onSelect(cat);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return AsyncStreamBuilder<List<FinanceCategory>>(
      state: categoryController,
      loadingBuilder: (context) => const LinearProgressIndicator(),
      errorBuilder: (context, message) => Text(
        'Error loading categories: $message',
        style: TextStyle(color: colorScheme.error),
      ),
      builder: (context, categories) {
        final CategoryType targetType = selectedType == TransactionType.income
            ? CategoryType.income
            : CategoryType.expense;

        final typedCategories = categories
            .where((c) => c.type == targetType)
            .toList();

        if (typedCategories.isEmpty) {
          return Text(
            'No ${selectedType.displayName.toLowerCase()} categories found.',
            style: TextStyle(color: colorScheme.error),
          );
        }

        if (selectedCategory != null &&
            selectedCategory!.type != targetType) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onTypeMismatch();
          });
        }

        final hasSelection = selectedCategory != null;

        return FormField<String>(
          initialValue: selectedCategoryId,
          validator: (_) =>
              selectedCategoryId == null ? 'Please select a category' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _showCategoryDialog(context, categories),
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
                          selectedCategory!.type.icon,
                          size: 18,
                          color: selectedCategory!.type.color,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          hasSelection
                              ? selectedCategory!.name
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
}
