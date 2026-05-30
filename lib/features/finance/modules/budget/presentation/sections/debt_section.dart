import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../../../debt/domain/entities/debt.dart';
import '../widgets/debt_row.dart';

class DebtSection extends StatelessWidget {
  final String title;
  final List<Debt> debts;
  final bool isReceivable;
  final Debt? selectedDebt;
  final Map<String, double> paidThisMonth;
  final VoidCallback onAdd;
  final void Function(Debt) onPay;
  final void Function(Debt) onEdit;
  final void Function(Debt) onSelect;
  final Future<void> Function(Debt, double) onUpdateMonthlyPayment;
  final int? dragIndex;
  final bool isLocked;

  const DebtSection({
    super.key,
    required this.title,
    required this.debts,
    required this.isReceivable,
    required this.onAdd,
    required this.onPay,
    required this.onEdit,
    required this.onSelect,
    required this.onUpdateMonthlyPayment,
    this.selectedDebt,
    this.paidThisMonth = const {},
    this.dragIndex,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = AppColors.border.withValues(alpha: isDark ? 0.15 : 0.4);
    final accentColor = isReceivable ? AppColors.success : AppColors.error;
    final addLabel = isReceivable ? 'Add Receivable' : 'Add Debt';

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
                  child: Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
                    ),
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
                // Column labels — match DebtRow widths
                SizedBox(
                  width: 70,
                  child: Text(
                    'Balance',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Planned',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Paid',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 62),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // ── Debt rows ──────────────────────────────────────────────────
          if (debts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                isReceivable ? 'No receivables yet' : 'No debts yet',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary),
              ),
            )
          else
            ...debts.expand((d) => [
              DebtRow(
                key: ValueKey(d.id),
                debt: d,
                isReceivable: isReceivable,
                isSelected: selectedDebt?.id == d.id,
                paidThisMonth: paidThisMonth[d.id] ?? 0,
                isLocked: isLocked,
                onSelect: () => onSelect(d),
                onPay: () => onPay(d),
                onEdit: () => onEdit(d),
                onUpdateMonthlyPayment: (amount) => onUpdateMonthlyPayment(d, amount),
              ),
              Divider(height: 1, color: borderColor),
            ]),

          // ── Add link ───────────────────────────────────────────────────
          if (!isLocked)
            GestureDetector(
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Text(
                  addLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}
