import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/helpers/split_entry.dart';

class SplitEntryHeaderRow extends StatelessWidget {
  final SplitEntry entry;
  final bool isDark;
  final bool canRemove;
  final VoidCallback onTypeToggle;
  final VoidCallback onNoteChanged;
  final VoidCallback onPickImage;
  final VoidCallback onRemove;

  const SplitEntryHeaderRow({
    super.key,
    required this.entry,
    required this.isDark,
    required this.canRemove,
    required this.onTypeToggle,
    required this.onNoteChanged,
    required this.onPickImage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    final typeColor = entry.type == TransactionType.income
        ? AppColors.success
        : AppColors.error;
    final hasCategory = entry.category != null;

    return Row(
      children: [
        // Type toggle
        GestureDetector(
          onTap: onTypeToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  entry.type == TransactionType.income
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 11,
                  color: typeColor,
                ),
                const SizedBox(width: 3),
                Text(
                  entry.type == TransactionType.income ? 'In' : 'Out',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Description inline
        Expanded(
          child: TextField(
            controller: entry.noteCtrl,
            onChanged: (_) => onNoteChanged(),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 2),
              border: InputBorder.none,
              hintText: hasCategory ? entry.category!.name : 'Description',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 13,
                color: hasCategory
                    ? textPrimary.withValues(alpha: 0.5)
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Amount
        SizedBox(
          width: 80,
          child: TextField(
            controller: entry.amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) => onNoteChanged(),
            textAlign: TextAlign.right,
            style: GoogleFonts.dmMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: '0.00',
              hintStyle: GoogleFonts.dmMono(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                if (entry.imagePaths.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(
                    '${entry.imagePaths.length}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (canRemove)
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: AppColors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}
