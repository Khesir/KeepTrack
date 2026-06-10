import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import '../sheets/sheet_helpers.dart';
import '../widgets/detail_sheet_widgets.dart';
import 'subscription_pay_drawer.dart';

class SubDetailSheet extends StatefulWidget {
  final Subscription sub;
  final SubscriptionController subController;
  final DateTime month;
  final Future<void> Function(PaymentTxConfig config) onPay;
  final Future<void> Function(Subscription) onUpdate;
  final VoidCallback? onDelete;

  const SubDetailSheet({
    super.key,
    required this.sub,
    required this.subController,
    required this.month,
    required this.onPay,
    required this.onUpdate,
    this.onDelete,
  });

  @override
  State<SubDetailSheet> createState() => _SubDetailSheetState();
}

class _SubDetailSheetState extends State<SubDetailSheet> {
  bool _editMode = false;
  bool _loading = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _providerCtrl;

  Subscription _latestSub(AsyncState<List<Subscription>> state) {
    if (state is AsyncData<List<Subscription>>) {
      for (final s in state.data) {
        if (s.id == widget.sub.id) return s;
      }
    }
    return widget.sub;
  }

  bool _paidThisMonth(Subscription s) =>
      s.lastBilledDate != null &&
      s.lastBilledDate!.year == widget.month.year &&
      s.lastBilledDate!.month == widget.month.month;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.sub.name);
    _amountCtrl = TextEditingController(text: widget.sub.amount.toStringAsFixed(2));
    _providerCtrl = TextEditingController(text: widget.sub.provider ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _amountCtrl.dispose(); _providerCtrl.dispose(); super.dispose(); }

  void _pay(BuildContext context, Subscription sub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscriptionPayDrawer(
        sub: sub,
        onConfirm: (config) async {
          setState(() => _loading = true);
          try {
            await widget.onPay(config);
          } catch (e) {
            if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
      widget.onDelete?.call();
    }
  }

  Future<void> _save(Subscription current) async {
    final amount = double.tryParse(_amountCtrl.text);
    if (_nameCtrl.text.trim().isEmpty || amount == null || amount <= 0) return;
    setState(() => _loading = true);
    try {
      await widget.onUpdate(current.copyWith(
        name: _nameCtrl.text.trim(), amount: amount,
        provider: _providerCtrl.text.trim().isEmpty ? null : _providerCtrl.text.trim(),
      ));
      if (mounted) setState(() => _editMode = false);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<AsyncState<List<Subscription>>>(
      stream: widget.subController.stream,
      initialData: widget.subController.state,
      builder: (_, snap) {
        final s = _latestSub(snap.data ?? widget.subController.state);
        final paid = _paidThisMonth(s);
        final now = DateTime.now();
        final daysUntil = s.nextBillingDate.difference(now).inDays;
        final statusColor = paid ? AppColors.success : s.isOverdue ? AppColors.error : daysUntil <= 3 ? AppColors.warning : AppColors.textSecondary;
        final statusText = paid ? 'Paid' : s.isOverdue ? 'Overdue' : daysUntil == 0 ? 'Due today' : 'Due in ${daysUntil}d';

        return CompactFrame(
          isDark: isDark,
          title: _editMode ? 'Edit Subscription' : s.name,
          trailing: !_editMode ? StatusPill(text: statusText, color: statusColor) : null,
          onBack: _editMode ? () => setState(() => _editMode = false) : null,
          child: _editMode
              ? _SubEditBody(nameCtrl: _nameCtrl, amountCtrl: _amountCtrl, providerCtrl: _providerCtrl, loading: _loading, onSave: () => _save(s), onCancel: () => setState(() => _editMode = false), isDark: isDark)
              : _SubViewBody(sub: s, paidThisMonth: paid, loading: _loading, onPay: paid ? null : () => _pay(context, s), onEdit: () => setState(() => _editMode = true), onDelete: widget.onDelete != null ? () => _confirmDelete(context) : null, isDark: isDark),
        );
      },
    );
  }
}

class _SubViewBody extends StatelessWidget {
  final Subscription sub;
  final bool paidThisMonth, loading, isDark;
  final VoidCallback? onPay;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _SubViewBody({required this.sub, required this.paidThisMonth, required this.loading, required this.onPay, required this.onEdit, this.onDelete, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DetailInfoRow(isDark: isDark, label: 'Amount', value: '${currencyFormatter.format(sub.amount, decimalDigits: 2)} · ${sub.billingCycle.displayName}'),
      if (sub.provider != null) DetailInfoRow(isDark: isDark, label: 'Provider', value: sub.provider!),
      DetailInfoRow(isDark: isDark, label: 'Next billing', value: DateFormat('MMMM d, yyyy').format(sub.nextBillingDate),
          sub: sub.nextBillingDate.isAfter(now) ? '${sub.nextBillingDate.difference(now).inDays} days from now' : null,
          subColor: sub.isOverdue ? AppColors.error : null),
      if (sub.lastBilledDate != null)
        DetailInfoRow(isDark: isDark, label: 'Last paid', value: DateFormat('MMMM d, yyyy').format(sub.lastBilledDate!),
            sub: paidThisMonth ? 'Paid this month ✓' : null, subColor: AppColors.success),
      DetailInfoRow(isDark: isDark, label: 'Monthly cost', value: currencyFormatter.format(sub.monthlyEquivalent, decimalDigits: 2)),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            flex: 7,
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: loading ? null : onPay,
                icon: loading
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline_rounded, size: 15),
                label: Text(paidThisMonth ? 'Already paid' : 'Mark as Paid · ${currencyFormatter.format(sub.amount, decimalDigits: 2)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: onPay == null ? AppColors.textTertiary : AppColors.success,
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

class _SubEditBody extends StatelessWidget {
  final TextEditingController nameCtrl, amountCtrl, providerCtrl;
  final bool loading, isDark;
  final VoidCallback onSave, onCancel;

  const _SubEditBody({required this.nameCtrl, required this.amountCtrl, required this.providerCtrl, required this.loading, required this.onSave, required this.onCancel, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(children: [
    DetailField(ctrl: nameCtrl, label: 'Name', isDark: isDark),
    const SizedBox(height: 12),
    DetailField(ctrl: amountCtrl, label: 'Amount', isDark: isDark, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
    const SizedBox(height: 12),
    DetailField(ctrl: providerCtrl, label: 'Provider (optional)', isDark: isDark),
    const SizedBox(height: 20),
    SheetActionButton(label: 'Save Changes', icon: Icons.check_rounded, color: AppColors.accent, loading: loading, onTap: onSave),
    const SizedBox(height: 8),
    SheetActionButton(label: 'Cancel', icon: Icons.close_rounded, color: AppColors.textSecondary, outlined: true, onTap: onCancel, isDark: isDark),
  ]);
}
