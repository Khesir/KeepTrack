import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/presentation/helpers/split_entry.dart';
import 'package:keep_track/features/finance/presentation/widgets/split_entry_row.dart';

class CreateTransactionSplitPanel extends StatelessWidget {
  final List<SplitEntry> entries;
  final bool isDark;
  final Color borderColor;
  final double amount;
  final double splitTotal;
  final bool splitBalanced;
  final VoidCallback onAddLine;
  final void Function(int index) onPickCategory;
  final void Function(int index) onRemove;
  final void Function(int index) onPickImage;
  final VoidCallback onChanged;

  const CreateTransactionSplitPanel({
    super.key,
    required this.entries,
    required this.isDark,
    required this.borderColor,
    required this.amount,
    required this.splitTotal,
    required this.splitBalanced,
    required this.onAddLine,
    required this.onPickCategory,
    required this.onRemove,
    required this.onPickImage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.4,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < entries.length; i++)
                  SplitEntryRow(
                    key: ObjectKey(entries[i]),
                    entry: entries[i],
                    isDark: isDark,
                    borderColor: borderColor,
                    canRemove: entries.length > 1,
                    onChanged: onChanged,
                    onPickCategory: () => onPickCategory(i),
                    onRemove: () => onRemove(i),
                    onPickImage: () => onPickImage(i),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onAddLine,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 15,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Add line',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${currencyFormatter.format(splitTotal, decimalDigits: 2)} / ${currencyFormatter.format(amount, decimalDigits: 2)}',
                    style: GoogleFonts.dmMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: splitBalanced
                          ? AppColors.success
                          : (splitTotal > amount
                                ? AppColors.error
                                : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: amount > 0
                      ? (splitTotal / amount).clamp(0.0, 1.0)
                      : 0,
                  minHeight: 4,
                  backgroundColor: borderColor,
                  valueColor: AlwaysStoppedAnimation(
                    splitBalanced
                        ? AppColors.success
                        : (splitTotal > amount
                              ? AppColors.error
                              : AppColors.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
