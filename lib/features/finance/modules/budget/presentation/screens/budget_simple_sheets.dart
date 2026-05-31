import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';

// ─── Subscription Detail Sheet ────────────────────────────────────────────────

class SubDetailSheet extends StatefulWidget {
  final Subscription sub;
  final SubscriptionController subController;
  final DateTime month;
  final Future<void> Function() onPay;
  final Future<void> Function(Subscription) onUpdate;

  const SubDetailSheet({super.key, required this.sub, required this.subController, required this.month, required this.onPay, required this.onUpdate});

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

  Future<void> _pay(BuildContext context) async {
    setState(() => _loading = true);
    try {
      await widget.onPay();
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
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

        return _CompactFrame(
          isDark: isDark,
          title: _editMode ? 'Edit Subscription' : s.name,
          trailing: !_editMode ? _StatusPill(text: statusText, color: statusColor) : null,
          onBack: _editMode ? () => setState(() => _editMode = false) : null,
          child: _editMode
              ? _SubEditBody(nameCtrl: _nameCtrl, amountCtrl: _amountCtrl, providerCtrl: _providerCtrl, loading: _loading, onSave: () => _save(s), onCancel: () => setState(() => _editMode = false), isDark: isDark)
              : _SubViewBody(sub: s, paidThisMonth: paid, loading: _loading, onPay: paid ? null : () => _pay(context), onEdit: () => setState(() => _editMode = true), isDark: isDark),
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

  const _SubViewBody({required this.sub, required this.paidThisMonth, required this.loading, required this.onPay, required this.onEdit, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _InfoRow(isDark: isDark, label: 'Amount', value: '${currencyFormatter.format(sub.amount, decimalDigits: 2)} · ${sub.billingCycle.displayName}'),
      if (sub.provider != null) _InfoRow(isDark: isDark, label: 'Provider', value: sub.provider!),
      _InfoRow(isDark: isDark, label: 'Next billing', value: DateFormat('MMMM d, yyyy').format(sub.nextBillingDate),
          sub: sub.nextBillingDate.isAfter(now) ? '${sub.nextBillingDate.difference(now).inDays} days from now' : null,
          subColor: sub.isOverdue ? AppColors.error : null),
      if (sub.lastBilledDate != null)
        _InfoRow(isDark: isDark, label: 'Last paid', value: DateFormat('MMMM d, yyyy').format(sub.lastBilledDate!),
            sub: paidThisMonth ? 'Paid this month ✓' : null, subColor: AppColors.success),
      _InfoRow(isDark: isDark, label: 'Monthly cost', value: currencyFormatter.format(sub.monthlyEquivalent, decimalDigits: 2)),
      const SizedBox(height: 20),
      _ActionButton(label: paidThisMonth ? 'Already paid this month' : 'Mark as Paid · ${currencyFormatter.format(sub.amount, decimalDigits: 2)}', icon: Icons.check_circle_outline_rounded, color: AppColors.success, loading: loading, onTap: onPay),
      const SizedBox(height: 8),
      _ActionButton(label: 'Edit Subscription', icon: Icons.edit_outlined, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary, outlined: true, onTap: onEdit, isDark: isDark),
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
    _Field(ctrl: nameCtrl, label: 'Name', isDark: isDark),
    const SizedBox(height: 12),
    _Field(ctrl: amountCtrl, label: 'Amount', isDark: isDark, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
    const SizedBox(height: 12),
    _Field(ctrl: providerCtrl, label: 'Provider (optional)', isDark: isDark),
    const SizedBox(height: 20),
    _ActionButton(label: 'Save Changes', icon: Icons.check_rounded, color: AppColors.accent, loading: loading, onTap: onSave),
    const SizedBox(height: 8),
    _ActionButton(label: 'Cancel', icon: Icons.close_rounded, color: AppColors.textSecondary, outlined: true, onTap: onCancel, isDark: isDark),
  ]);
}

// ─── Debt Detail Sheet ────────────────────────────────────────────────────────

class DebtDetailSheet extends StatefulWidget {
  final Debt debt;
  final DebtController debtController;
  final Future<void> Function(double amount, double? fee) onPay;
  final Future<void> Function(Debt updated) onUpdate;

  const DebtDetailSheet({super.key, required this.debt, required this.debtController, required this.onPay, required this.onUpdate});

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

  void _showPayDrawer(Debt current) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _PaymentDrawer(debt: current, onConfirm: (amount, fee) async {
        setState(() => _loading = true);
        try { await widget.onPay(amount, fee); }
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
        return _CompactFrame(
          isDark: isDark,
          title: _editMode ? 'Edit ${isReceivable ? 'Receivable' : 'Debt'}' : d.personName,
          trailing: !_editMode ? _StatusPill(
            text: isSettled ? (isReceivable ? 'Collected' : 'Settled') : (isReceivable ? 'Receivable' : 'Debt'),
            color: isSettled ? AppColors.success : color,
          ) : null,
          onBack: _editMode ? () => setState(() => _editMode = false) : null,
          child: _editMode
              ? _DebtEditBody(nameCtrl: _nameCtrl, monthlyCtrl: _monthlyCtrl, notesCtrl: _notesCtrl, loading: _loading, onSave: () => _save(d), onCancel: () => setState(() => _editMode = false), isDark: isDark)
              : _DebtViewBody(debt: d, loading: _loading, onCollect: isSettled ? null : () => _showPayDrawer(d), onEdit: () => setState(() => _editMode = true), isDark: isDark),
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

  const _DebtViewBody({required this.debt, required this.loading, this.onCollect, required this.onEdit, required this.isDark});

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
      _InfoRow(isDark: isDark, label: 'Since', value: DateFormat('MMMM d, yyyy').format(d.startDate)),
      _InfoRow(isDark: isDark, label: 'Planned', value: d.monthlyPaymentAmount > 0 ? '${currencyFormatter.format(d.monthlyPaymentAmount, decimalDigits: 2)} / month' : 'Not set'),
      if (d.notes != null && d.notes!.isNotEmpty) _InfoRow(isDark: isDark, label: 'Notes', value: d.notes!),
      if (d.isOverdue) _InfoRow(isDark: isDark, label: 'Status', value: 'Payment overdue', valueColor: AppColors.error),
      const SizedBox(height: 20),
      _ActionButton(
        label: onCollect == null
            ? (isReceivable ? 'Fully Collected' : 'Fully Paid')
            : (isReceivable ? 'Collect Payment' : 'Record Payment'),
        icon: Icons.payments_outlined,
        color: color,
        loading: loading,
        onTap: onCollect,
      ),
      const SizedBox(height: 8),
      _ActionButton(label: 'Edit ${isReceivable ? 'Receivable' : 'Debt'}', icon: Icons.edit_outlined, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary, outlined: true, onTap: onEdit, isDark: isDark),
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
    _SectionLabel('Person / Company'),
    _Field(ctrl: nameCtrl, label: 'Name', isDark: isDark),
    const SizedBox(height: 16),
    _SectionLabel('Planned Monthly Payment'),
    _Field(ctrl: monthlyCtrl, label: 'Amount (0 = no plan)', isDark: isDark, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
    Padding(padding: const EdgeInsets.only(top: 5), child: Text('Pre-fills the payment amount when recording a payment.', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, height: 1.4))),
    const SizedBox(height: 16),
    _SectionLabel('Notes (optional)'),
    _Field(ctrl: notesCtrl, label: 'Notes', isDark: isDark, maxLines: 2),
    const SizedBox(height: 20),
    _ActionButton(label: 'Save Changes', icon: Icons.check_rounded, color: AppColors.accent, loading: loading, onTap: onSave),
    const SizedBox(height: 8),
    _ActionButton(label: 'Cancel', icon: Icons.close_rounded, color: AppColors.textSecondary, outlined: true, onTap: onCancel, isDark: isDark),
  ]);
}

// ─── Category Detail Sheet ────────────────────────────────────────────────────

class CategoryDetailSheet extends StatelessWidget {
  final Budget group;
  final BudgetCategory cat;
  final double spent;
  final VoidCallback? onEdit;

  const CategoryDetailSheet({super.key, required this.group, required this.cat, required this.spent, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = group.budgetType == BudgetType.income;
    final color = isIncome ? AppColors.success : AppColors.accent;
    final planned = cat.targetAmount;
    final over = planned > 0 && spent > planned;
    final progress = planned > 0 ? (spent / planned).clamp(0.0, 1.0) : 0.0;
    final progressColor = over ? AppColors.error : color;

    return _CompactFrame(
      isDark: isDark,
      title: cat.financeCategory?.name ?? 'Category',
      trailing: _StatusPill(text: group.title ?? (isIncome ? 'Income' : 'Expenses'), color: color),
      child: Column(children: [
        // Spent / Planned card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Spent', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                Text(currencyFormatter.format(spent, decimalDigits: 2),
                    style: GoogleFonts.dmMono(fontSize: 22, fontWeight: FontWeight.w700, color: over ? AppColors.error : (isDark ? AppColors.primaryForeground : AppColors.textPrimary), fontFeatures: const [FontFeature.tabularFigures()])),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Planned', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                Text(currencyFormatter.format(planned, decimalDigits: 2),
                    style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
            ]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border, valueColor: AlwaysStoppedAnimation<Color>(progressColor))),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${(progress * 100).round()}% used', style: GoogleFonts.dmSans(fontSize: 10, color: over ? AppColors.error : AppColors.textSecondary)),
              Text(over ? 'Over by ${currencyFormatter.format(spent - planned, decimalDigits: 2)}' : '${currencyFormatter.format(planned - spent, decimalDigits: 2)} remaining',
                  style: GoogleFonts.dmSans(fontSize: 10, color: over ? AppColors.error : AppColors.textSecondary)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        _ActionButton(label: 'Edit Category', icon: Icons.edit_outlined, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary, outlined: true, onTap: onEdit, isDark: isDark),
      ]),
    );
  }
}

// ─── Payment Drawer ───────────────────────────────────────────────────────────

class _PaymentDrawer extends StatefulWidget {
  final Debt debt;
  final Future<void> Function(double amount, double? fee) onConfirm;

  const _PaymentDrawer({required this.debt, required this.onConfirm});

  @override
  State<_PaymentDrawer> createState() => _PaymentDrawerState();
}

class _PaymentDrawerState extends State<_PaymentDrawer> {
  late final TextEditingController _amtCtrl;
  late final TextEditingController _feeCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _amtCtrl = TextEditingController(text: widget.debt.monthlyPaymentAmount > 0 ? widget.debt.monthlyPaymentAmount.toStringAsFixed(2) : '');
    _feeCtrl = TextEditingController();
  }

  @override
  void dispose() { _amtCtrl.dispose(); _feeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = widget.debt;
    final isReceivable = d.type == DebtType.lending;
    final color = isReceivable ? AppColors.success : AppColors.error;
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final amt = double.tryParse(_amtCtrl.text);
    final confirmLabel = amt != null && amt > 0
        ? '${isReceivable ? 'Collect' : 'Pay'} ${currencyFormatter.format(amt, decimalDigits: 2)}'
        : isReceivable ? 'Collect' : 'Pay';

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 16, 0), child: Row(children: [
            Expanded(child: Text(isReceivable ? 'Collect from ${d.personName}' : 'Pay ${d.personName}',
                style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
          ])),
          Divider(height: 20, color: borderColor),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _amtCtrl, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: 'Amount', border: const OutlineInputBorder(),
                    helperText: d.monthlyPaymentAmount > 0 ? 'Planned: ${currencyFormatter.format(d.monthlyPaymentAmount, decimalDigits: 2)}/mo' : null)),
            const SizedBox(height: 12),
            TextField(controller: _feeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Fee (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            _ActionButton(label: confirmLabel, icon: Icons.check_circle_outline_rounded, color: color, loading: _loading, onTap: () async {
              final amount = double.tryParse(_amtCtrl.text);
              if (amount == null || amount <= 0) return;
              final fee = double.tryParse(_feeCtrl.text);
              final nav = Navigator.of(context);
              setState(() => _loading = true);
              try {
                await widget.onConfirm(amount, fee);
                nav.pop();
              } catch (e, st) {
                debugPrint('[PaymentDrawer] error: $e\n$st');
                if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            }),
            const SizedBox(height: 8),
            _ActionButton(label: 'Cancel', icon: Icons.close_rounded, color: AppColors.textSecondary, outlined: true, onTap: () => Navigator.pop(context), isDark: isDark),
          ])),
        ])),
      ),
    );
  }
}

