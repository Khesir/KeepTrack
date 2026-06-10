import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import '../sheets/sheet_helpers.dart';
import '../widgets/detail_sheet_widgets.dart';
import 'debt_payment_drawer.dart';

class DebtDetailSheet extends StatefulWidget {
  final Debt debt;
  final DebtController debtController;
  final Future<void> Function(double amount, double? fee, PaymentTxConfig config) onPay;
  final Future<void> Function(Debt updated) onUpdate;
  final VoidCallback? onDelete;

  const DebtDetailSheet({
    super.key,
    required this.debt,
    required this.debtController,
    required this.onPay,
    required this.onUpdate,
    this.onDelete,
  });

  @override
  State<DebtDetailSheet> createState() => _DebtDetailSheetState();
}

class _DebtDetailSheetState extends State<DebtDetailSheet> {
  bool _editMode = false;
  bool _loading = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _monthlyCtrl;
  late final TextEditingController _notesCtrl;

  Debt _latestDebt(AsyncState<List<Debt>> state) {
    if (state is AsyncData<List<Debt>>) {
      for (final d in state.data) {
        if (d.id == widget.debt.id) return d;
      }
    }
    return widget.debt;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.debt.personName);
    _monthlyCtrl = TextEditingController(text: widget.debt.monthlyPaymentAmount > 0 ? widget.debt.monthlyPaymentAmount.toStringAsFixed(2) : '');
    _notesCtrl = TextEditingController(text: widget.debt.notes ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _monthlyCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
      widget.onDelete?.call();
    }
  }

  void _showPayDrawer(Debt current) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DebtPaymentDrawer(debt: current, onConfirm: (amount, fee, config) async {
        setState(() => _loading = true);
        try { await widget.onPay(amount, fee, config); }
        finally { if (mounted) setState(() => _loading = false); }
      }),
    );
  }

  Future<void> _save(Debt current) async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final monthly = double.tryParse(_monthlyCtrl.text) ?? 0.0;
    setState(() => _loading = true);
    try {
      await widget.onUpdate(current.copyWith(
        personName: _nameCtrl.text.trim(), monthlyPaymentAmount: monthly,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
      if (mounted) setState(() => _editMode = false);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<AsyncState<List<Debt>>>(
      stream: widget.debtController.stream,
      initialData: widget.debtController.state,
      builder: (_, snap) {
        final d = _latestDebt(snap.data ?? widget.debtController.state);
        final isReceivable = d.type == DebtType.lending;
        final color = isReceivable ? AppColors.success : AppColors.error;

        final isSettled = d.status == DebtStatus.settled || d.remainingAmount <= 0;
        return CompactFrame(
          isDark: isDark,
          title: _editMode ? 'Edit ${isReceivable ? 'Receivable' : 'Debt'}' : d.personName,
          trailing: !_editMode ? StatusPill(
            text: isSettled ? (isReceivable ? 'Collected' : 'Settled') : (isReceivable ? 'Receivable' : 'Debt'),
            color: isSettled ? AppColors.success : color,
          ) : null,
          onBack: _editMode ? () => setState(() => _editMode = false) : null,
          child: _editMode
              ? _DebtEditBody(nameCtrl: _nameCtrl, monthlyCtrl: _monthlyCtrl, notesCtrl: _notesCtrl, loading: _loading, onSave: () => _save(d), onCancel: () => setState(() => _editMode = false), isDark: isDark)
              : _DebtViewBody(debt: d, loading: _loading, onCollect: isSettled ? null : () => _showPayDrawer(d), onEdit: () => setState(() => _editMode = true), onDelete: widget.onDelete != null ? () => _confirmDelete(context) : null, isDark: isDark),
        );
      },
    );
  }
}

class _DebtViewBody extends StatelessWidget {
  final Debt debt;
  final bool loading, isDark;
  final VoidCallback? onCollect;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _DebtViewBody({required this.debt, required this.loading, this.onCollect, required this.onEdit, this.onDelete, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final d = debt;
    final isReceivable = d.type == DebtType.lending;
    final color = isReceivable ? AppColors.success : AppColors.error;
    final progress = d.progress;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Compact progress row
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Remaining', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              Text(currencyFormatter.format(d.remainingAmount, decimalDigits: 2),
                  style: GoogleFonts.dmMono(fontSize: 22, fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
            ])),
            if (d.originalAmount > 0)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Paid so far', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                Text(currencyFormatter.format(d.paidAmount, decimalDigits: 2),
                    style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success, fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
          ]),
          if (d.originalAmount > 0) ...[
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Column(children: [
                ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: v, minHeight: 5, backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border, valueColor: AlwaysStoppedAnimation<Color>(AppColors.success))),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${(v * 100).round()}% paid', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
                  Text('of ${currencyFormatter.format(d.originalAmount, decimalDigits: 2)}', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
                ]),
              ]),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      DetailInfoRow(isDark: isDark, label: 'Since', value: DateFormat('MMMM d, yyyy').format(d.startDate)),
      DetailInfoRow(isDark: isDark, label: 'Planned', value: d.monthlyPaymentAmount > 0 ? '${currencyFormatter.format(d.monthlyPaymentAmount, decimalDigits: 2)} / month' : 'Not set'),
      if (d.notes != null && d.notes!.isNotEmpty) DetailInfoRow(isDark: isDark, label: 'Notes', value: d.notes!),
      if (d.isOverdue) DetailInfoRow(isDark: isDark, label: 'Status', value: 'Payment overdue', valueColor: AppColors.error),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            flex: 7,
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: loading ? null : onCollect,
                icon: loading
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.payments_outlined, size: 15),
                label: Text(
                  onCollect == null
                      ? (isReceivable ? 'Fully Collected' : 'Fully Paid')
                      : (isReceivable ? 'Collect Payment' : 'Record Payment'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: onCollect == null ? AppColors.textTertiary : color,
                  foregroundColor: AppColors.textPrimaryDark,
                  elevation: 0,
                  textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
                  side: BorderSide(color: (isDark ? AppColors.primaryForeground : AppColors.textPrimary).withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.edit_outlined, size: 16),
              ),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.delete_outlined, size: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    ]);
  }
}

class _DebtEditBody extends StatelessWidget {
  final TextEditingController nameCtrl, monthlyCtrl, notesCtrl;
  final bool loading, isDark;
  final VoidCallback onSave, onCancel;

  const _DebtEditBody({required this.nameCtrl, required this.monthlyCtrl, required this.notesCtrl, required this.loading, required this.onSave, required this.onCancel, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    DetailSectionLabel('Person / Company'),
    DetailField(ctrl: nameCtrl, label: 'Name', isDark: isDark),
    const SizedBox(height: 16),
    DetailSectionLabel('Planned Monthly Payment'),
    DetailField(ctrl: monthlyCtrl, label: 'Amount (0 = no plan)', isDark: isDark, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
    Padding(padding: const EdgeInsets.only(top: 5), child: Text('Pre-fills the payment amount when recording a payment.', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, height: 1.4))),
    const SizedBox(height: 16),
    DetailSectionLabel('Notes (optional)'),
    DetailField(ctrl: notesCtrl, label: 'Notes', isDark: isDark, maxLines: 2),
    const SizedBox(height: 20),
    SheetActionButton(label: 'Save Changes', icon: Icons.check_rounded, color: AppColors.accent, loading: loading, onTap: onSave),
    const SizedBox(height: 8),
    SheetActionButton(label: 'Cancel', icon: Icons.close_rounded, color: AppColors.textSecondary, outlined: true, onTap: onCancel, isDark: isDark),
  ]);
}
