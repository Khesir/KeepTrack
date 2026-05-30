import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/currency_formatter.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';

import '../controllers/budget_controller.dart';
import '../../../../presentation/state/month_plan_controller.dart';

class StartPlanningSheet extends StatefulWidget {
  final String monthKey;
  final String monthLabel;
  final String prevMonthKey;
  final String prevMonthLabel;
  final bool hasPrevBudgets;
  final String? budgetProfileId;
  final MonthPlanController monthPlanController;
  final BudgetController budgetController;

  const StartPlanningSheet({
    super.key,
    required this.monthKey,
    required this.monthLabel,
    required this.prevMonthKey,
    required this.prevMonthLabel,
    required this.hasPrevBudgets,
    this.budgetProfileId,
    required this.monthPlanController,
    required this.budgetController,
  });

  bool get _isProfileMode => budgetProfileId != null;

  @override
  State<StartPlanningSheet> createState() => _StartPlanningSheetState();
}

class _StartPlanningSheetState extends State<StartPlanningSheet> {
  bool _loading = false;

  double _calculateCarryOver() {
    final prevBudgets = (widget.budgetController.data ?? [])
        .where((b) =>
            b.month == widget.prevMonthKey &&
            (widget.budgetProfileId == null ||
                b.budgetProfileId == widget.budgetProfileId))
        .toList();
    final income = prevBudgets
        .where((b) => b.budgetType == BudgetType.income)
        .fold(0.0, (s, b) => s + b.budgetTarget);
    final expenses = prevBudgets
        .where((b) => b.budgetType == BudgetType.expense)
        .fold(0.0, (s, b) => s + b.budgetTarget);
    return income - expenses;
  }

  Future<void> _applyCarryOver(double amount) async {
    final userId = locator.get<AuthController>().currentUser?.id ?? '';
    final catCtrl = locator.get<FinanceCategoryController>();

    final categoryId = await catCtrl.findOrCreate(
      name: 'Carry Over',
      type: CategoryType.income,
      userId: userId,
    );
    if (categoryId == null) return;

    final created = await widget.budgetController.createBudget(Budget(
      month: widget.monthKey,
      title: 'Carry Over',
      budgetType: BudgetType.income,
      periodType: BudgetPeriodType.monthly,
      status: BudgetStatus.active,
      budgetProfileId: widget.budgetProfileId,
    ));

    await widget.budgetController.addCategory(
      created.id!,
      BudgetCategory(
        budgetId: created.id!,
        financeCategoryId: categoryId,
        targetAmount: amount,
      ),
    );

    // Only link to month plan for non-profile mode
    if (!widget._isProfileMode) {
      await widget.monthPlanController.addBudgetToMonthPlan(
        widget.monthKey,
        created.id!,
      );
    }
  }

  Future<void> _promptCarryOver() async {
    final carryOver = _calculateCarryOver();
    if (carryOver <= 0 || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Carry Over'),
        content: Text(
          'Your previous month had a remaining balance of ${formatCurrency(carryOver)}. '
          'Add it as carry-over income for ${widget.monthLabel}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add Carry Over'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _applyCarryOver(carryOver);
      await widget.budgetController.refreshBudgetsWithSpentAmounts();
    }
  }

  Future<void> _copyFromPrev() async {
    setState(() => _loading = true);
    try {
      if (widget._isProfileMode) {
        // Copy profile-scoped budgets from previous month
        final prevBudgets = (widget.budgetController.data ?? [])
            .where((b) =>
                b.budgetProfileId == widget.budgetProfileId &&
                b.month == widget.prevMonthKey &&
                b.status == BudgetStatus.active)
            .toList();
        for (final src in prevBudgets) {
          final created = await widget.budgetController.createBudget(Budget(
            month: widget.monthKey,
            title: src.title,
            budgetType: src.budgetType,
            periodType: src.periodType,
            status: BudgetStatus.active,
            budgetProfileId: widget.budgetProfileId,
          ));
          for (final cat in src.categories) {
            await widget.budgetController.addCategory(
              created.id!,
              BudgetCategory(
                budgetId: created.id!,
                financeCategoryId: cat.financeCategoryId,
                targetAmount: cat.targetAmount,
              ),
            );
          }
        }
        await widget.budgetController.refreshBudgetsWithSpentAmounts();
      } else {
        await widget.monthPlanController.copyMonthPlan(
          widget.prevMonthKey,
          widget.monthKey,
        );
        await widget.budgetController.refreshBudgetsWithSpentAmounts();
      }
      await _promptCarryOver();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to copy: $e')));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startFresh() async {
    setState(() => _loading = true);
    try {
      if (!widget._isProfileMode) {
        await widget.monthPlanController.getOrCreateMonthPlan(widget.monthKey);
        await widget.budgetController.refreshBudgetsWithSpentAmounts();
      }
      await _promptCarryOver();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Start Planning', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              widget.monthLabel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            if (widget.hasPrevBudgets) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _copyFromPrev,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.copy_outlined, size: 18),
                  label: Text(
                    _loading ? 'Copying…' : 'Copy from ${widget.prevMonthLabel}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _startFresh,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Start Fresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
