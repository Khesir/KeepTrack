import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';

class SubscriptionsTab extends StatefulWidget {
  const SubscriptionsTab({super.key});

  @override
  State<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<SubscriptionsTab> {
  late final SubscriptionController _controller;
  Subscription? _selected;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _controller = locator.get<SubscriptionController>();
  }

  void _showDialog({Subscription? sub}) {
    final userId = locator.get<AuthController>().currentUser?.id ?? '';
    showDialog(
      context: context,
      builder: (_) => _SubscriptionDialog(
        subscription: sub,
        userId: userId,
        onSave: (s) async {
          if (sub != null) {
            await _controller.updateSubscription(s);
            if (_selected?.id == s.id) setState(() => _selected = s);
          } else {
            await _controller.createSubscription(s);
          }
        },
        onDelete: sub != null ? () => _controller.deleteSubscription(sub.id!) : null,
      ),
    );
  }

  Future<void> _pay(Subscription sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Record Payment'),
        content: Text('Mark ${sub.name} as paid?\n\nThis will create a ${currencyFormatter.format(sub.amount, decimalDigits: 2)} expense transaction and advance the next billing date.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pay')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final updated = await _controller.pay(sub.id!);
      if (_selected?.id == sub.id) setState(() => _selected = updated);
      if (mounted) {
        AppToast.success(context, '${sub.name} marked as paid. Next billing: ${DateFormat('MMM d, y').format(updated.nextBillingDate)}');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Failed: $e');
    }
  }

  List<Subscription> _applyFilter(List<Subscription> all) => switch (_filter) {
        'Active' => all.where((s) => s.status == SubscriptionStatus.active).toList(),
        'Paused' => all.where((s) => s.status == SubscriptionStatus.paused).toList(),
        'Upcoming' => all.where((s) => s.isUpcoming && s.status == SubscriptionStatus.active).toList(),
        _ => all,
      };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= ResponsiveBreakpoints.desktop;
        return AsyncStreamBuilder<List<Subscription>>(
          state: _controller,
          builder: (context, all) {
            final filtered = _applyFilter(all);
            final totalMonthly = all
                .where((s) => s.status == SubscriptionStatus.active)
                .fold(0.0, (sum, s) => sum + s.monthlyEquivalent);
            final upcoming = all.where((s) => s.isUpcoming && s.status == SubscriptionStatus.active).length;

            if (isDesktop) {
              return _DesktopLayout(
                all: all,
                filtered: filtered,
                selected: _selected,
                totalMonthly: totalMonthly,
                upcomingCount: upcoming,
                filter: _filter,
                onFilterChange: (f) => setState(() { _filter = f; _selected = null; }),
                onSelect: (s) => setState(() => _selected = s),
                onAdd: () => _showDialog(),
                onEdit: (s) => _showDialog(sub: s),
                onPay: _pay,
              );
            }

            return _MobileLayout(
              all: all,
              filtered: filtered,
              totalMonthly: totalMonthly,
              upcomingCount: upcoming,
              filter: _filter,
              selected: _selected,
              onFilterChange: (f) => setState(() { _filter = f; _selected = null; }),
              onSelect: (s) => setState(() => _selected = s),
              onBack: () => setState(() => _selected = null),
              onAdd: () => _showDialog(),
              onEdit: (s) => _showDialog(sub: s),
              onPay: _pay,
            );
          },
          loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, msg) => Center(child: Text(msg)),
        );
      },
    );
  }
}


class _DesktopLayout extends StatelessWidget {
  final List<Subscription> all;
  final List<Subscription> filtered;
  final Subscription? selected;
  final double totalMonthly;
  final int upcomingCount;
  final String filter;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<Subscription> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<Subscription> onEdit;
  final Future<void> Function(Subscription) onPay;

  const _DesktopLayout({
    required this.all,
    required this.filtered,
    required this.selected,
    required this.totalMonthly,
    required this.upcomingCount,
    required this.filter,
    required this.onFilterChange,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final panelBg = isDark ? const Color(0xFF18181B) : AppColors.surface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: Container(
            decoration: BoxDecoration(
              color: panelBg,
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subscriptions', style: AppTextStyles.h4),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: onAdd,
                        tooltip: 'Add Subscription',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                          foregroundColor: AppColors.accent,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currencyFormatter.format(totalMonthly, decimalDigits: 2),
                          style: AppTextStyles.h2),
                      Text('per month · ${all.where((s) => s.status == SubscriptionStatus.active).length} active',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      if (upcomingCount > 0) ...[
                        const SizedBox(height: 4),
                        _Chip(label: '$upcomingCount due this week', color: AppColors.warning),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in ['All', 'Active', 'Upcoming', 'Paused']) ...[
                          _FilterChip(label: f, selected: filter == f, onTap: () => onFilterChange(f)),
                          const SizedBox(width: 5),
                        ],
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: borderColor),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState(filter: filter)
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                          itemBuilder: (_, i) => _SubRow(
                            sub: filtered[i],
                            isSelected: selected?.id == filtered[i].id,
                            onTap: () => onSelect(filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: selected == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.subscriptions_outlined, size: 48, color: AppColors.textDisabled),
                      const SizedBox(height: 12),
                      Text('Select a subscription',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : _DetailPanel(sub: selected!, onEdit: () => onEdit(selected!), onPay: () => onPay(selected!), onBack: null),
        ),
      ],
    );
  }
}


class _MobileLayout extends StatelessWidget {
  final List<Subscription> all;
  final List<Subscription> filtered;
  final double totalMonthly;
  final int upcomingCount;
  final String filter;
  final Subscription? selected;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<Subscription> onSelect;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final ValueChanged<Subscription> onEdit;
  final Future<void> Function(Subscription) onPay;

