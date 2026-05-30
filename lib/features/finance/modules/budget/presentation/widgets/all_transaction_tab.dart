import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../transaction/domain/entities/transaction.dart';

class AllTransactionsTab extends StatefulWidget {
  final List<Transaction> transactions;

  const AllTransactionsTab({required this.transactions});

  @override
  State<AllTransactionsTab> createState() => _AllTransactionsTabState();
}

class _AllTransactionsTabState extends State<AllTransactionsTab> {
  static const _pageSize = 10;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    final sorted = [...widget.transactions]..sort((a, b) => b.date.compareTo(a.date));
    final hasMore = sorted.length > _pageSize;
    final visible = _expanded ? sorted : sorted.take(_pageSize).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              'TRANSACTIONS',
              style: GoogleFonts.dmSans(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary, letterSpacing: 1.2,
              ),
            ),
            if (widget.transactions.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.transactions.length}',
                  style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 0.5),
            ),
            child: sorted.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No transactions this period',
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      ...visible.asMap().entries.map((e) {
                        final i = e.key;
                        final t = e.value;
                        final isIncome = t.type == TransactionType.income;
                        final color = isIncome ? AppColors.success : AppColors.error;
                        final sign = isIncome ? '+' : '-';

                        return TweenAnimationBuilder<double>(
                          key: ValueKey(t.id ?? i),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Interval(
                            (i * 0.06).clamp(0.0, 0.5),
                            ((i * 0.06) + 0.4).clamp(0.0, 1.0),
                            curve: Curves.easeOut,
                          ),
                          builder: (_, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child),
                          ),
                          child: Column(children: [
                            if (i > 0) Divider(height: 1, thickness: 0.5, color: divColor, indent: 12, endIndent: 12),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                              child: Row(children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Icon(
                                    isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    size: 13, color: color,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(
                                      t.description ?? '—',
                                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(t.date),
                                      style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ]),
                                ),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text(
                                    '$sign${currencyFormatter.format(t.amount, decimalDigits: 2)}',
                                    style: GoogleFonts.dmMono(
                                      fontSize: 12, fontWeight: FontWeight.w600, color: color,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  if (t.hasFee)
                                    Text(
                                      '+${currencyFormatter.format(t.fee, decimalDigits: 2)} fee',
                                      style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textTertiary),
                                    ),
                                ]),
                              ]),
                            ),
                          ]),
                        );
                      }),
                      if (hasMore) ...[
                        Divider(height: 1, thickness: 0.5, color: divColor),
                        GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(
                                _expanded ? 'Show less' : 'View ${sorted.length - _pageSize} more',
                                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _expanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: AppColors.accent),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
