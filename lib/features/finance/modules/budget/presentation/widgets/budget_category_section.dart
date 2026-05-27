import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import 'budget_category_card.dart';

class BudgetCategorySection extends StatelessWidget {
  final Budget budget;
  final String? selectedCategoryId;
  final bool isDesktop;
  final void Function(String) onCategoryTap;

  const BudgetCategorySection({
    super.key,
    required this.budget,
    required this.selectedCategoryId,
    required this.isDesktop,
    required this.onCategoryTap,
  });

  List<BudgetCategory> _byType(CategoryType type) => budget.categories
      .where((c) => c.financeCategory?.type == type)
      .toList();

  @override
  Widget build(BuildContext context) {
    final income = _byType(CategoryType.income);
    final expense = _byType(CategoryType.expense);
    final savings = _byType(CategoryType.savings);
    final investment = _byType(CategoryType.investment);

    if (isDesktop) {
      return _DesktopCategoryGrid(
        income: income,
        expense: expense,
        savings: savings,
        investment: investment,
        budget: budget,
        selectedCategoryId: selectedCategoryId,
        onCategoryTap: onCategoryTap,
      );
    }

    return _MobileCategoryList(
      income: income,
      expense: expense,
      savings: savings,
      investment: investment,
      budget: budget,
      selectedCategoryId: selectedCategoryId,
      onCategoryTap: onCategoryTap,
    );
  }
}

class _DesktopCategoryGrid extends StatelessWidget {
  final List<BudgetCategory> income;
  final List<BudgetCategory> expense;
  final List<BudgetCategory> savings;
  final List<BudgetCategory> investment;
  final Budget budget;
  final String? selectedCategoryId;
  final void Function(String) onCategoryTap;

  const _DesktopCategoryGrid({
    required this.income,
    required this.expense,
    required this.savings,
    required this.investment,
    required this.budget,
    required this.selectedCategoryId,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (income.isNotEmpty) ...[
          _CategoryGroupLabel(label: 'Income'),
          const SizedBox(height: AppSpacing.sm),
          _GridGroup(
            categories: income,
            budget: budget,
            selectedCategoryId: selectedCategoryId,
            onCategoryTap: onCategoryTap,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (expense.isNotEmpty) ...[
          _CategoryGroupLabel(label: 'Expenses'),
          const SizedBox(height: AppSpacing.sm),
          _GridGroup(
            categories: expense,
            budget: budget,
            selectedCategoryId: selectedCategoryId,
            onCategoryTap: onCategoryTap,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (savings.isNotEmpty) ...[
          _CategoryGroupLabel(label: 'Savings'),
          const SizedBox(height: AppSpacing.sm),
          _GridGroup(
            categories: savings,
            budget: budget,
            selectedCategoryId: selectedCategoryId,
            onCategoryTap: onCategoryTap,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (investment.isNotEmpty) ...[
          _CategoryGroupLabel(label: 'Investments'),
          const SizedBox(height: AppSpacing.sm),
          _GridGroup(
            categories: investment,
            budget: budget,
            selectedCategoryId: selectedCategoryId,
            onCategoryTap: onCategoryTap,
          ),
        ],
      ],
    );
  }
}

class _GridGroup extends StatelessWidget {
  final List<BudgetCategory> categories;
  final Budget budget;
  final String? selectedCategoryId;
  final void Function(String) onCategoryTap;

  const _GridGroup({
    required this.categories,
    required this.budget,
    required this.selectedCategoryId,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: AppSpacing.sm + 4,
        mainAxisSpacing: AppSpacing.sm + 4,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) => BudgetCategoryCard(
        category: categories[i],
        budgetType: budget.budgetType,
        isSelected: selectedCategoryId == categories[i].financeCategoryId,
        onTap: () => onCategoryTap(categories[i].financeCategoryId),
      ),
    );
  }
}

class _MobileCategoryList extends StatelessWidget {
  final List<BudgetCategory> income;
  final List<BudgetCategory> expense;
  final List<BudgetCategory> savings;
  final List<BudgetCategory> investment;
  final Budget budget;
  final String? selectedCategoryId;
  final void Function(String) onCategoryTap;

  const _MobileCategoryList({
    required this.income,
    required this.expense,
    required this.savings,
    required this.investment,
    required this.budget,
    required this.selectedCategoryId,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (income.isNotEmpty) ...[
          _ListGroup(
            label: 'Income',
            categories: income,
            budget: budget,
            selectedCategoryId: selectedCategoryId,
            onCategoryTap: onCategoryTap,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (expense.isNotEmpty) ...[
          _ListGroup(
            label: 'Expenses',
            categories: expense,
            budget: budget,
            selectedCategoryId: selectedCategoryId,
            onCategoryTap: onCategoryTap,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (savings.isNotEmpty) ...[
          _ListGroup(
            label: 'Savings',
            categories: savings,
            budget: budget,
            selectedCategoryId: selectedCategoryId,
            onCategoryTap: onCategoryTap,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (investment.isNotEmpty)
          _ListGroup(
            label: 'Investments',
            categories: investment,
            budget: budget,
            selectedCategoryId: selectedCategoryId,
            onCategoryTap: onCategoryTap,
          ),
      ],
    );
  }
}

class _ListGroup extends StatelessWidget {
  final String label;
  final List<BudgetCategory> categories;
  final Budget budget;
  final String? selectedCategoryId;
  final void Function(String) onCategoryTap;

  const _ListGroup({
    required this.label,
    required this.categories,
    required this.budget,
    required this.selectedCategoryId,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _CategoryGroupLabel(label: label),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...categories.map(
          (cat) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            child: BudgetCategoryCard(
              category: cat,
              budgetType: budget.budgetType,
              isSelected: selectedCategoryId == cat.financeCategoryId,
              onTap: () => onCategoryTap(cat.financeCategoryId),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryGroupLabel extends StatelessWidget {
  final String label;

  const _CategoryGroupLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
