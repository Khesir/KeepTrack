import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart'
    show FinanceCategory;
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';

import '../../../../../../core/state/stream_state.dart';
import '../controllers/budget_controller.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import '../../../finance_category/domain/entities/finance_category_enums.dart';
import 'add_category_sheet.dart' show defaultLinkedCategoryName;
import 'entity_link_picker_sheet.dart';
import 'sheet_helpers.dart';

class EditCategorySheet extends StatefulWidget {
  final Budget group;
  final BudgetCategory category;
  final FinanceCategoryController categoryController;
  final BudgetController budgetController;
  final VoidCallback? onDelete;

  /// Subscription/Debt/Goal ids already linked to a category elsewhere in the
  /// current month/budget snapshot — excluded from the "Change link" entity
  /// picker, same as `AddCategorySheet`. See CONTEXT.md ("Link uniqueness").
  final Set<String> alreadyLinkedIds;

  const EditCategorySheet({
    super.key,
    required this.group,
    required this.category,
    required this.categoryController,
    required this.budgetController,
    this.onDelete,
    this.alreadyLinkedIds = const {},
  });

  @override
  State<EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<EditCategorySheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  bool _saving = false;

  // Link state — initialized from widget.category, mutable via "Change link"
  // (EntityLinkPickerSheet.showTypePicker) and "Unlink".
  late bool _isLinked;
  String? _linkedType; // EntitySelection.type: subscription/debt_payment/lending/goal
  String? _linkedLabel;
  String? _linkedSubscriptionId;
  String? _linkedDebtId;
  String? _linkedGoalId;

  bool get _isIncome => widget.group.budgetType == BudgetType.income;

