import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart'
    show FinanceCategory;
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import '../../../../../../core/state/stream_state.dart';
import '../../../../presentation/state/finance_category_controller.dart';
import '../../../finance_category/domain/entities/finance_category_enums.dart';
import '../../domain/entities/budget.dart';
import 'entity_link_picker_sheet.dart';
import 'sheet_chip.dart';
import 'sheet_helpers.dart';

enum _CategoryEntryMode { category, link }

/// The fixed per-type default `FinanceCategory` name a linked category
/// resolves to (find-or-create) — shared with [EditCategorySheet] so both
/// sheets can never disagree on how a link's category bucket is named.
String defaultLinkedCategoryName(String type) => switch (type) {
  'subscription' => 'Subscriptions',
  'debt_payment' => 'Debt',
  'lending' => 'Receivables',
  'goal' => 'Goals',
  _ => 'Category',
};

class AddCategorySheet extends StatefulWidget {
  final Budget group;
  final FinanceCategoryController categoryController;
  final Future<void> Function(BudgetCategory) onSave;

  /// Subscription/Debt/Goal ids already linked to a category elsewhere in the
  /// current month/budget snapshot — excluded from the "Link" entity picker
  /// so the same entity can never be linked twice at once. See CONTEXT.md
  /// ("Link uniqueness").
  final Set<String> alreadyLinkedIds;

  const AddCategorySheet({
    super.key,
    required this.group,
    required this.categoryController,
    required this.onSave,
    this.alreadyLinkedIds = const {},
  });

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  _CategoryEntryMode _mode = _CategoryEntryMode.category;
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  // Link mode selection state.
  String? _linkedType; // EntitySelection.type: subscription/debt_payment/lending/goal
  String? _linkedLabel;
  String? _linkedSubscriptionId;
  String? _linkedDebtId;
  String? _linkedGoalId;

  bool get _isIncome => widget.group.budgetType == BudgetType.income;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _pickLink(bool isDark) {
    EntityLinkPickerSheet.showTypePicker(
      context,
      isDark: isDark,
      linkedLabel: _linkedLabel,
      selectedId: _linkedSubscriptionId ?? _linkedDebtId ?? _linkedGoalId,
      isIncome: _isIncome,
      excludeIds: widget.alreadyLinkedIds,
      onRemoveLink: () => setState(() {
        _linkedType = null;
        _linkedLabel = null;
        _linkedSubscriptionId = null;
        _linkedDebtId = null;
        _linkedGoalId = null;
      }),
      onSelect: (sel) {
        setState(() {
          _linkedType = sel.type;
          _linkedLabel = sel.label;
          _linkedSubscriptionId = sel.subscriptionId;
          _linkedDebtId = sel.debtId;
          _linkedGoalId = sel.goalId;
        });
        final amount = _resolveEntityAmount(sel);
        if (amount != null) {
          _amountCtrl.text = amount.toStringAsFixed(2);
        }
      },
    );
  }

  /// Auto-fills the planned amount from the linked entity's own recurring
  /// amount at link time — stays freely editable afterward. See CONTEXT.md.
  double? _resolveEntityAmount(EntitySelection sel) {
    switch (sel.type) {
      case 'subscription':
        final sub = (locator.get<SubscriptionController>().data ?? [])
            .where((s) => s.id == sel.subscriptionId)
            .firstOrNull;
        return sub?.amount;
      case 'debt_payment':
      case 'lending':
        final debt = (locator.get<DebtController>().data ?? [])
            .where((d) => d.id == sel.debtId)
            .firstOrNull;
        return debt?.monthlyPaymentAmount;
      case 'goal':
        final goal = (locator.get<GoalController>().data ?? [])
            .where((g) => g.id == sel.goalId)
            .firstOrNull;
        return goal?.monthlyContribution;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final isIncome = _isIncome;
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
                    Row(children: [
                      SheetChip(
                        icon: Icons.label_outline_rounded,
                        label: 'Category',
                        active: _mode == _CategoryEntryMode.category,
                        isDark: isDark,
                        onTap: () => setState(() => _mode = _CategoryEntryMode.category),
                      ),
                      const SizedBox(width: 8),
                      SheetChip(
                        icon: Icons.link_rounded,
                        label: 'Link',
                        active: _mode == _CategoryEntryMode.link,
                        isDark: isDark,
                        onTap: () => setState(() => _mode = _CategoryEntryMode.link),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    if (_mode == _CategoryEntryMode.category) ...[
                      SheetLabel('CATEGORY NAME'),
                      SheetField(
                        ctrl: _nameCtrl,
                        hint: 'e.g. Groceries, Netflix, Salary',
                        isDark: isDark,
                        autofocus: true,
                        capitalize: true,
                      ),
                    ] else ...[
                      SheetLabel(isIncome ? 'LINKED RECEIVABLE' : 'LINKED ITEM'),
                      SheetPickerField(
                        icon: _linkedType != null ? EntityLinkPickerSheet.entityIcon(_linkedType!) : Icons.link_rounded,
                        label: _linkedLabel ?? (isIncome ? 'Select a receivable' : 'Select a subscription, debt, or goal'),
                        hasValue: _linkedLabel != null,
                        border: borderColor,
                        textPrimary: textPrimary,
                        onTap: () => _pickLink(isDark),
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
    if (_mode == _CategoryEntryMode.category) {
      await _saveCategory();
    } else {
      await _saveLink();
    }
  }

  Future<void> _saveCategory() async {
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

      final created = await _findOrCreateFinanceCategory(name: name, type: catType);

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

  Future<void> _saveLink() async {
    final type = _linkedType;
    if (type == null) {
      AppToast.error(context, 'Select an item to link');
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
      final created = await _findOrCreateFinanceCategory(
        name: defaultLinkedCategoryName(type),
        type: catType,
      );

      await widget.onSave(BudgetCategory(
        budgetId: budgetId,
        financeCategoryId: created.id ?? '',
        targetAmount: amount,
        financeCategory: created,
        subscriptionId: _linkedSubscriptionId,
        debtId: _linkedDebtId,
        goalId: _linkedGoalId,
        linkedEntityLabel: _linkedLabel,
      ));
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
}
