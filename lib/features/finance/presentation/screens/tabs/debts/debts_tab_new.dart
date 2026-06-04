import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/screens/configuration/debts/widgets/debt_management_dialog.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
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
  late final WalletController _walletController;
  Debt? _selected;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _controller = locator.get<DebtController>();
    _walletController = locator.get<WalletController>();
  }

  void _showEditDialog(Debt debt) {
    showDialog(
      context: context,
      builder: (_) => DebtManagementDialog(
        debt: debt,
        wallets: _walletController.wallets,
        onSave: (updated, wallet) => _controller.updateDebt(updated),
      ),
    );
  }

  void _showDeleteConfirmation(Debt debt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Delete "${debt.personName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              _controller.deleteDebt(debt.id!);
              Navigator.pop(context);
              if (_selected?.id == debt.id) setState(() => _selected = null);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<Debt> _applyFilter(List<Debt> all) {
    if (_filter == 'Settled') {
      return all.where((d) => d.status == DebtStatus.settled).toList()
        ..sort((a, b) {
          final aDate = a.settledAt ?? a.updatedAt ?? a.startDate;
          final bDate = b.settledAt ?? b.updatedAt ?? b.startDate;
          return bDate.compareTo(aDate);
        });
    }
    final active = switch (_filter) {
      'Lending' => all.where((d) => d.type == DebtType.lending && d.status != DebtStatus.settled),
      'Borrowing' => all.where((d) => d.type == DebtType.borrowing && d.status != DebtStatus.settled),
      'Overdue' => all.where((d) => d.isOverdue),
      _ => all.where((d) => d.status != DebtStatus.settled),
    };
    return active.toList()
      ..sort((a, b) {
        int priority(DebtStatus s) => switch (s) {
          DebtStatus.overdue => 0,
          DebtStatus.active => 1,
          _ => 2,
        };
        return priority(a.status).compareTo(priority(b.status));
      });
  }

  Future<void> _showRecordPayment(Debt debt) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordPaymentSheet(
        debt: debt,
        onSave: (amount, wallet, fee) async {
          await _controller.payDebtWithTransaction(
            debt,
            amount: amount,
            wallet: wallet,
            fee: fee,
          );
        },
      ),
    );
    if (mounted) {
      final updated = _controller.data?.where((d) => d.id == debt.id).firstOrNull;
      if (updated != null) setState(() => _selected = updated);
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
                onEdit: _showEditDialog,
                onDelete: _showDeleteConfirmation,
                onHistory: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtHistoryScreen())),
              );
            }

            if (_selected != null) {
              return _DetailPanel(
                debt: _selected!,
                onBack: () => setState(() => _selected = null),
                onRecord: () => _showRecordPayment(_selected!),
                onEdit: _showEditDialog,
                onDelete: _showDeleteConfirmation,
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


class _DesktopLayout extends StatelessWidget {
  final List<Debt> debts;
  final double totalLending, totalBorrowing;
  final int overdueCount;
  final String filter;
  final Debt? selected;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<Debt> onSelect;
  final Future<void> Function(Debt) onRecord;
  final void Function(Debt) onEdit;
  final void Function(Debt) onDelete;
  final VoidCallback onHistory;

  const _DesktopLayout({
    required this.debts, required this.totalLending, required this.totalBorrowing,
    required this.overdueCount, required this.filter, required this.selected,
    required this.onFilterChange, required this.onSelect,
    required this.onRecord, required this.onEdit, required this.onDelete,
    required this.onHistory,
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
                        for (final f in ['All', 'Lending', 'Borrowing', 'Overdue', 'Settled']) ...[
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
              : _DetailPanel(debt: selected!, onRecord: () => onRecord(selected!), onEdit: onEdit, onDelete: onDelete),
        ),
      ],
    );
  }
}


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
                    for (final f in ['All', 'Lending', 'Borrowing', 'Overdue', 'Settled']) ...[
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


class _DetailPanel extends StatelessWidget {
  final Debt debt;
  final VoidCallback? onBack;
  final VoidCallback onRecord;
  final void Function(Debt) onEdit;
  final void Function(Debt) onDelete;

  const _DetailPanel({
    required this.debt,
    this.onBack,
    required this.onRecord,
    required this.onEdit,
    required this.onDelete,
  });

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
          if (debt.status == DebtStatus.settled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onEdit(debt),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onDelete(debt),
                    icon: const Icon(Icons.delete_outline, size: 15),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
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
    return Column(children: [
      _DetailHeader(debt: debt, onBack: null, color: _color, borderColor: borderColor),
      Expanded(child: content),
    ]);
  }
}


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
                else if (debt.status == DebtStatus.settled)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusBadge(status: debt.status),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
                    ],
                  )
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

