import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';

import '../controllers/budget_controller.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import 'sheet_helpers.dart';

class EditCategorySheet extends StatefulWidget {
  final Budget group;
  final BudgetCategory category;
  final FinanceCategoryController categoryController;
  final BudgetController budgetController;
  final VoidCallback? onDelete;

  const EditCategorySheet({
    super.key,
    required this.group,
    required this.category,
    required this.categoryController,
    required this.budgetController,
    this.onDelete,
  });

  @override
  State<EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<EditCategorySheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category.financeCategory?.name ?? '');
    _amountCtrl = TextEditingController(text: widget.category.targetAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final isIncome = widget.group.budgetType == BudgetType.income;
    final accentColor = isIncome ? AppColors.success : AppColors.accent;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        'Edit Category',
                        style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      if ((widget.group.title ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.group.title!,
                          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isIncome ? 'Income' : 'Expense',
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ]),
              ),
              Divider(height: 24, color: borderColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SheetLabel('CATEGORY NAME'),
                    SheetField(
                      ctrl: _nameCtrl,
                      hint: 'Category name',
                      isDark: isDark,
                      autofocus: true,
                      capitalize: true,
                    ),
                    const SizedBox(height: 16),
                    SheetLabel('PLANNED AMOUNT'),
                    SheetField(
                      ctrl: _amountCtrl,
                      hint: '0.00',
                      prefix: '${currencyFormatter.currencySymbol} ',
                      isDark: isDark,
                      numeric: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded, size: 15),
                        label: Text(_saving ? 'Saving…' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: AppColors.textPrimaryDark,
                          elevation: 0,
                          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (widget.onDelete != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : widget.onDelete,
                          icon: const Icon(Icons.delete_outline_rounded, size: 15),
                          label: const Text('Delete Category'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                            textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (name.isEmpty) {
      AppToast.error(context, 'Enter a category name');
      return;
    }
    if (amount == null || amount < 0) {
      AppToast.error(context, 'Enter a valid amount');
      return;
    }
    setState(() => _saving = true);
    try {
      final fc = widget.category.financeCategory;
      if (fc != null && fc.name != name) {
        await widget.categoryController.updateCategory(fc.copyWith(name: name));
        await widget.budgetController.loadBudgetsWithSpentAmounts();
      }
      if (amount != widget.category.targetAmount) {
        await widget.budgetController.updateCategory(
          widget.group.id!,
          widget.category.copyWith(targetAmount: amount),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: $e');
        setState(() => _saving = false);
      }
    }
  }
}
