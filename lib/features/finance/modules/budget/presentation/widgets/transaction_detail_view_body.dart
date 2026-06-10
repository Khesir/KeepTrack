import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import '../sheets/sheet_helpers.dart';
import 'transaction_detail_attachments.dart';

class TransactionDetailViewBody extends StatelessWidget {
  final Transaction transaction;
  final bool isDark;
  final Color color;
  final Color textPrimary;
  final String? linked;
  final bool isTransfer;
  final bool loading;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const TransactionDetailViewBody({
    super.key,
    required this.transaction,
    required this.isDark,
    required this.color,
    required this.textPrimary,
    required this.linked,
    required this.isTransfer,
    required this.loading,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == TransactionType.income;
    final sign = isTransfer ? '↔' : (isIncome ? '+' : '-');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Amount', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
            Text(
              '$sign${currencyFormatter.format(t.amount, decimalDigits: 2)}',
              style: GoogleFonts.dmMono(fontSize: 22, fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ])),
          if (t.hasFee)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Fee', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              Text('+${currencyFormatter.format(t.fee, decimalDigits: 2)}',
                  style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
        ]),
      ),
      const SizedBox(height: 14),
      SheetInfoRow(isDark: isDark, label: 'Date', value: DateFormat('MMMM d, yyyy').format(t.date), textPrimary: textPrimary),
      if (linked != null) SheetInfoRow(isDark: isDark, label: isTransfer ? 'Transfer' : 'Linked to', value: linked!, textPrimary: AppColors.info),
      if (t.notes != null && t.notes!.isNotEmpty) SheetInfoRow(isDark: isDark, label: 'Notes', value: t.notes!, textPrimary: textPrimary),
      if (t.imagePaths.isNotEmpty) ...[
        const SizedBox(height: 14),
        TransactionDetailAttachmentList(imagePaths: t.imagePaths),
      ],
      const SizedBox(height: 20),
      SheetActionButton(label: 'Edit Transaction', icon: Icons.edit_outlined,
          color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
          outlined: true, isDark: isDark, onTap: onEdit),
      const SizedBox(height: 8),
      SheetActionButton(label: 'Delete Transaction', icon: Icons.delete_outline_rounded,
          color: AppColors.error, loading: loading, onTap: t.id != null ? onDelete : null),
    ]);
  }
}
