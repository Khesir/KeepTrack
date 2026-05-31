import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';

class SavingsSection extends StatelessWidget {
  final List<Wallet> buckets;
  final Map<String, double> plannedAmounts;
  final VoidCallback onManage;
  final void Function(Wallet) onDeposit;
  final void Function(Wallet, double) onSetPlanned;
  final int? dragIndex;

  const SavingsSection({
    super.key,
    required this.buckets,
    required this.plannedAmounts,
    required this.onManage,
    required this.onDeposit,
    required this.onSetPlanned,
    this.dragIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = AppColors.border.withValues(alpha: isDark ? 0.15 : 0.4);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Savings',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onManage,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.textTertiary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(Icons.edit_outlined, size: 13, color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (dragIndex != null)
                  ReorderableDragStartListener(
                    index: dragIndex!,
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Icon(Icons.drag_handle, size: 16, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Column labels — match _SavingsRow widths
                SizedBox(
                  width: 90,
                  child: Text(
                    'Planned',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 90,
                  child: Text(
                    'Balance',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // ── Savings rows ───────────────────────────────────────────────
          if (buckets.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Text(
                'No savings buckets selected — tap edit to add',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary),
              ),
            )
          else
            ...buckets.expand((b) => [
              _SavingsRow(
                bucket: b,
                planned: plannedAmounts[b.id] ?? 0,
                onDeposit: () => onDeposit(b),
                onSetPlanned: (amount) => onSetPlanned(b, amount),
                isDark: isDark,
              ),
              Divider(height: 1, color: borderColor),
            ]),
        ],
      ),
    );
  }
}

class _SavingsRow extends StatelessWidget {
  final Wallet bucket;
  final double planned;
  final VoidCallback onDeposit;
  final void Function(double) onSetPlanned;
  final bool isDark;

  const _SavingsRow({
    required this.bucket,
    required this.planned,
    required this.onDeposit,
    required this.onSetPlanned,
    required this.isDark,
  });

  void _showPlannedDialog(BuildContext context) {
    final ctrl = TextEditingController(
      text: planned > 0 ? planned.toStringAsFixed(2) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Planned deposit — ${bucket.name}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v >= 0) onSetPlanned(v);
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              bucket.name,
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => _showPlannedDialog(context),
            child: SizedBox(
              width: 90,
              child: Text(
                planned > 0 ? currencyFormatter.format(planned, decimalDigits: 2) : '—',
                textAlign: TextAlign.right,
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  color: planned > 0 ? AppColors.textSecondary : AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                  decoration: planned > 0 ? TextDecoration.underline : null,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: AppColors.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 90,
            child: Text(
              currencyFormatter.format(bucket.balance, decimalDigits: 2),
              textAlign: TextAlign.right,
              style: GoogleFonts.dmMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: GestureDetector(
                onTap: onDeposit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text(
                    'Add',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
