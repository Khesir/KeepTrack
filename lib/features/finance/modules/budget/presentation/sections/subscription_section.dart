import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';

class SubscriptionSection extends StatelessWidget {
  final List<Subscription> subscriptions;
  final VoidCallback onAdd;
  final Future<void> Function(Subscription) onPay;
  final int? dragIndex;

  const SubscriptionSection({
    super.key,
    required this.subscriptions,
    required this.onAdd,
    required this.onPay,
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
                  child: Text(
                    'Subscriptions',
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
                // Column labels — match _SubscriptionRow widths
                SizedBox(
                  width: 80,
                  child: Text(
                    'Amount',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Cycle',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Next Bill',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 56),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // ── Subscription rows ──────────────────────────────────────────
          if (subscriptions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                'No subscriptions yet',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary),
              ),
            )
          else
            ...subscriptions.expand((s) => [
              _SubscriptionRow(subscription: s, onPay: () => onPay(s), isDark: isDark, borderColor: borderColor),
              Divider(height: 1, color: borderColor),
            ]),

          // ── Add link ───────────────────────────────────────────────────
          GestureDetector(
            onTap: onAdd,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Text(
                'Add Subscription',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onPay;
  final bool isDark;
  final Color borderColor;

  const _SubscriptionRow({
    required this.subscription,
    required this.onPay,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final s = subscription;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final isOverdue = s.isOverdue;
    final isUpcoming = s.isUpcoming;
    final dateColor = isOverdue
        ? AppColors.error
        : isUpcoming
        ? AppColors.warning
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (s.provider != null)
                  Text(
                    s.provider!,
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              currencyFormatter.format(s.amount, decimalDigits: 2),
              textAlign: TextAlign.right,
              style: GoogleFonts.dmMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 70,
            child: Text(
              s.billingCycle.displayName,
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 70,
            child: Text(
              DateFormat('MMM d').format(s.nextBillingDate),
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: dateColor,
                fontWeight: (isOverdue || isUpcoming) ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: s.status == SubscriptionStatus.active
                ? Center(
                    child: GestureDetector(
                      onTap: onPay,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Text(
                          'Pay',
                          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
