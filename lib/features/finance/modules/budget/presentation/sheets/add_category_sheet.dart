import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart'
    show FinanceCategory;
import '../../../../../../core/state/stream_state.dart';
import '../../../../presentation/state/finance_category_controller.dart';
import '../../../finance_category/domain/entities/finance_category_enums.dart';
import '../../domain/entities/budget.dart';
import 'sheet_helpers.dart';

class AddCategorySheet extends StatefulWidget {
  final Budget group;
  final FinanceCategoryController categoryController;
  final Future<void> Function(BudgetCategory) onSave;

  const AddCategorySheet({
    super.key,
    required this.group,
    required this.categoryController,
    required this.onSave,
  });

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _saving = false;

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
                        'Add Category',
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
                      hint: 'e.g. Groceries, Netflix, Salary',
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
                            : const Icon(Icons.add_rounded, size: 15),
                        label: Text(_saving ? 'Adding…' : 'Add Category'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: AppColors.textPrimaryDark,
                          elevation: 0,
                          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
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
    if (name.isEmpty) {
      AppToast.error(context, 'Enter a category name');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount < 0) {
      AppToast.error(context, 'Enter a valid amount');
      return;
    }
    final budgetId = widget.group.id;
    if (budgetId == null) return;

    setState(() => _saving = true);
    try {
      final catType = widget.group.budgetType == BudgetType.income ? CategoryType.income : CategoryType.expense;

      final currentState = widget.categoryController.state;
      final currentCats = currentState is AsyncData<List<FinanceCategory>> ? currentState.data : <FinanceCategory>[];
      final existing = currentCats
          .where((c) => c.name.toLowerCase() == name.toLowerCase() && c.type == catType)
          .firstOrNull;

      FinanceCategory created;
      if (existing != null) {
        created = existing;
      } else {
        await widget.categoryController.createCategory(FinanceCategory(name: name, type: catType));
        final updatedState = widget.categoryController.state;
        final updatedCats = updatedState is AsyncData<List<FinanceCategory>> ? updatedState.data : <FinanceCategory>[];
        created = updatedCats.firstWhere(
          (c) => c.name.toLowerCase() == name.toLowerCase() && c.type == catType,
          orElse: () => FinanceCategory(name: name, type: catType),
        );
      }

      await widget.onSave(BudgetCategory(
        budgetId: budgetId,
        financeCategoryId: created.id ?? '',
        targetAmount: amount,
        financeCategory: created,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: $e');
        setState(() => _saving = false);
      }
    }
  }
}