  /// `BudgetCategory.linkedEntityType` can't tell a borrowing Debt from a
  /// lending Debt (Receivable) apart on its own (see issue 001's Flagged
  /// note) — but this category's group `BudgetType` already disambiguates
  /// it: an Income group only ever holds lending (Receivable) links, an
  /// Expense group only ever holds borrowing (debt_payment) links, enforced
  /// by the entity picker itself. So no live `Debt` lookup is needed here.
  String? _deriveLinkedType(BudgetCategory cat) {
    if (cat.subscriptionId != null) return 'subscription';
    if (cat.debtId != null) return _isIncome ? 'lending' : 'debt_payment';
    if (cat.goalId != null) return 'goal';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category.financeCategory?.name ?? '');
    _amountCtrl = TextEditingController(text: widget.category.targetAmount.toStringAsFixed(2));
    _isLinked = widget.category.isLinked;
    _linkedType = _deriveLinkedType(widget.category);
    _linkedLabel = widget.category.linkedEntityLabel;
    _linkedSubscriptionId = widget.category.subscriptionId;
    _linkedDebtId = widget.category.debtId;
    _linkedGoalId = widget.category.goalId;
  }

  void _pickLink(bool isDark) {
    EntityLinkPickerSheet.showTypePicker(
      context,
      isDark: isDark,
      linkedLabel: _linkedLabel,
      selectedId: _linkedSubscriptionId ?? _linkedDebtId ?? _linkedGoalId,
      isIncome: _isIncome,
      excludeIds: widget.alreadyLinkedIds,
      onRemoveLink: _doUnlink,
      onSelect: (sel) {
        // "Change link" does not auto-refill the amount — the user may have
        // deliberately adjusted it. See CONTEXT.md ("Editing a link").
        setState(() {
          _isLinked = true;
          _linkedType = sel.type;
          _linkedLabel = sel.label;
          _linkedSubscriptionId = sel.subscriptionId;
          _linkedDebtId = sel.debtId;
          _linkedGoalId = sel.goalId;
        });
      },
    );
  }

  /// Drops the Category Link, falling back to a plain category — the name
  /// field is cleared so the user is prompted to give it a real,
  /// user-chosen name (the field's own emptiness plus the existing "Enter a
  /// category name" validation on save is the prompt). See CONTEXT.md
  /// ("Editing a link").
  void _doUnlink() {
    setState(() {
      _isLinked = false;
      _linkedType = null;
      _linkedLabel = null;
      _linkedSubscriptionId = null;
      _linkedDebtId = null;
      _linkedGoalId = null;
      _nameCtrl.text = '';
    });
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
                    if (_isLinked) ...[
                      SheetLabel(_isIncome ? 'LINKED RECEIVABLE' : 'LINKED ITEM'),
                      SheetPickerField(
                        icon: _linkedType != null ? EntityLinkPickerSheet.entityIcon(_linkedType!) : Icons.link_rounded,
                        label: _linkedLabel ?? 'Select an item',
                        hasValue: _linkedLabel != null,
                        border: borderColor,
                        textPrimary: textPrimary,
                        onTap: () => _pickLink(isDark),
                        trailing: GestureDetector(
                          onTap: _doUnlink,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.link_off_rounded, size: 16, color: AppColors.error),
                          ),
                        ),
                      ),
                    ] else ...[
                      SheetLabel('CATEGORY NAME'),
                      SheetField(
                        ctrl: _nameCtrl,
                        hint: 'Category name',
                        isDark: isDark,
                        autofocus: true,
                        capitalize: true,
                      ),
                    ],
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
    if (_isLinked) {
      await _saveLinked();
    } else if (widget.category.isLinked) {
      // Was linked when the sheet opened, user hit "Unlink" this session.
      await _saveUnlinked();
    } else {
      // Was never linked — exact pre-existing plain-category save behavior.
      await _savePlain();
    }
  }

  Future<void> _saveLinked() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount < 0) {
      AppToast.error(context, 'Enter a valid amount');
      return;
    }
    final type = _linkedType;
    if (type == null) {
      AppToast.error(context, 'Select an item to link');
      return;
    }
    setState(() => _saving = true);
    try {
      final catType = _isIncome ? CategoryType.income : CategoryType.expense;
      final created = await _findOrCreateFinanceCategory(
        name: defaultLinkedCategoryName(type),
        type: catType,
      );
      await widget.budgetController.updateCategory(
        widget.group.id!,
        BudgetCategory(
          id: widget.category.id,
          budgetId: widget.category.budgetId,
          financeCategoryId: created.id ?? '',
          userId: widget.category.userId,
          targetAmount: amount,
          spentAmount: widget.category.spentAmount,
          feeSpent: widget.category.feeSpent,
          financeCategory: created,
          createdAt: widget.category.createdAt,
          updatedAt: widget.category.updatedAt,
          subscriptionId: _linkedSubscriptionId,
          debtId: _linkedDebtId,
          goalId: _linkedGoalId,
          linkedEntityLabel: _linkedLabel,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: $e');
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveUnlinked() async {
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
      final catType = _isIncome ? CategoryType.income : CategoryType.expense;
      final created = await _findOrCreateFinanceCategory(name: name, type: catType);
      await widget.budgetController.updateCategory(
        widget.group.id!,
        BudgetCategory(
          id: widget.category.id,
          budgetId: widget.category.budgetId,
          financeCategoryId: created.id ?? '',
          userId: widget.category.userId,
          targetAmount: amount,
          spentAmount: widget.category.spentAmount,
          feeSpent: widget.category.feeSpent,
          financeCategory: created,
          createdAt: widget.category.createdAt,
          updatedAt: widget.category.updatedAt,
          // subscriptionId/debtId/goalId/linkedEntityLabel intentionally
          // omitted (null) — this is the whole point of "Unlink".
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: $e');
        setState(() => _saving = false);
      }
    }
  }

  Future<FinanceCategory> _findOrCreateFinanceCategory({
    required String name,
    required CategoryType type,
  }) async {
    final currentState = widget.categoryController.state;
    final currentCats = currentState is AsyncData<List<FinanceCategory>> ? currentState.data : <FinanceCategory>[];
    final existing = currentCats
        .where((c) => c.name.toLowerCase() == name.toLowerCase() && c.type == type)
        .firstOrNull;
    if (existing != null) return existing;

    await widget.categoryController.createCategory(FinanceCategory(name: name, type: type));
    final updatedState = widget.categoryController.state;
    final updatedCats = updatedState is AsyncData<List<FinanceCategory>> ? updatedState.data : <FinanceCategory>[];
    return updatedCats.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase() && c.type == type,
      orElse: () => FinanceCategory(name: name, type: type),
    );
  }

  Future<void> _savePlain() async {
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