// ─── Goal Detail Sheet ────────────────────────────────────────────────────────

class GoalDetailSheet extends StatefulWidget {
  final Goal goal;
  final GoalController goalController;
  final Future<void> Function(Goal currentGoal, double amount) onContribute;
  final Future<void> Function(Goal updated) onUpdate;

  const GoalDetailSheet({
    super.key,
    required this.goal,
    required this.goalController,
    required this.onContribute,
    required this.onUpdate,
  });

  @override
  State<GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends State<GoalDetailSheet> {
  bool _loading = false;

  // Always resolve the latest goal from the controller stream so the
  // drawer reflects optimistic updates without needing to close/reopen.
  Goal _latestGoal(AsyncState<List<Goal>> state) {
    if (state is AsyncData<List<Goal>>) {
      for (final g in state.data) {
        if (g.id == widget.goal.id) return g;
      }
    }
    return widget.goal;
  }

  void _showContributeDrawer(Goal current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContributionDrawer(
        goal: current,
        onConfirm: (amount) async {
          setState(() => _loading = true);
          try {
            await widget.onContribute(current, amount);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<AsyncState<List<Goal>>>(
      stream: widget.goalController.stream,
      initialData: widget.goalController.state,
      builder: (_, snap) {
        final g = _latestGoal(snap.data ?? widget.goalController.state);
        final color = g.colorHex != null
            ? Color(int.parse(g.colorHex!.replaceFirst('#', '0xff')))
            : AppColors.accent;
        final statusLabel = switch (g.status) {
          GoalStatus.completed => ('Completed', AppColors.success),
          GoalStatus.paused    => ('Paused', AppColors.warning),
          _                    => ('Active', color),
        };

        return _CompactFrame(
          isDark: isDark,
          title: g.name,
          trailing: _StatusPill(text: statusLabel.$1, color: statusLabel.$2),
          child: _GoalViewBody(
            goal: g,
            color: color,
            isDark: isDark,
            loading: _loading,
            onContribute: g.status != GoalStatus.completed
                ? () => _showContributeDrawer(g)
                : null,
          ),
        );
      },
    );
  }
}

class _GoalViewBody extends StatelessWidget {
  final Goal goal;
  final Color color;
  final bool isDark, loading;
  final VoidCallback? onContribute;

  const _GoalViewBody({
    required this.goal,
    required this.color,
    required this.isDark,
    required this.loading,
    required this.onContribute,
  });

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final progress = g.progress.clamp(0.0, 1.0);
    final isComplete = g.isCompleted;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Progress card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Saved', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              Text(
                currencyFormatter.format(g.currentAmount, decimalDigits: 2),
                style: GoogleFonts.dmMono(fontSize: 22, fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Target', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              Text(
                currencyFormatter.format(g.targetAmount, decimalDigits: 2),
                style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ]),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(isComplete ? AppColors.success : color),
            ),
          ),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${(progress * 100).round()}% saved', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
            Text(
              isComplete ? 'Goal reached!' : '${currencyFormatter.format(g.remainingAmount, decimalDigits: 2)} to go',
              style: GoogleFonts.dmSans(fontSize: 10, color: isComplete ? AppColors.success : AppColors.textSecondary),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      if (g.targetDate != null)
        _InfoRow(isDark: isDark, label: 'Target date', value: DateFormat('MMMM d, yyyy').format(g.targetDate!),
            sub: g.daysRemaining != null && g.daysRemaining! > 0 ? '${g.daysRemaining} days remaining' : null),
      if (g.monthlyContribution > 0)
        _InfoRow(isDark: isDark, label: 'Monthly', value: '${currencyFormatter.format(g.monthlyContribution, decimalDigits: 2)} / month'),
      if (g.savingsBucketId != null)
        _InfoRow(isDark: isDark, label: 'Linked to', value: 'Savings bucket', sub: 'Contributions update both goal & bucket balance'),
      const SizedBox(height: 20),
      _ActionButton(
        label: isComplete ? 'Goal Completed' : 'Add Contribution',
        icon: isComplete ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
        color: isComplete ? AppColors.success : color,
        loading: loading,
        onTap: onContribute,
      ),
    ]);
  }
}

