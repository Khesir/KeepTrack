import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class SheetLabel extends StatelessWidget {
  final String text;
  const SheetLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.2)),
  );
}

class SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final String? prefix;
  final bool isDark, numeric, autofocus;
  final int maxLines;
  final bool capitalize;
  final void Function(String)? onChanged;

  const SheetField({super.key, required this.ctrl, required this.hint, required this.isDark, this.prefix, this.numeric = false, this.autofocus = false, this.maxLines = 1, this.capitalize = false, this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, autofocus: autofocus, maxLines: maxLines, onChanged: onChanged,
    keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    textCapitalization: capitalize ? TextCapitalization.words : TextCapitalization.none,
    decoration: InputDecoration(
      hintText: hint, prefixText: prefix,
      hintStyle: GoogleFonts.dmSans(color: AppColors.textTertiary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class SheetCalendar extends StatefulWidget {
  final bool isDark, allowPast;
  final DateTime? selected;
  final void Function(DateTime) onSelect;
  const SheetCalendar({super.key, required this.isDark, required this.selected, required this.onSelect, this.allowPast = false});

  @override
  State<SheetCalendar> createState() => _SheetCalendarState();
}

class _SheetCalendarState extends State<SheetCalendar> {
  late DateTime _view;

  @override
  void initState() {
    super.initState();
    final base = widget.selected ?? DateTime.now();
    _view = DateTime(base.year, base.month);
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.cardDark : AppColors.card;
    final border = widget.isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final now = DateTime.now();
    final firstDay = DateTime(_view.year, _view.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_view.year, _view.month);
    final startOffset = firstDay.weekday % 7;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(8, 12, 8, 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary), onPressed: () => setState(() => _view = DateTime(_view.year, _view.month - 1))),
          Text(DateFormat('MMMM yyyy').format(_view), style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
          IconButton(icon: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary), onPressed: () => setState(() => _view = DateTime(_view.year, _view.month + 1))),
        ])),
        Divider(height: 1, color: border),
        Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(children: ['S','M','T','W','T','F','S'].map((d) => Expanded(child: Center(
                child: Text(d, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary))))).toList())),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 40),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startOffset) return const SizedBox.shrink();
              final day = i - startOffset + 1;
              final date = DateTime(_view.year, _view.month, day);
              final isSelected = widget.selected != null && DateUtils.isSameDay(date, widget.selected!);
              final isPast = !widget.allowPast && date.isBefore(now) && !DateUtils.isSameDay(date, now);
              final isToday = DateUtils.isSameDay(date, now);
              Color textColor = isPast ? AppColors.textTertiary : textPrimary;
              if (isSelected) textColor = Colors.white;
              return GestureDetector(
                onTap: isPast ? null : () => widget.onSelect(date),
                child: Center(child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected ? Border.all(color: AppColors.accent, width: 1.5) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text('$day', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400, color: textColor)),
                )),
              );
            },
          ),
        ),
      ])),
    );
  }
}
