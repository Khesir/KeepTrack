import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import '../helpers/linked_category_display.dart';
import '../sheets/sheet_helpers.dart';
import '../widgets/detail_sheet_widgets.dart';

class CategoryDetailSheet extends StatelessWidget {
  final Budget group;
  final BudgetCategory cat;
  final double spent;
  final VoidCallback? onEdit;

  const CategoryDetailSheet({super.key, required this.group, required this.cat, required this.spent, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = group.budgetType == BudgetType.income;
    final color = isIncome ? AppColors.success : AppColors.accent;
    final planned = cat.targetAmount;
    final over = planned > 0 && spent > planned;
    final progress = planned > 0 ? (spent / planned).clamp(0.0, 1.0) : 0.0;
    final progressColor = over ? AppColors.error : color;
    final display = resolveLinkedCategoryDisplay(cat);

    return CompactFrame(
      isDark: isDark,
      title: display.name,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (display.statusLabel != null) ...[
          StatusPill(text: display.statusLabel!, color: display.statusColor ?? AppColors.textTertiary),
          const SizedBox(width: 6),
        ],
        StatusPill(text: group.title ?? (isIncome ? 'Income' : 'Expenses'), color: color),
      ]),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Spent', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                Text(currencyFormatter.format(spent, decimalDigits: 2),
                    style: GoogleFonts.dmMono(fontSize: 22, fontWeight: FontWeight.w700, color: over ? AppColors.error : (isDark ? AppColors.primaryForeground : AppColors.textPrimary), fontFeatures: const [FontFeature.tabularFigures()])),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Planned', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                Text(currencyFormatter.format(planned, decimalDigits: 2),
                    style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
            ]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border, valueColor: AlwaysStoppedAnimation<Color>(progressColor))),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${(progress * 100).round()}% used', style: GoogleFonts.dmSans(fontSize: 10, color: over ? AppColors.error : AppColors.textSecondary)),
              Text(over ? 'Over by ${currencyFormatter.format(spent - planned, decimalDigits: 2)}' : '${currencyFormatter.format(planned - spent, decimalDigits: 2)} remaining',
                  style: GoogleFonts.dmSans(fontSize: 10, color: over ? AppColors.error : AppColors.textSecondary)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        SheetActionButton(label: 'Edit Category', icon: Icons.edit_outlined, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary, outlined: true, onTap: onEdit, isDark: isDark),
      ]),
    );
  }
}