class _ContributionDrawer extends StatefulWidget {
  final Goal goal;
  final Future<void> Function(double amount) onConfirm;

  const _ContributionDrawer({required this.goal, required this.onConfirm});

  @override
  State<_ContributionDrawer> createState() => _ContributionDrawerState();
}

class _ContributionDrawerState extends State<_ContributionDrawer> {
  late final TextEditingController _amtCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _amtCtrl = TextEditingController(
      text: widget.goal.monthlyContribution > 0
          ? widget.goal.monthlyContribution.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() { _amtCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final g = widget.goal;
    final color = g.colorHex != null
        ? Color(int.parse(g.colorHex!.replaceFirst('#', '0xff')))
        : AppColors.accent;
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    final amt = double.tryParse(_amtCtrl.text);
    final newTotal = amt != null ? (g.currentAmount + amt).clamp(0.0, double.infinity) : null;
    final newProgress = newTotal != null && g.targetAmount > 0 ? (newTotal / g.targetAmount).clamp(0.0, 1.0) : null;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 16, 0), child: Row(children: [
            Expanded(child: Text('Contribute to ${g.name}', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
          ])),
          if (g.savingsBucketId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(children: [
                Icon(Icons.link_rounded, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Also updates linked savings bucket', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ),
          Divider(height: 20, color: borderColor),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _amtCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${currencyFormatter.currencySymbol} ',
                border: const OutlineInputBorder(),
                helperText: g.monthlyContribution > 0 ? 'Planned: ${currencyFormatter.format(g.monthlyContribution, decimalDigits: 2)}/mo' : null,
              ),
            ),
            if (newProgress != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.trending_up_rounded, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    'Will reach ${(newProgress * 100).round()}% of goal',
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: color),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            _ActionButton(
              label: amt != null && amt > 0 ? 'Contribute ${currencyFormatter.format(amt, decimalDigits: 2)}' : 'Contribute',
              icon: Icons.add_circle_outline_rounded,
              color: color,
              loading: _loading,
              onTap: () async {
                final amount = double.tryParse(_amtCtrl.text);
                if (amount == null || amount <= 0) return;
                final nav = Navigator.of(context);
                setState(() => _loading = true);
                try {
                  await widget.onConfirm(amount);
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
                nav.pop();
              },
            ),
            const SizedBox(height: 8),
            _ActionButton(label: 'Cancel', icon: Icons.close_rounded, color: AppColors.textSecondary, outlined: true, onTap: () => Navigator.pop(context), isDark: isDark),
          ])),
        ])),
      ),
    );
  }
}

