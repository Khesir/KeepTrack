import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';

class PaymentTxConfig {
  final Wallet? wallet;
  final String? categoryId;
  final String? budgetProfileId;
  final List<String> imagePaths;
  final DateTime date;
  final String? description;

  const PaymentTxConfig({
    this.wallet,
    this.categoryId,
    this.budgetProfileId,
    this.imagePaths = const [],
    required this.date,
    this.description,
  });
}

class CompactFrame extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Widget child;

  const CompactFrame({super.key, required this.isDark, required this.title, required this.child, this.trailing, this.onBack});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 16, 0), child: Row(children: [
            if (onBack != null) ...[
              GestureDetector(onTap: onBack, child: Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppColors.textSecondary))),
            ],
            Expanded(child: Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
          ])),
          Divider(height: 20, color: borderColor),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: child),
        ])),
      ),
    );
  }
}

class DetailInfoRow extends StatelessWidget {
  final bool isDark;
  final String label, value;
  final String? sub;
  final Color? subColor, valueColor;

  const DetailInfoRow({super.key, required this.isDark, required this.label, required this.value, this.sub, this.subColor, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary))),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? textPrimary)),
          if (sub != null) Text(sub!, style: GoogleFonts.dmSans(fontSize: 11, color: subColor ?? AppColors.textSecondary)),
        ])),
      ]),
    );
  }
}

class DetailSectionLabel extends StatelessWidget {
  final String text;
  const DetailSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3)),
  );
}

class DetailField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool isDark;
  final TextInputType? keyboardType;
  final int? maxLines;

  const DetailField({super.key, required this.ctrl, required this.label, required this.isDark, this.keyboardType, this.maxLines});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, keyboardType: keyboardType, maxLines: maxLines ?? 1,
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
  );
}

class PayChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active, isDark;
  final VoidCallback onTap;

  const PayChip({super.key, required this.icon, required this.label, required this.active, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textSecondary;
    final bg = active
        ? AppColors.accent.withValues(alpha: 0.1)
        : (isDark ? Colors.white.withValues(alpha: 0.07) : AppColors.background);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const StatusPill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}
