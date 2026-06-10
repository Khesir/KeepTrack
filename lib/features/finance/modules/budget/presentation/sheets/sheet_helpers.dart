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

class SheetPickerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasValue;
  final Color border;
  final Color textPrimary;
  final VoidCallback onTap;
  final Color? errorBorderColor;
  final Widget? trailing;

  const SheetPickerField({super.key, required this.icon, required this.label, required this.hasValue, required this.border, required this.textPrimary, required this.onTap, this.errorBorderColor, this.trailing});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: errorBorderColor ?? border, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: GoogleFonts.dmSans(fontSize: 14, color: hasValue ? textPrimary : AppColors.textSecondary)),
        ),
        trailing ?? Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
      ]),
    ),
  );
}

class SheetToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color textPrimary;

  const SheetToggleRow({super.key, required this.title, required this.subtitle, required this.value, required this.onChanged, required this.textPrimary});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
      Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.accent),
    ]),
  );
}

class SheetInfoRow extends StatelessWidget {
  final bool isDark;
  final String label, value;
  final Color? textPrimary;
  const SheetInfoRow({super.key, required this.isDark, required this.label, required this.value, this.textPrimary});

  @override
  Widget build(BuildContext context) {
    final def = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary ?? def))),
      ]),
    );
  }
}

class SheetActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading, outlined;
  final bool? isDark;
  final VoidCallback? onTap;
  const SheetActionButton({super.key, required this.label, required this.icon, required this.color, this.loading = false, this.outlined = false, this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(width: double.infinity, height: 46,
        child: OutlinedButton.icon(
          onPressed: onTap, icon: Icon(icon, size: 15), label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color, side: BorderSide(color: color.withValues(alpha: 0.4)),
            textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }
    return SizedBox(width: double.infinity, height: 46,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 15),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: onTap == null ? AppColors.textTertiary : color,
          foregroundColor: AppColors.textPrimaryDark, elevation: 0,
          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
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
