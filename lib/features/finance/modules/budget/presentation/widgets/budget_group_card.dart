import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import 'category_row.dart';

class BudgetGroupCard extends StatelessWidget {
  final Budget group;
  final String monthLabel;
  final bool isSelected;
  final Map<String, double> spentByCategory;
  final VoidCallback onSelect;
  final VoidCallback onEditGroup;
  final VoidCallback onAddRow;
  final void Function(BudgetCategory) onCategoryDetailTap;
  final void Function(BudgetCategory) onCategoryEditTap;
  final Future<void> Function(BudgetCategory, double) onUpdateAmount;
  final Future<void> Function(BudgetCategory, double)? onCategoryPay;
  final int? dragIndex;

  const BudgetGroupCard({
    super.key,
    required this.group,
    required this.monthLabel,
    required this.isSelected,
    required this.spentByCategory,
    required this.onSelect,
    required this.onEditGroup,
    required this.onAddRow,
    required this.onCategoryDetailTap,
    required this.onCategoryEditTap,
    required this.onUpdateAmount,
    this.onCategoryPay,
    this.dragIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = group.budgetType == BudgetType.income;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final cardColor = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = AppColors.border.withValues(alpha: isDark ? 0.15 : 0.4);
    final groupColor = isIncome ? AppColors.success : AppColors.accent;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group header row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Group title + collapse toggle
                Expanded(
                  child: GestureDetector(
                    onTap: onSelect,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            group.title ?? monthLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? groupColor : textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: isSelected ? 0 : 0.5,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: Icon(Icons.keyboard_arrow_up_rounded, size: 17, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),

                // "Planned" column label — aligns with CategoryRow planned field
                SizedBox(
                  width: 80,
                  child: Text(
                    'Planned',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),

                // "Spent" column label — aligns with CategoryRow actual field
                SizedBox(
                  width: 72,
                  child: Text(
                    'Spent',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),

                // Edit + drag — after Spent, matching CategoryRow's optional Pay position
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onEditGroup,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(Icons.edit_outlined, size: 14, color: AppColors.textTertiary),
                  ),
                ),
                if (dragIndex != null)
                  ReorderableDragStartListener(
                    index: dragIndex!,
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Icon(Icons.drag_handle, size: 16, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // ── Category rows ─────────────────────────────────────────────
          for (int i = 0; i < group.categories.length; i++) ...[
            TweenAnimationBuilder<double>(
              key: ValueKey(group.categories[i].id ?? group.categories[i].financeCategoryId),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Interval((i * 0.12).clamp(0.0, 0.7), (i * 0.12 + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(offset: Offset(0, (1 - v) * 6), child: child),
              ),
              child: CategoryRow(
                category: group.categories[i],
                spentAmount: spentByCategory[group.categories[i].financeCategoryId] ?? 0.0,
                isIncomeGroup: isIncome,
                accentColor: groupColor,
                onDetailTap: () => onCategoryDetailTap(group.categories[i]),
                onEditTap: () => onCategoryEditTap(group.categories[i]),
                onUpdateAmount: (amount) => onUpdateAmount(group.categories[i], amount),
                onPay: onCategoryPay != null ? (amount) => onCategoryPay!(group.categories[i], amount) : null,
              ),
            ),
            Divider(height: 1, color: borderColor),
          ],

          // ── Add Item — plain accent text link (Every Dollar style) ─────
          GestureDetector(
            onTap: onAddRow,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Text(
                'Add Item',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: groupColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
