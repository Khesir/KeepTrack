import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';

class ProfileStartPlanningSheet extends StatefulWidget {
  final BudgetProfile targetProfile;
  final List<BudgetProfile> otherProfiles;
  final List<Budget> allBudgets;
  final BudgetController budgetController;
  final VoidCallback onPlanStarted;

  const ProfileStartPlanningSheet({
    super.key,
    required this.targetProfile,
    required this.otherProfiles,
    required this.allBudgets,
    required this.budgetController,
    required this.onPlanStarted,
  });

  static Future<void> show(
    BuildContext context, {
    required BudgetProfile targetProfile,
    required List<BudgetProfile> otherProfiles,
    required List<Budget> allBudgets,
    required BudgetController budgetController,
    required VoidCallback onPlanStarted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileStartPlanningSheet(
        targetProfile: targetProfile,
        otherProfiles: otherProfiles,
        allBudgets: allBudgets,
        budgetController: budgetController,
        onPlanStarted: onPlanStarted,
      ),
    );
  }

  @override
  State<ProfileStartPlanningSheet> createState() => _ProfileStartPlanningSheetState();
}

class _ProfileStartPlanningSheetState extends State<ProfileStartPlanningSheet> {
  bool _loading = false;

  Future<void> _copyFrom(BudgetProfile source) async {
    setState(() => _loading = true);
    try {
      final sourceBudgets = widget.allBudgets
          .where((b) => b.budgetProfileId == source.id && b.status == BudgetStatus.active)
          .toList();

      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      for (final src in sourceBudgets) {
        final created = await widget.budgetController.createBudget(Budget(
          month: monthKey,
          title: src.title,
          budgetType: src.budgetType,
          periodType: BudgetPeriodType.oneTime,
          status: BudgetStatus.active,
          budgetProfileId: widget.targetProfile.id,
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

      if (mounted) {
        Navigator.pop(context);
        widget.onPlanStarted();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startFresh() async {
    Navigator.pop(context);
    widget.onPlanStarted();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final profileColor = widget.targetProfile.colorHex != null
        ? Color(int.parse(widget.targetProfile.colorHex!.replaceFirst('#', '0xFF')))
        : AppColors.accent;

    final profilesWithBudgets = widget.otherProfiles.where((p) =>
      widget.allBudgets.any((b) => b.budgetProfileId == p.id && b.status == BudgetStatus.active)
    ).toList();

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: profileColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(widget.targetProfile.name, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 4),
            Text('Start Planning', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
          ]),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            if (profilesWithBudgets.isNotEmpty) ...[
              ...profilesWithBudgets.map((p) {
                final color = p.colorHex != null
                    ? Color(int.parse(p.colorHex!.replaceFirst('#', '0xFF')))
                    : AppColors.accent;
                final count = widget.allBudgets.where((b) => b.budgetProfileId == p.id && b.status == BudgetStatus.active).length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : () => _copyFrom(p),
                      icon: _loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.copy_outlined, size: 16),
                      label: Text('Copy from "${p.name}" ($count group${count == 1 ? '' : 's'})'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _startFresh,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Start Fresh'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
