import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';

class GoalsManagementDialog extends StatefulWidget {
  final Goal? goal;
  final Function(Goal) onSave;

  const GoalsManagementDialog({this.goal, required this.onSave, super.key});

  static Future<void> show(BuildContext context, {Goal? goal, required Function(Goal) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => GoalsManagementDialog(goal: goal, onSave: onSave),
    );
  }

  @override
  State<GoalsManagementDialog> createState() => _GoalsManagementDialogState();
}

class _GoalsManagementDialogState extends State<GoalsManagementDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _monthlyCtrl;
  late final TextEditingController _descCtrl;

  String? _savingsBucketId;
  String? _savingsBucketName;
  DateTime? _targetDate;
  GoalStatus _status = GoalStatus.active;
  Color _color = const Color(0xFF534AB7); // brand violet default
  bool _saving = false;

  bool get _isEdit => widget.goal != null;

  static const _palette = [
    Color(0xFF534AB7), // violet
    Color(0xFF1D9E75), // teal
    Color(0xFFE24B4A), // red
    Color(0xFFEF9F27), // gold
    Color(0xFF378ADD), // blue
    Color(0xFF8B5CF6), // purple
    Color(0xFF14B8A6), // emerald
    Color(0xFFF97316), // orange
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _targetCtrl = TextEditingController(text: g != null ? g.targetAmount.toStringAsFixed(2) : '');
    _monthlyCtrl = TextEditingController(text: g != null && g.monthlyContribution > 0 ? g.monthlyContribution.toStringAsFixed(2) : '');
    _descCtrl = TextEditingController(text: g?.description ?? '');
    _savingsBucketId = g?.savingsBucketId;
    _targetDate = g?.targetDate;
    _status = g?.status ?? GoalStatus.active;
    if (g?.colorHex != null) {
      try { _color = Color(int.parse(g!.colorHex!.replaceFirst('#', '0xFF'))); } catch (_) {}
    }
    locator.get<WalletController>().loadWallets();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _monthlyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      (double.tryParse(_targetCtrl.text) ?? 0) > 0 &&
      _savingsBucketId != null;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    try {
      final colorHex = '#${_color.value.toRadixString(16).substring(2).toUpperCase()}';
      widget.onSave(Goal(
        id: widget.goal?.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        targetAmount: double.parse(_targetCtrl.text),
        currentAmount: widget.goal?.currentAmount ?? 0,
        targetDate: _targetDate,
        colorHex: colorHex,
        status: _status,
        monthlyContribution: double.tryParse(_monthlyCtrl.text) ?? 0,
        savingsBucketId: _savingsBucketId,
      ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pickWallet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletPicker(
        isDark: isDark,
        selectedId: _savingsBucketId,
        onSelect: (bucket) {
          setState(() {
            _savingsBucketId = bucket.id;
            _savingsBucketName = bucket.name;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _pickDate(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalDatePicker(
        isDark: isDark,
        selected: _targetDate,
        onSelect: (d) { setState(() => _targetDate = d); Navigator.pop(context); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Column(children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.flag_rounded, size: 18, color: _color)),
              const SizedBox(width: 12),
              Expanded(child: Text(_isEdit ? 'Edit Goal' : 'New Goal',
                  style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary))),
              GestureDetector(onTap: () => Navigator.pop(context),
                  child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
            ]),
          ),
          Divider(height: 20, color: borderColor),
          // Form
          Expanded(
            child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
              // Goal name
              _FieldLabel('Goal Name *'),
              TextField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Emergency Fund, New Car…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  hintStyle: GoogleFonts.dmSans(color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 18),

              // Target amount
              _FieldLabel('Target Amount *'),
              TextField(
                controller: _targetCtrl,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '${currencyFormatter.currencySymbol} ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),

              // Savings bucket (required)
              _FieldLabel('Linked Savings Bucket *'),
              GestureDetector(
                onTap: () => _pickWallet(isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _savingsBucketId == null
                          ? AppColors.error.withValues(alpha: 0.4)
                          : borderColor,
                      width: _savingsBucketId == null ? 1 : 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: _savingsBucketId != null ? AppColors.success.withValues(alpha: 0.05) : Colors.transparent,
                  ),
                  child: Row(children: [
                    Icon(Icons.savings_outlined, size: 18, color: _savingsBucketId != null ? AppColors.success : AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      _savingsBucketName ?? 'Select a savings bucket',
                      style: GoogleFonts.dmSans(fontSize: 14, color: _savingsBucketId != null ? textPrimary : AppColors.textSecondary),
                    )),
                    Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
                  ]),
                ),
              ),
              if (_savingsBucketId == null) ...[
                const SizedBox(height: 4),
                Text('Contributions will be deposited into this bucket',
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 18),

              // Monthly contribution
              _FieldLabel('Monthly Contribution (optional)'),
              TextField(
                controller: _monthlyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '${currencyFormatter.currencySymbol} ',
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  helperText: 'How much you plan to save per month',
                ),
              ),
              const SizedBox(height: 18),

              // Target date
              _FieldLabel('Target Date (optional)'),
              GestureDetector(
                onTap: () => _pickDate(isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      _targetDate != null ? DateFormat('MMMM d, yyyy').format(_targetDate!) : 'No target date',
                      style: GoogleFonts.dmSans(fontSize: 14, color: _targetDate != null ? textPrimary : AppColors.textSecondary),
                    )),
                    if (_targetDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _targetDate = null),
                        child: Icon(Icons.close_rounded, size: 16, color: AppColors.textTertiary),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 18),

              // Color
              _FieldLabel('Color'),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _palette.map((c) {
                  final selected = _color.value == c.value;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? textPrimary : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: selected ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))] : null,
                      ),
                      child: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Description
              _FieldLabel('Notes (optional)'),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'What is this goal for?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // Status (edit only)
              if (_isEdit) ...[
                const SizedBox(height: 18),
                _FieldLabel('Status'),
                Row(children: GoalStatus.values.map((s) {
                  final selected = _status == s;
                  final color = switch (s) {
                    GoalStatus.active => AppColors.success,
                    GoalStatus.paused => AppColors.warning,
                    GoalStatus.completed => AppColors.accent,
                  };
                  return Expanded(child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _status = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? color : borderColor, width: selected ? 1.5 : 0.5),
                        ),
                        child: Column(children: [
                          Icon(switch (s) { GoalStatus.active => Icons.play_arrow_rounded, GoalStatus.paused => Icons.pause_rounded, _ => Icons.check_rounded }, size: 16, color: selected ? color : AppColors.textSecondary),
                          const SizedBox(height: 3),
                          Text(s.displayName, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? color : AppColors.textSecondary)),
                        ]),
                      ),
                    ),
                  ));
                }).toList()),
              ],

              const SizedBox(height: 28),
              SizedBox(width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _canSave && !_saving ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave ? _color : AppColors.textTertiary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? 'Save Changes' : 'Create Goal',
                          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Savings Bucket Picker ────────────────────────────────────────────────────

class _WalletPicker extends StatelessWidget {
  final bool isDark;
  final String? selectedId;
  final void Function(Wallet) onSelect;

  const _WalletPicker({required this.isDark, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 14, 16, 10), child: Row(children: [
          Text('Select Wallet', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
          const Spacer(),
          GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
        ])),
        Divider(height: 1, color: borderColor),
        AsyncStreamBuilder<List<Wallet>>(
          state: locator.get<WalletController>(),
          builder: (_, wallets) {
            if (wallets.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 40, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text('No wallets yet', style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Create a wallet first to link your goal', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary), textAlign: TextAlign.center),
                ]),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: wallets.map((b) {
                final isSelected = b.id == selectedId;
                final color = b.colorHex != null
                    ? Color(int.parse(b.colorHex!.replaceFirst('#', '0xff')))
                    : AppColors.success;
                return Column(children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.account_balance_wallet_outlined, size: 20, color: color)),
                    title: Text(b.name, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: textPrimary)),
                    subtitle: Text(currencyFormatter.format(b.balance, decimalDigits: 2),
                        style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.success)),
                    trailing: isSelected ? Icon(Icons.check_rounded, size: 20, color: AppColors.accent) : null,
                    onTap: () => onSelect(b),
                  ),
                  Divider(height: 1, color: borderColor, indent: 20, endIndent: 20),
                ]);
              }).toList(),
            );
          },
          loadingBuilder: (_) => const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
          errorBuilder: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
      ])),
    );
  }
}

