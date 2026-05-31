import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';
import '../../../../modules/debt/domain/entities/debt.dart';
import '../../../state/debt_controller.dart';
import 'debt_history_screen.dart';

class DebtsTabNew extends StatefulWidget {
  const DebtsTabNew({super.key});

  @override
  State<DebtsTabNew> createState() => _DebtsTabNewState();
}

class _DebtsTabNewState extends State<DebtsTabNew> {
  late final DebtController _controller;
  Debt? _selected;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _controller = locator.get<DebtController>();
  }

  List<Debt> _applyFilter(List<Debt> all) => switch (_filter) {
        'Lending' => all.where((d) => d.type == DebtType.lending).toList(),
        'Borrowing' => all.where((d) => d.type == DebtType.borrowing).toList(),
        'Overdue' => all.where((d) => d.isOverdue).toList(),
        _ => all,
      }..sort((a, b) {
          int priority(DebtStatus s) => switch (s) {
                DebtStatus.overdue => 0,
                DebtStatus.active => 1,
                _ => 2,
              };
          return priority(a.status).compareTo(priority(b.status));
        });

  Future<void> _showRecordPayment(Debt debt) async {
    final amountCtrl = TextEditingController(
      text: debt.monthlyPaymentAmount > 0 ? debt.monthlyPaymentAmount.toStringAsFixed(2) : '',
    );
    final feeCtrl = TextEditingController();
    final isLending = debt.type == DebtType.lending;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isLending ? 'Collect from ${debt.personName}' : 'Pay ${debt.personName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${currencyFormatter.currencySymbol} ',
                  border: const OutlineInputBorder(),
                  hintText: debt.monthlyPaymentAmount > 0
                      ? 'Suggested: ${debt.monthlyPaymentAmount.toStringAsFixed(2)}'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Fee (optional)',
                  prefixText: '${currencyFormatter.currencySymbol} ',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (amount == null || amount <= 0) {
                AppToast.error(ctx, 'Enter a valid amount');
                return;
              }
              if (amount > debt.remainingAmount) {
                AppToast.error(ctx, 'Cannot exceed remaining ${currencyFormatter.format(debt.remainingAmount, decimalDigits: 2)}');
                return;
              }
              try {
                final fee = double.tryParse(feeCtrl.text) ?? 0;
                await ApiClient.instance.post('/debts/${debt.id}/pay', data: {
                  'amount': amount,
                  if (fee > 0) 'fee': fee,
                });
                _controller.loadDebts();
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) AppToast.error(ctx, 'Failed: $e');
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );

    amountCtrl.dispose();
    feeCtrl.dispose();

    if (ok == true && mounted) {
      AppToast.success(context, 'Payment recorded');
      if (_selected != null) {
        final updated = _controller.data?.where((d) => d.id == _selected!.id).firstOrNull;
        if (updated != null) setState(() => _selected = updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= ResponsiveBreakpoints.desktop;
        return AsyncStreamBuilder<List<Debt>>(
          state: _controller,
          builder: (context, debts) {
            final filtered = _applyFilter(debts);
            final totalLending = debts.where((d) => d.type == DebtType.lending)
                .fold(0.0, (s, d) => s + d.remainingAmount);
            final totalBorrowing = debts.where((d) => d.type == DebtType.borrowing)
                .fold(0.0, (s, d) => s + d.remainingAmount);
            final overdueCount = debts.where((d) => d.isOverdue).length;

            if (isDesktop) {
              return _DesktopLayout(
                debts: filtered,
                totalLending: totalLending,
                totalBorrowing: totalBorrowing,
                overdueCount: overdueCount,
                filter: _filter,
                selected: _selected,
                onFilterChange: (f) => setState(() { _filter = f; _selected = null; }),
                onSelect: (d) => setState(() => _selected = d),
                onRecord: _showRecordPayment,
                onHistory: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtHistoryScreen())),
              );
            }

            if (_selected != null) {
              return _DetailPanel(
                debt: _selected!,
                onBack: () => setState(() => _selected = null),
                onRecord: () => _showRecordPayment(_selected!),
              );
            }

            return _MobileListView(
              debts: filtered,
              totalLending: totalLending,
              totalBorrowing: totalBorrowing,
              overdueCount: overdueCount,
              filter: _filter,
              onFilterChange: (f) => setState(() => _filter = f),
              onSelect: (d) => setState(() => _selected = d),
              onHistory: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtHistoryScreen())),
            );
          },
          loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, msg) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load', style: AppTextStyles.h4),
                const SizedBox(height: 6),
                Text(msg, textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _controller.loadDebts(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Desktop Layout ────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final List<Debt> debts;
  final double totalLending, totalBorrowing;
  final int overdueCount;
  final String filter;
  final Debt? selected;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<Debt> onSelect;
  final Future<void> Function(Debt) onRecord;
  final VoidCallback onHistory;

  const _DesktopLayout({
    required this.debts, required this.totalLending, required this.totalBorrowing,
    required this.overdueCount, required this.filter, required this.selected,
    required this.onFilterChange, required this.onSelect,
    required this.onRecord, required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final panelBg = isDark ? const Color(0xFF18181B) : AppColors.surface;
    final net = totalLending - totalBorrowing;

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
                      Text('Debts & Lending', style: AppTextStyles.h4),
                      IconButton(
                        icon: const Icon(Icons.history, size: 20),
                        tooltip: 'History',
                        onPressed: onHistory,
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
                      Text(
                        '${net >= 0 ? '+' : ''}${currencyFormatter.format(net, decimalDigits: 2)}',
                        style: AppTextStyles.h2.copyWith(
                          color: net >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text('Net balance', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Chip(label: '↑ ${currencyFormatter.format(totalLending, decimalDigits: 0)} out', color: AppColors.success),
                          const SizedBox(width: 6),
                          _Chip(label: '↓ ${currencyFormatter.format(totalBorrowing, decimalDigits: 0)} owed', color: AppColors.error),
                          if (overdueCount > 0) ...[
                            const SizedBox(width: 6),
                            _Chip(label: '$overdueCount overdue', color: AppColors.warning),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in ['All', 'Lending', 'Borrowing', 'Overdue']) ...[
                          _FilterChip(label: f, selected: filter == f, onTap: () => onFilterChange(f)),
                          const SizedBox(width: 5),
                        ],
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: borderColor),
                Expanded(
                  child: debts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.swap_horiz, size: 40, color: AppColors.textDisabled),
                              const SizedBox(height: 8),
                              Text('No debts', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: debts.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                          itemBuilder: (_, i) => _DebtRow(
                            debt: debts[i],
                            isSelected: selected?.id == debts[i].id,
                            onTap: () => onSelect(debts[i]),
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
                      const Icon(Icons.swap_horiz, size: 48, color: AppColors.textDisabled),
                      const SizedBox(height: 12),
                      Text('Select a debt to view details',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : _DetailPanel(debt: selected!, onRecord: () => onRecord(selected!)),
        ),
      ],
    );
  }
}

// ─── Mobile List View ──────────────────────────────────────────────────────────

class _MobileListView extends StatelessWidget {
  final List<Debt> debts;
  final double totalLending, totalBorrowing;
  final int overdueCount;
  final String filter;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<Debt> onSelect;
  final VoidCallback onHistory;

  const _MobileListView({
    required this.debts, required this.totalLending, required this.totalBorrowing,
    required this.overdueCount, required this.filter,
    required this.onFilterChange, required this.onSelect, required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final cardBg = isDark ? const Color(0xFF18181B) : AppColors.surface;
    final net = totalLending - totalBorrowing;

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
                        const Icon(Icons.swap_horiz, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Net Balance', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        const Spacer(),
                        if (overdueCount > 0) _Chip(label: '$overdueCount overdue', color: AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${net >= 0 ? '+' : ''}${currencyFormatter.format(net, decimalDigits: 2)}',
                      style: AppTextStyles.display.copyWith(
                        color: net >= 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Chip(label: 'Lent ${currencyFormatter.format(totalLending, decimalDigits: 0)}', color: AppColors.success),
                        const SizedBox(width: 6),
                        _Chip(label: 'Owe ${currencyFormatter.format(totalBorrowing, decimalDigits: 0)}', color: AppColors.error),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in ['All', 'Lending', 'Borrowing', 'Overdue']) ...[
                      _FilterChip(label: f, selected: filter == f, onTap: () => onFilterChange(f)),
                      const SizedBox(width: 6),
                    ],
                    Text('${debts.length}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (debts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.swap_horiz, size: 48, color: AppColors.textDisabled),
                        const SizedBox(height: 10),
                        Text(filter == 'All' ? 'No debts yet' : 'No $filter debts',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: cardBg, border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < debts.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: borderColor),
                        _DebtRow(debt: debts[i], isSelected: false, onTap: () => onSelect(debts[i])),
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
            onPressed: onHistory,
            icon: const Icon(Icons.history),
            label: const Text('History'),
          ),
        ),
      ],
    );
  }
}

// ─── Detail Panel ──────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  final Debt debt;
  final VoidCallback? onBack;
  final VoidCallback onRecord;

  const _DetailPanel({required this.debt, this.onBack, required this.onRecord});

  Color get _color => debt.type == DebtType.lending ? AppColors.success : AppColors.error;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final cardBg = isDark ? const Color(0xFF18181B) : AppColors.surface;
    final progress = debt.progress;
    final daysUntil = debt.dueDate?.difference(DateTime.now()).inDays;

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
                          Text('Remaining', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(currencyFormatter.format(debt.remainingAmount, decimalDigits: 2),
                              style: AppTextStyles.display.copyWith(color: _color)),
                          Text('of ${currencyFormatter.format(debt.originalAmount, decimalDigits: 2)}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _color.withValues(alpha: 0.2)),
                      ),
                      child: Text('${(progress * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.h4.copyWith(color: _color)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: _color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(_color),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  debt.paidAmount > 0
                      ? '${currencyFormatter.format(debt.paidAmount, decimalDigits: 2)} paid'
                      : 'No payments yet',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (debt.dueDate != null)
                Expanded(child: _InfoCard(
                  label: 'Due Date',
                  value: DateFormat('MMM d, y').format(debt.dueDate!),
                  icon: Icons.calendar_today_outlined,
                  color: debt.isOverdue ? AppColors.error : (daysUntil != null && daysUntil <= 7 ? AppColors.warning : AppColors.textSecondary),
                  borderColor: borderColor, cardBg: cardBg,
                )),
              if (debt.dueDate != null && debt.monthlyPaymentAmount > 0) const SizedBox(width: 8),
              if (debt.monthlyPaymentAmount > 0)
                Expanded(child: _InfoCard(
                  label: 'Monthly',
                  value: currencyFormatter.format(debt.monthlyPaymentAmount, decimalDigits: 2),
                  icon: Icons.repeat_outlined,
                  color: AppColors.info,
                  borderColor: borderColor, cardBg: cardBg,
                )),
            ],
          ),
          if (debt.description.isNotEmpty) ...[
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
                  Expanded(child: Text(debt.description,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
                ],
              ),
            ),
          ],
          if (debt.notes != null && debt.notes!.isNotEmpty) ...[
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
                  const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(debt.notes!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
                ],
              ),
            ),
          ],
          if (debt.isOverdue) ...[
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
                  Text(
                    daysUntil != null ? 'Overdue by ${daysUntil.abs()} day${daysUntil.abs() == 1 ? '' : 's'}' : 'Overdue',
                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ],
          if (debt.status == DebtStatus.active) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRecord,
                icon: const Icon(Icons.add, size: 16),
                label: Text(debt.type == DebtType.lending ? 'Record Collection' : 'Record Payment'),
                style: FilledButton.styleFrom(
                  backgroundColor: _color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onBack != null) {
      return Column(
        children: [
          _DetailHeader(debt: debt, onBack: onBack!, color: _color, borderColor: borderColor),
          Expanded(child: content),
        ],
      );
    }
    return Column(
      children: [
        _DetailHeader(debt: debt, onBack: null, color: _color, borderColor: borderColor),
        Expanded(child: content),
      ],
    );
  }
}

// ─── Detail Header ─────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final Debt debt;
  final VoidCallback? onBack;
  final Color color, borderColor;

  const _DetailHeader({required this.debt, required this.onBack, required this.color, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(icon: const Icon(Icons.arrow_back, size: 20), onPressed: onBack,
                padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            const SizedBox(width: 12),
          ],
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(debt.type == DebtType.lending ? Icons.call_made : Icons.call_received, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(debt.personName, style: AppTextStyles.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(debt.type.displayName,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(status: debt.status),
        ],
      ),
    );
  }
}

// ─── Debt List Row ─────────────────────────────────────────────────────────────

class _DebtRow extends StatelessWidget {
  final Debt debt;
  final bool isSelected;
  final VoidCallback onTap;

  const _DebtRow({required this.debt, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLending = debt.type == DebtType.lending;
    final color = isLending ? AppColors.success : AppColors.error;
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
              child: Icon(isLending ? Icons.call_made : Icons.call_received, color: color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(debt.personName,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: debt.progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(debt.remainingAmount, decimalDigits: 0),
                  style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                if (debt.isOverdue)
                  _Chip(label: 'Overdue', color: AppColors.error)
                else
                  _StatusBadge(status: debt.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────────

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
  final DebtStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DebtStatus.active => ('Active', AppColors.info),
      DebtStatus.overdue => ('Overdue', AppColors.error),
      DebtStatus.settled => ('Settled', AppColors.success),
    };
    return _Chip(label: label, color: color);
  }
}
