import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';

class ScanProfilePickerSheet {
  static void show(
    BuildContext context, {
    required bool isDark,
    required List<BudgetProfile> profiles,
    required String? selectedProfileId,
    required DateTime selectedDate,
    required void Function(String? id, String baseName, bool isMonthly, String displayName) onSelect,
  }) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text('Select Budget', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: fg))),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: profiles.length,
              itemBuilder: (_, i) {
                final p = profiles[i];
                final sel = selectedProfileId == p.id;
                final displayMonth = DateFormat('MMM yyyy').format(selectedDate);
                final displayName = p.isMonthly ? '${p.name} · $displayMonth' : p.name;
                return ListTile(
                  title: Text(displayName, style: GoogleFonts.dmSans(fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: fg)),
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
      ),
    );
  }
}