// ─── Date Picker ──────────────────────────────────────────────────────────────

class _GoalDatePicker extends StatefulWidget {
  final bool isDark;
  final DateTime? selected;
  final void Function(DateTime) onSelect;

  const _GoalDatePicker({required this.isDark, required this.selected, required this.onSelect});

  @override
  State<_GoalDatePicker> createState() => _GoalDatePickerState();
}

class _GoalDatePickerState extends State<_GoalDatePicker> {
  late DateTime _view;

  @override
  void initState() {
    super.initState();
    final base = widget.selected ?? DateTime.now().add(const Duration(days: 365));
    _view = DateTime(base.year, base.month);
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = widget.isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final firstDay = DateTime(_view.year, _view.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_view.year, _view.month);
    final startOffset = firstDay.weekday % 7;
    final today = DateTime.now();

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
        Divider(height: 1, color: borderColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Expanded(child: Center(
              child: Text(d, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary))))).toList()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 40),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startOffset) return const SizedBox.shrink();
              final day = i - startOffset + 1;
              final date = DateTime(_view.year, _view.month, day);
              final isSelected = widget.selected != null && DateUtils.isSameDay(date, widget.selected!);
              final isPast = date.isBefore(today) && !DateUtils.isSameDay(date, today);
              Color textColor = textPrimary;
              if (isPast) textColor = AppColors.textTertiary;
              if (isSelected) textColor = Colors.white;
              return GestureDetector(
                onTap: isPast ? null : () => widget.onSelect(date),
                child: Center(child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('$day', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: textColor)),
                )),
              );
            },
          ),
        ),
      ])),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.2)),
  );
}
