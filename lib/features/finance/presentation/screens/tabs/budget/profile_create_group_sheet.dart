import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';

class ProfileCreateGroupSheet extends StatefulWidget {
  final BudgetProfile profile;
  final bool isIncome;
  final BudgetController budgetController;
  final MonthPlanController monthPlanController;
  final VoidCallback onCreated;

  const ProfileCreateGroupSheet({
    super.key,
    required this.profile,
    required this.isIncome,
    required this.budgetController,
    required this.monthPlanController,
    required this.onCreated,
  });

  @override
  State<ProfileCreateGroupSheet> createState() => _ProfileCreateGroupSheetState();
}

class _ProfileCreateGroupSheetState extends State<ProfileCreateGroupSheet> {
  late final TextEditingController _titleCtrl;
  late BudgetType _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.isIncome ? BudgetType.income : BudgetType.expense;
    _titleCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final created = await widget.budgetController.createBudget(
        Budget(
          month: month,
          title: title,
          budgetType: _type,
          periodType: widget.profile.isMonthly ? BudgetPeriodType.monthly : BudgetPeriodType.oneTime,
          status: BudgetStatus.active,
          budgetProfileId: widget.profile.id,
        ),
      );
      // Register this budget in the profile's MonthPlan
      if (created.id != null) {
        final plans = widget.monthPlanController.data ?? [];
        final plan = plans.cast<MonthPlan?>().firstWhere(
          (p) => p?.budgetProfileId == widget.profile.id, orElse: () => null);
        if (plan?.id != null) {
          await widget.monthPlanController.addBudgetToPlanById(plan!.id!, created.id!);
        }
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? const Color(0xFF1E1E1C) : AppColors.surface;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final profileColor = widget.profile.colorHex != null
        ? Color(int.parse(widget.profile.colorHex!.replaceFirst('#', '0xFF')))
        : AppColors.accent;

    return Container(
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: profileColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(widget.profile.name, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 6),
          Text('New Budget Group', style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g., Salary, Housing, Travel',
              hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.accent, width: 1.5)),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 14),
          Center(
            child: SegmentedButton<BudgetType>(
              segments: const [
                ButtonSegment(value: BudgetType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_upward, size: 14)),
                ButtonSegment(value: BudgetType.income, label: Text('Income'), icon: Icon(Icons.arrow_downward, size: 14)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Create Group', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