  const _MobileLayout({
    required this.all, required this.filtered, required this.totalMonthly,
    required this.upcomingCount, required this.filter, required this.selected,
    required this.onFilterChange, required this.onSelect, required this.onBack,
    required this.onAdd, required this.onEdit, required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    if (selected != null) {
      return _DetailPanel(
        sub: selected!,
        onBack: onBack,
        onEdit: () => onEdit(selected!),
        onPay: () => onPay(selected!),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final cardBg = isDark ? const Color(0xFF18181B) : AppColors.surface;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg, border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.subscriptions_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Monthly Cost', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        const Spacer(),
                        if (upcomingCount > 0) _Chip(label: '$upcomingCount due soon', color: AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(currencyFormatter.format(totalMonthly, decimalDigits: 2), style: AppTextStyles.display),
                    Text('${all.where((s) => s.status == SubscriptionStatus.active).length} active subscriptions',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in ['All', 'Active', 'Upcoming', 'Paused']) ...[
                      _FilterChip(label: f, selected: filter == f, onTap: () => onFilterChange(f)),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                _EmptyState(filter: filter)
              else
                Container(
                  decoration: BoxDecoration(
                    color: cardBg, border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < filtered.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: borderColor),
                        _SubRow(sub: filtered[i], isSelected: false, onTap: () => onSelect(filtered[i])),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16, right: 16,
          child: FloatingActionButton.extended(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Subscription'),
          ),
        ),
      ],
    );
  }
}


class _DetailHeader extends StatelessWidget {
  final Subscription sub;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const _DetailHeader({required this.sub, required this.onBack, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final color = _parseColor(sub.colorHex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, size: 20), onPressed: onBack,
              padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 10),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
            child: Icon(IconHelper.fromString(sub.iconCodePoint), color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(sub.name, style: AppTextStyles.h4, maxLines: 1, overflow: TextOverflow.ellipsis)),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}


class _DetailPanel extends StatelessWidget {
  final Subscription sub;
  final VoidCallback? onBack;
  final VoidCallback onEdit;
  final VoidCallback onPay;

  const _DetailPanel({required this.sub, this.onBack, required this.onEdit, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final cardBg = isDark ? const Color(0xFF18181B) : AppColors.surface;
    final color = _parseColor(sub.colorHex);
    final daysUntil = sub.nextBillingDate.difference(DateTime.now()).inDays;

    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg, border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Amount', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(currencyFormatter.format(sub.amount, decimalDigits: 2),
                              style: AppTextStyles.display.copyWith(color: color)),
                          Text(sub.billingCycle.displayName,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    _StatusBadge(status: sub.status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _InfoCard(
                      label: 'Next Billing',
                      value: DateFormat('MMM d, y').format(sub.nextBillingDate),
                      icon: Icons.calendar_today_outlined,
                      color: sub.isOverdue ? AppColors.error : sub.isUpcoming ? AppColors.warning : AppColors.textSecondary,
                      borderColor: borderColor, cardBg: cardBg,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _InfoCard(
                      label: 'Monthly Cost',
                      value: currencyFormatter.format(sub.monthlyEquivalent, decimalDigits: 2),
                      icon: Icons.repeat_outlined,
                      color: AppColors.info,
                      borderColor: borderColor, cardBg: cardBg,
                    )),
                  ],
                ),
                if (sub.provider != null) ...[
                  const SizedBox(height: 8),
                  _InfoCard(
                    label: 'Provider',
                    value: sub.provider!,
                    icon: Icons.business_outlined,
                    color: AppColors.textSecondary,
                    borderColor: borderColor, cardBg: cardBg,
                  ),
                ],
                if (sub.notes != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg, border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(sub.notes!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (sub.isOverdue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_outlined, size: 14, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text('Overdue by ${daysUntil.abs()} day${daysUntil.abs() == 1 ? '' : 's'}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (sub.status == SubscriptionStatus.active)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Mark as Paid'),
                style: FilledButton.styleFrom(
                  backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );

    if (onBack != null) {
      return Column(
        children: [
          _DetailHeader(sub: sub, onBack: onBack!, onEdit: onEdit),
          Divider(height: 1, color: borderColor),
          Expanded(child: content),
        ],
      );
    }
    return content;
  }
}


class _SubRow extends StatelessWidget {
  final Subscription sub;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubRow({required this.sub, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(sub.colorHex);
    final icon = IconHelper.fromString(sub.iconCodePoint);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.accent.withValues(alpha: 0.04);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? selectedBg : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(width: 3, height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                )),
            const SizedBox(width: 10),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(sub.billingCycle.displayName,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currencyFormatter.format(sub.amount, decimalDigits: 2),
                    style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w700)),
                if (sub.isUpcoming && sub.status == SubscriptionStatus.active)
                  _Chip(label: 'Due soon', color: AppColors.warning),
                if (sub.isOverdue)
                  _Chip(label: 'Overdue', color: AppColors.error),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _SubscriptionDialog extends StatefulWidget {
  final Subscription? subscription;
  final String userId;
  final Future<void> Function(Subscription) onSave;
  final Future<void> Function()? onDelete;

  const _SubscriptionDialog({
    this.subscription, required this.userId,
    required this.onSave, this.onDelete,
  });

  @override
  State<_SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<_SubscriptionDialog> {
  final _nameCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  BillingCycle _cycle = BillingCycle.monthly;
  SubscriptionStatus _status = SubscriptionStatus.active;
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.subscription;
    if (s != null) {
      _nameCtrl.text = s.name;
      _providerCtrl.text = s.provider ?? '';
      _amountCtrl.text = s.amount.toString();
      _notesCtrl.text = s.notes ?? '';
      _cycle = s.billingCycle;
      _status = s.status;
      _nextBillingDate = s.nextBillingDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _providerCtrl.dispose();
    _amountCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (_nameCtrl.text.trim().isEmpty || amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      final s = Subscription(
        id: widget.subscription?.id,
        userId: widget.userId,
        name: _nameCtrl.text.trim(),
        provider: _providerCtrl.text.trim().isEmpty ? null : _providerCtrl.text.trim(),
        amount: amount,
        billingCycle: _cycle,
        status: _status,
        nextBillingDate: _nextBillingDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        colorHex: widget.subscription?.colorHex,
        iconCodePoint: widget.subscription?.iconCodePoint,
      );
      await widget.onSave(s);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.subscription != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Subscription' : 'Add Subscription'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _providerCtrl,
                  decoration: const InputDecoration(labelText: 'Provider (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount', border: const OutlineInputBorder(),
                    prefixText: '${currencyFormatter.currencySymbol} ',
                  )),
              const SizedBox(height: 12),
              DropdownButtonFormField<BillingCycle>(
                value: _cycle,
                decoration: const InputDecoration(labelText: 'Billing Cycle', border: OutlineInputBorder()),
                items: BillingCycle.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
                onChanged: (v) { if (v != null) setState(() => _cycle = v); },
              ),
              const SizedBox(height: 12),
              if (isEdit) ...[
                DropdownButtonFormField<SubscriptionStatus>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: SubscriptionStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _status = v); },
                ),
                const SizedBox(height: 12),
              ],
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context, initialDate: _nextBillingDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setState(() => _nextBillingDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Next Billing Date', border: OutlineInputBorder()),
                  child: Text(DateFormat('MMM d, y').format(_nextBillingDate)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder())),
            ],
          ),
        ),
      ),
      actions: [
        if (isEdit && widget.onDelete != null)
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Subscription'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ));
              if (ok == true && mounted) {
                await widget.onDelete?.call();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}


class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(child: Column(children: [
      const Icon(Icons.subscriptions_outlined, size: 48, color: AppColors.textDisabled),
      const SizedBox(height: 10),
      Text(filter == 'All' ? 'No subscriptions yet' : 'No $filter subscriptions',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      if (filter == 'All') ...[
        const SizedBox(height: 4),
        Text('Tap + to track your first subscription',
            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
      ],
    ])),
  );
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, borderColor, cardBg;
  const _InfoCard({required this.label, required this.value, required this.icon,
      required this.color, required this.borderColor, required this.cardBg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: cardBg, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 4),
      Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(
        color: selected ? AppColors.accent : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      )),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
  );
}

class _StatusBadge extends StatelessWidget {
  final SubscriptionStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SubscriptionStatus.active => ('Active', AppColors.success),
      SubscriptionStatus.paused => ('Paused', AppColors.warning),
      SubscriptionStatus.cancelled => ('Cancelled', AppColors.error),
    };
    return _Chip(label: label, color: color);
  }
}

Color _parseColor(String? hex) {
  if (hex == null) return AppColors.accent;
  try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); } catch (_) { return AppColors.accent; }
}