// ─── Compact Frame (shared by all detail sheets) ──────────────────────────────

class _CompactFrame extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Widget child;

  const _CompactFrame({required this.isDark, required this.title, required this.child, this.trailing, this.onBack});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 16, 0), child: Row(children: [
            if (onBack != null) ...[
              GestureDetector(onTap: onBack, child: Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppColors.textSecondary))),
            ],
            Expanded(child: Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
          ])),
          Divider(height: 20, color: borderColor),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: child),
        ])),
      ),
    );
  }
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final bool isDark;
  final String label, value;
  final String? sub;
  final Color? subColor, valueColor;

  const _InfoRow({required this.isDark, required this.label, required this.value, this.sub, this.subColor, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary))),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? textPrimary)),
          if (sub != null) Text(sub!, style: GoogleFonts.dmSans(fontSize: 11, color: subColor ?? AppColors.textSecondary)),
        ])),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading, outlined;
  final VoidCallback? onTap;
  final bool? isDark;

  const _ActionButton({required this.label, required this.icon, required this.color, this.loading = false, this.outlined = false, this.onTap, this.isDark});

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(width: double.infinity, height: 46,
        child: OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 15), label: Text(label),
          style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color.withValues(alpha: 0.4)),
            textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))));
    }
    return SizedBox(width: double.infinity, height: 46,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon, size: 15),
        label: Text(label),
        style: ElevatedButton.styleFrom(backgroundColor: onTap == null ? AppColors.textTertiary : color, foregroundColor: Colors.white, elevation: 0,
          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3)),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool isDark;
  final TextInputType? keyboardType;
  final int? maxLines;

  const _Field({required this.ctrl, required this.label, required this.isDark, this.keyboardType, this.maxLines});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl, keyboardType: keyboardType, maxLines: maxLines ?? 1,
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
  );
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}
