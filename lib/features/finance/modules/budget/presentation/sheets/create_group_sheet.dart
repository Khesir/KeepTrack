import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../../../../shared/infrastructure/supabase/supabase_service.dart';
import '../controllers/budget_controller.dart';
import '../../../../presentation/state/month_plan_controller.dart';
import '../../domain/entities/budget.dart';

class CreateGroupSheet extends StatefulWidget {
  final String monthKey;
  final String monthLabel;
  final BudgetController budgetController;
  final MonthPlanController monthPlanController;
  final SupabaseService supabaseService;

  const CreateGroupSheet({
    required this.monthKey,
    required this.monthLabel,
    required this.budgetController,
    required this.monthPlanController,
    required this.supabaseService,
  });

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  late final TextEditingController _titleCtrl;
  BudgetType _budgetType = BudgetType.expense;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.monthLabel);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final created = await widget.budgetController.createBudget(
        Budget(
          month: widget.monthKey,
          title: _titleCtrl.text.trim().isEmpty
              ? widget.monthLabel
              : _titleCtrl.text.trim(),
          budgetType: _budgetType,
          periodType: BudgetPeriodType.monthly,
          status: BudgetStatus.active,
          userId: widget.supabaseService.userId,
        ),
      );
      // Link the new budget to the month plan so budgetIds stays in sync
      if (created.id != null) {
        await widget.monthPlanController.addBudgetToMonthPlan(
          widget.monthKey,
          created.id!,
        );
      }
      if (mounted) {
        // Capture messenger before closing the sheet so the snackbar
        // shows on the parent screen, not the dialog being dismissed.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Budget group created!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
            Text('New Budget Group', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              widget.monthLabel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Group name
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g., Housing, Food & Dining',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),

            // Income / Expense toggle
            Center(
              child: SegmentedButton<BudgetType>(
                segments: const [
                  ButtonSegment(
                    value: BudgetType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward, size: 14),
                  ),
                  ButtonSegment(
                    value: BudgetType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward, size: 14),
                  ),
                ],
                selected: {_budgetType},
                onSelectionChanged: (s) =>
                    setState(() => _budgetType = s.first),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
