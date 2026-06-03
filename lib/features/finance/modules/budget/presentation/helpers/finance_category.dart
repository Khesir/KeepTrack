import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../finance_category/domain/entities/finance_category.dart';
import '../../../finance_category/domain/entities/finance_category_enums.dart';
import '../../domain/entities/budget.dart';

class CategoryGroup {
  final String name;
  final List<FinanceCategory> categories;
  const CategoryGroup(this.name, this.categories);
}

/// Builds grouped category list: one group per active budget in [monthKey],
/// then an "Other" group for any categories not assigned to a budget.
List<CategoryGroup> buildGroupedCategories({
  required List<FinanceCategory> allCategories,
  required List<Budget> allBudgets,
  required CategoryType targetType,
  required String monthKey,
}) {
  final targetBudgetType = targetType == CategoryType.income
      ? BudgetType.income
      : BudgetType.expense;

  final monthBudgets = allBudgets
      .where(
        (b) =>
            b.month == monthKey &&
            b.periodType == BudgetPeriodType.monthly &&
            b.status == BudgetStatus.active &&
            b.budgetType == targetBudgetType,
      )
      .toList();

  final typedCats = allCategories.where((c) => c.type == targetType).toList();
  final seenIds = <String>{};
  final groups = <CategoryGroup>[];

  for (final budget in monthBudgets) {
    final groupCats = <FinanceCategory>[];
    for (final bc in budget.categories) {
      final cat = typedCats.firstWhere(
        (c) => c.id == bc.financeCategoryId,
        orElse: () => FinanceCategory(name: '', type: targetType),
      );
      if (cat.id != null && !seenIds.contains(cat.id)) {
        groupCats.add(cat);
        seenIds.add(cat.id!);
      }
    }
    if (groupCats.isNotEmpty) {
      groups.add(CategoryGroup(budget.title ?? 'Untitled', groupCats));
    }
  }

  if (monthBudgets.isNotEmpty) {
    final others = typedCats
        .where((c) => c.id != null && !seenIds.contains(c.id))
        .toList();
    if (others.isNotEmpty) {
      groups.add(CategoryGroup('Other', others));
    }
  }

  // If no budgets exist, show all typed categories flat under one group.
  if (groups.isEmpty && typedCats.isNotEmpty) {
    groups.add(CategoryGroup('Categories', typedCats));
  }

  return groups;
}

/// Shows a grouped category picker as a bottom sheet.
/// Returns the selected [FinanceCategory] or null (cancelled).
Future<FinanceCategory?> showGroupedCategoryDialog(
  BuildContext context, {
  required List<CategoryGroup> groups,
  required String? selectedId,
}) {
  return showModalBottomSheet<FinanceCategory>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoryPickerSheet(
      groups: groups,
      selectedId: selectedId,
    ),
  );
}

class _CategoryPickerSheet extends StatefulWidget {
  final List<CategoryGroup> groups;
  final String? selectedId;

  const _CategoryPickerSheet({required this.groups, required this.selectedId});

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CategoryGroup> get _filtered {
    if (_query.isEmpty) return widget.groups;
    final q = _query.toLowerCase();
    return widget.groups
        .map((g) => CategoryGroup(
              g.name,
              g.categories
                  .where((c) => c.name.toLowerCase().contains(q))
                  .toList(),
            ))
        .where((g) => g.categories.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.void_ : Colors.white;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.15)
        : AppColors.border.withValues(alpha: 0.4);
    final textPrimary =
        isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final filtered = _filtered;
    final totalCount =
        filtered.fold(0, (s, g) => s + g.categories.length);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(
                child: Text(
                  'Select Category',
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textSecondary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search categories…',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 14, color: AppColors.textTertiary),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: AppColors.textTertiary),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          child: Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textTertiary),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: borderColor),

          // List
          Expanded(
            child: totalCount == 0
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_outlined,
                            size: 40, color: AppColors.textTertiary),
                        const SizedBox(height: 10),
                        Text(
                          _query.isEmpty
                              ? 'No categories available'
                              : 'No results for "$_query"',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _itemCount(filtered),
                    itemBuilder: (_, i) =>
                        _buildItem(i, filtered, isDark, borderColor, textPrimary),
                  ),
          ),
        ]),
      ),
    );
  }

  // Flat index over [group header + items] structure
  int _itemCount(List<CategoryGroup> groups) =>
      groups.fold(0, (s, g) => s + 1 + g.categories.length);

  Widget _buildItem(int index, List<CategoryGroup> groups, bool isDark,
      Color borderColor, Color textPrimary) {
    var cursor = 0;
    for (final group in groups) {
      if (index == cursor) return _GroupHeader(name: group.name, isDark: isDark);
      cursor++;
      for (final cat in group.categories) {
        if (index == cursor) {
          return _CategoryTile(
            category: cat,
            selected: widget.selectedId == cat.id,
            isDark: isDark,
            borderColor: borderColor,
            textPrimary: textPrimary,
            onTap: () => Navigator.pop(context, cat),
          );
        }
        cursor++;
      }
    }
    return const SizedBox.shrink();
  }
}

class _GroupHeader extends StatelessWidget {
  final String name;
  final bool isDark;

  const _GroupHeader({required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
        child: Text(
          name.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
            letterSpacing: 1.1,
          ),
        ),
      );
}

class _CategoryTile extends StatelessWidget {
  final FinanceCategory category;
  final bool selected;
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.onTap,
  });

  Color get _iconColor => category.type.color;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _iconColor.withValues(alpha: isDark ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _iconColor.withValues(alpha: 0.35)
                  : borderColor,
              width: selected ? 1 : 0.5,
            ),
          ),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(category.type.icon, size: 16, color: _iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? _iconColor : textPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  size: 18, color: _iconColor),
          ]),
        ),
      );
}
