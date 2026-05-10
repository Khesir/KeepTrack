import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../../../../shared/infrastructure/supabase/supabase_service.dart';
import '../../../../presentation/state/budget_controller.dart';
import '../../../../presentation/state/month_plan_controller.dart';
import '../screens/create_group_sheet.dart';

class StartPlanningSheet extends StatefulWidget {
  final String monthKey;
  final String monthLabel;
  final String prevMonthKey;
  final String prevMonthLabel;
  final bool hasPrevBudgets;
  final MonthPlanController monthPlanController;
  final BudgetController budgetController;
  final SupabaseService supabaseService;

  const StartPlanningSheet({
    required this.monthKey,
    required this.monthLabel,
    required this.prevMonthKey,
    required this.prevMonthLabel,
    required this.hasPrevBudgets,
    required this.monthPlanController,
    required this.budgetController,
    required this.supabaseService,
  });

  @override
  State<StartPlanningSheet> createState() => _StartPlanningSheetState();
}

class _StartPlanningSheetState extends State<StartPlanningSheet> {
  bool _loading = false;

  Future<void> _copyFromPrev() async {
    setState(() => _loading = true);
    try {
      await widget.monthPlanController.copyMonthPlan(
        widget.prevMonthKey,
        widget.monthKey,
      );
      // Refresh budget list so the new budgets appear immediately
      await widget.budgetController.refreshBudgetsWithSpentAmounts();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to copy: $e')));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startFresh() async {
    Navigator.pop(context);
    // Ensure a MonthPlan record exists for this month before creating budget groups
    try {
      await widget.monthPlanController.getOrCreateMonthPlan(widget.monthKey);
    } catch (_) {
      // Non-blocking: proceed to budget creation even if month plan creation fails
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateGroupSheet(
        monthKey: widget.monthKey,
        monthLabel: widget.monthLabel,
        budgetController: widget.budgetController,
        monthPlanController: widget.monthPlanController,
        supabaseService: widget.supabaseService,
      ),
    );
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
            // Handle
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
              // Copy option
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
                    _loading
                        ? 'Copying…'
                        : 'Copy from ${widget.prevMonthLabel}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Start fresh option
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
