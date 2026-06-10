import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class TransactionCreateDatePickerSheet extends StatefulWidget {
  final DateTime selected;
  final bool isDark;
  final bool allowFuture;
  final void Function(DateTime) onSelect;
  const TransactionCreateDatePickerSheet({
    super.key,
    required this.selected,
    required this.isDark,
    this.allowFuture = false,
    required this.onSelect,
  });

  @override
  State<TransactionCreateDatePickerSheet> createState() =>
      _TransactionCreateDatePickerSheetState();
}

class _TransactionCreateDatePickerSheetState
    extends State<TransactionCreateDatePickerSheet> {
  late DateTime _view;

  @override
  void initState() {
    super.initState();
    _view = DateTime(widget.selected.year, widget.selected.month);
  }

  void _prev() => setState(() => _view = DateTime(_view.year, _view.month - 1));
  void _next() {
    if (widget.allowFuture) {
      setState(() => _view = DateTime(_view.year, _view.month + 1));
      return;
    }
    final now = DateTime.now();
    final next = DateTime(_view.year, _view.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month)))
      setState(() => _view = next);
  }

  bool get _canGoNext {
    if (widget.allowFuture) return true;
    final now = DateTime.now();
    return _view.year < now.year ||
        (_view.year == now.year && _view.month < now.month);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    final now = DateTime.now();
    final firstDay = DateTime(_view.year, _view.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_view.year, _view.month);
    final startOffset = firstDay.weekday % 7; // 0=Sun

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Month/year nav
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: _prev,
                    padding: EdgeInsets.zero,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_view),
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _canGoNext
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                    ),
                    onPressed: _canGoNext ? _next : null,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),
            // Day of week headers
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Calendar grid
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: 40,
                ),
                itemCount: startOffset + daysInMonth,
                itemBuilder: (_, i) {
                  if (i < startOffset) return const SizedBox.shrink();
                  final day = i - startOffset + 1;
                  final date = DateTime(_view.year, _view.month, day);
                  final isSelected = DateUtils.isSameDay(date, widget.selected);
                  final isToday = DateUtils.isSameDay(date, now);
                  final isFuture = !widget.allowFuture && date.isAfter(now);
                  Color textColor = isDark
                      ? AppColors.primaryForeground
                      : AppColors.textPrimary;
                  if (isFuture) textColor = AppColors.textTertiary;
                  if (isSelected) textColor = Colors.white;

                  return GestureDetector(
                    onTap: isFuture ? null : () => widget.onSelect(date),
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday && !isSelected
                              ? Border.all(color: AppColors.accent, width: 1.5)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
