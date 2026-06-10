import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';

class TransactionProfilePickerSheet extends StatelessWidget {
  final bool isDark;
  final List<BudgetProfile> profiles;
  final String? selectedProfileId;
  final DateTime selectedDate;
  final void Function(String? id, String? baseName, bool isMonthly, String? displayName) onSelect;

  const TransactionProfilePickerSheet({
    super.key,
    required this.isDark,
    required this.profiles,
    required this.selectedProfileId,
    required this.selectedDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
          child: Row(children: [
            Expanded(child: Text('Select Budget', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary))),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary)),
            ),
          ]),
        ),
        Divider(height: 1, color: divColor),
        ListTile(
          title: Text('None', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
          trailing: selectedProfileId == null ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
          onTap: () {
            onSelect(null, null, false, null);
            Navigator.pop(context);
          },
        ),
        Divider(height: 1, color: divColor),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: profiles.length,
            itemBuilder: (_, i) {
              final p = profiles[i];
              final sel = selectedProfileId == p.id;
              final displayName = p.isMonthly
                  ? '${p.name} · ${DateFormat('MMM yyyy').format(selectedDate)}'
                  : p.name;
              return ListTile(
                title: Text(displayName, style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: textPrimary)),
                subtitle: p.isMonthly
                    ? Text('Monthly', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary))
                    : null,
                trailing: sel ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
                onTap: () {
                  onSelect(p.id, p.name, p.isMonthly, displayName);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ])),
    );
  }
}