// ---------------------------------------------------------------------------

class _RecordPaymentSheet extends StatefulWidget {
  final Debt debt;
  final Future<void> Function(double amount, Wallet wallet, double fee) onSave;

  const _RecordPaymentSheet({required this.debt, required this.onSave});

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();

  late final WalletController _walletController;

  Wallet? _wallet;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _walletController = locator.get<WalletController>();
    if (widget.debt.monthlyPaymentAmount > 0) {
      _amountCtrl.text = widget.debt.monthlyPaymentAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  bool get _isLending => widget.debt.type == DebtType.lending;
  Color get _typeColor => _isLending ? AppColors.success : AppColors.error;

  bool get _canSave {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    return amount > 0 &&
        amount <= widget.debt.remainingAmount &&
        _wallet != null;
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    final amount = double.parse(_amountCtrl.text);
    final fee = double.tryParse(_feeCtrl.text) ?? 0;
    setState(() => _saving = true);
    try {
      await widget.onSave(amount, _wallet!, fee);
      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, 'Payment recorded');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed: $e');
        setState(() => _saving = false);
      }
    }
  }

  void _pickWallet(List<Wallet> wallets, bool isDark) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Select Wallet', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 12),
          ...wallets.map((w) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.account_balance_wallet_outlined, color: _typeColor),
            title: Text(w.name, style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary)),
            subtitle: Text(currencyFormatter.format(w.balance), style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
            trailing: _wallet?.id == w.id ? Icon(Icons.check_rounded, color: _typeColor, size: 18) : null,
            onTap: () { setState(() => _wallet = w); Navigator.pop(context); },
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.void_ : Colors.white;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;


    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(_isLending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 20, color: _typeColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_isLending ? 'Collect from ${widget.debt.personName}' : 'Pay ${widget.debt.personName}',
                  style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
              Text('Remaining: ${currencyFormatter.format(widget.debt.remainingAmount)}',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 20),

          // Amount
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Amount *',
              prefixText: '${currencyFormatter.currencySymbol} ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
              hintText: widget.debt.monthlyPaymentAmount > 0 ? 'Suggested: ${widget.debt.monthlyPaymentAmount.toStringAsFixed(2)}' : null,
            ),
          ),
          const SizedBox(height: 12),

          // Fee
          TextField(
            controller: _feeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Fee (optional)',
              prefixText: '${currencyFormatter.currencySymbol} ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
            ),
          ),
          const SizedBox(height: 12),

          // Wallet picker
          AsyncStreamBuilder<List<Wallet>>(
            state: _walletController,
            builder: (_, wallets) => GestureDetector(
              onTap: () => _pickWallet(wallets, isDark),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: _wallet != null ? _typeColor.withValues(alpha: 0.4) : border, width: _wallet != null ? 1 : 0.5),
                  borderRadius: BorderRadius.circular(10),
                  color: _wallet != null ? _typeColor.withValues(alpha: 0.04) : Colors.transparent,
                ),
                child: Row(children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 16,
                      color: _wallet != null ? _typeColor : AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_wallet?.name ?? 'Select wallet *',
                      style: GoogleFonts.dmSans(fontSize: 14, color: _wallet != null ? textPrimary : AppColors.textSecondary))),
                  Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
                ]),
              ),
            ),
            loadingBuilder: (_) => const SizedBox.shrink(),
            errorBuilder: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _canSave && !_saving ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: _canSave ? _typeColor : AppColors.textTertiary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isLending ? 'Record Collection' : 'Record Payment',
                      style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
