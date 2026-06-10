import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';

class BudgetProfilePickerSheet extends StatelessWidget {
  final bool isDark;
  final List<BudgetProfile> profiles;
  final String? selectedProfileId;
  final void Function(String? id, String? name) onSelect;

  const BudgetProfilePickerSheet({
    super.key,
    required this.isDark,
    required this.profiles,
    required this.selectedProfileId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
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
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Budget',
                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.block_outlined, size: 16, color: AppColors.textTertiary),
                    title: Text('None',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
                    trailing: selectedProfileId == null
                        ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent)
                        : null,
                    onTap: () {
                      onSelect(null, null);
                      Navigator.pop(context);
                    },
                  ),
                  ...profiles.where((p) => p.isActive).map((p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name,
                            style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary)),
                        trailing: selectedProfileId == p.id
                            ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent)
                            : null,
                        onTap: () {
                          onSelect(p.id, p.name);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
