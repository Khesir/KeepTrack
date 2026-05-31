import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';

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

  Future<void> _copyFromPrev() async {
    setState(() => _loading = true);
    try {
      if (widget._isProfileMode) {
        final plan = widget.budgetProfileId != null
            ? await widget.monthPlanController.getOrCreateMonthPlanForMonthlyProfile(
                widget.monthKey, widget.budgetProfileId!)
            : null;
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
                financeCategory: cat.financeCategory,
              ),
            );
          }
          if (plan?.id != null && created.id != null) {
            await widget.monthPlanController.addBudgetToPlanById(plan!.id!, created.id!);
          }
        }
        await widget.budgetController.refreshBudgetsWithSpentAmounts();
      } else {
        await widget.monthPlanController.copyMonthPlan(widget.prevMonthKey, widget.monthKey);
        await widget.budgetController.refreshBudgetsWithSpentAmounts();
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to copy: $e');
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startFresh() async {
    setState(() => _loading = true);
    try {
      if (widget.budgetProfileId != null) {
        await widget.monthPlanController.getOrCreateMonthPlanForMonthlyProfile(
            widget.monthKey, widget.budgetProfileId!);
      } else {
        await widget.monthPlanController.getOrCreateMonthPlan(widget.monthKey);
      }
      await widget.budgetController.refreshBudgetsWithSpentAmounts();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month_rounded, size: 22, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Start Planning',
                    style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                Text(widget.monthLabel,
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              if (widget.hasPrevBudgets) ...[
                _OptionCard(
                  isDark: isDark,
                  icon: Icons.copy_all_rounded,
                  label: 'Copy from ${widget.prevMonthLabel}',
                  sublabel: 'Duplicate all budget groups and categories',
                  isPrimary: true,
                  loading: _loading,
                  onTap: _loading ? null : _copyFromPrev,
                ),
                const SizedBox(height: 10),
              ],
              _OptionCard(
                isDark: isDark,
                icon: Icons.add_circle_outline_rounded,
                label: 'Start Fresh',
                sublabel: 'Create a new empty budget for this month',
                isPrimary: !widget.hasPrevBudgets,
                loading: false,
                onTap: _loading ? null : _startFresh,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isPrimary;
  final bool loading;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isPrimary,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary
        ? AppColors.accent
        : (isDark ? const Color(0xFF2C2C2A) : AppColors.background);
    final border = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final labelColor = isPrimary ? Colors.white : (isDark ? AppColors.primaryForeground : AppColors.textPrimary);
    final subColor = isPrimary ? Colors.white.withValues(alpha: 0.75) : AppColors.textSecondary;
    final iconColor = isPrimary ? Colors.white : AppColors.accent;
    final iconBg = isPrimary
        ? Colors.white.withValues(alpha: 0.15)
        : AppColors.accent.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: isPrimary ? null : Border.all(color: border, width: 0.5),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: loading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor)),
              const SizedBox(height: 2),
              Text(sublabel, style: GoogleFonts.dmSans(fontSize: 12, color: subColor)),
            ])),
            Icon(Icons.chevron_right_rounded, size: 18,
                color: isPrimary ? Colors.white.withValues(alpha: 0.7) : AppColors.textTertiary),
          ]),
        ),
      ),
    );
  }
}
