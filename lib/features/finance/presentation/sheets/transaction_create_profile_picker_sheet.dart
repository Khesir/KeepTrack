import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';

class TransactionCreateProfilePickerSheet extends StatelessWidget {
  final bool isDark;
  final List<BudgetProfile> profiles;
  final List<MonthPlan> plans;
  final String? selectedProfileId;
  final String? selectedPlanMonth;
  final void Function(String? profileId, String? profileName, String? planMonth)
  onSelect;

  const TransactionCreateProfilePickerSheet({
    super.key,
    required this.isDark,
    required this.profiles,
    required this.plans,
    required this.selectedProfileId,
    required this.selectedPlanMonth,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    // Build picker items: monthly profiles → one entry per open plan; custom → one entry per profile
    final items = <({String label, String profileId, String? planMonth})>[];
    for (final p in profiles) {
      if (!p.isActive) continue;
      if (p.isMonthly) {
        final profilePlans =
            plans
                .where(
                  (pl) =>
                      pl.budgetProfileId == p.id &&
                      !pl.isClosed &&
                      pl.month != null,
                )
                .toList()
              ..sort((a, b) => (b.month ?? '').compareTo(a.month ?? ''));
        if (profilePlans.isEmpty) {
          items.add((label: p.name, profileId: p.id!, planMonth: null));
        } else {
          for (final pl in profilePlans) {
            final monthDt = DateTime.tryParse('${pl.month!}-01');
            final monthLabel = monthDt != null
                ? DateFormat('MMM yyyy').format(monthDt)
                : pl.month!;
            items.add((
              label: '${p.name} – $monthLabel',
              profileId: p.id!,
              planMonth: pl.month,
            ));
          }
        }
      } else {
        items.add((label: p.name, profileId: p.id!, planMonth: null));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text(
                'Select Budget',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.block_outlined,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    title: Text(
                      'No budget',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: selectedProfileId == null
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: AppColors.accent,
                          )
                        : null,
                    onTap: () {
                      onSelect(null, null, null);
                      Navigator.pop(context);
                    },
                  ),
                  ...items.map((item) {
                    final sel =
                        selectedProfileId == item.profileId &&
                        selectedPlanMonth == item.planMonth;
                    return ListTile(
                      title: Text(
                        item.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: fg,
                        ),
                      ),
                      trailing: sel
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.accent,
                            )
                          : null,
                      onTap: () {
                        onSelect(item.profileId, item.label, item.planMonth);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
