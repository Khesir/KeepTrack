import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import '../finance/modules/debt/domain/entities/debt.dart';
import '../finance/modules/goal/domain/entities/goal.dart';
import '../finance/modules/subscriptions/domain/entities/subscription.dart';
import '../finance/modules/transaction/domain/entities/transaction.dart';
import '../finance/modules/finance_category/domain/entities/finance_category.dart';
import '../finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import '../finance/presentation/state/debt_controller.dart';
import '../finance/presentation/state/goal_controller.dart';
import '../finance/presentation/state/subscription_controller.dart';
import '../finance/presentation/state/transaction_controller.dart';
import '../finance/presentation/state/finance_category_controller.dart';

class LogsScreen extends ScopedScreen {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ScopedScreenState<LogsScreen>
    with AppLayoutControlled {
  late final TransactionController _controller;
  late final FinanceCategoryController _categoryController;
  Map<String, FinanceCategory> _categoriesMap = {};
  String _selectedFilter = 'All';

  static const _filters = ['All', 'Income', 'Expense', 'Transfer'];

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TransactionController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _categoryController.loadCategories();
    _controller.loadAllTransactions();

    _categoryController.stream.listen((state) {
      if (state is AsyncData<List<FinanceCategory>>) {
        setState(() {
          _categoriesMap = {for (final c in state.data) if (c.id != null) c.id!: c};
        });
      }
    });
  }

  @override
  void registerServices() {}

  @override
  void onReady() {
    configureLayout(title: 'Transaction Logs', showBottomNav: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(
          selected: _selectedFilter,
          filters: _filters,
          onSelect: (f) => setState(() => _selectedFilter = f),
        ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    return AsyncStreamBuilder<List<Transaction>>(
      state: _controller,
      builder: (context, transactions) {
        final filtered = _filter(transactions);
        if (transactions.isEmpty) return _empty('No transactions yet', 'Your transactions will appear here');
        if (filtered.isEmpty) return _empty('No $_selectedFilter transactions', 'Try a different filter');

        final sorted = [...filtered]..sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: sorted.length,
          itemBuilder: (context, i) {
            final t = sorted[i];
            final showHeader = i == 0 || !_sameDay(t.date, sorted[i - 1].date);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHeader) _DateHeader(date: t.date),
                _TransactionRow(
                  transaction: t,
                  category: t.financeCategoryId != null ? _categoriesMap[t.financeCategoryId] : null,
                  onDelete: () => _confirmDelete(t),
                  onEdit: () => _showEdit(t),
                ),
              ],
            );
          },
        );
      },
      loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, msg) => _errorState(msg),
    );
  }

  List<Transaction> _filter(List<Transaction> all) {
    switch (_selectedFilter) {
      case 'Income':
        return all.where((t) => t.type == TransactionType.income).toList();
      case 'Expense':
        return all.where((t) => t.type == TransactionType.expense).toList();
      case 'Transfer':
        return all.where((t) => t.type == TransactionType.transfer).toList();
      default:
        return all;
    }
  }

  Future<void> _confirmDelete(Transaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('This will delete the transaction permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && t.id != null) {
      if (t.goalId != null) {
        final goalCtrl = locator.get<GoalController>();
        await goalCtrl.withdrawFromGoal(t.goalId!, t.amount);
        final updated = (goalCtrl.data ?? []).where((g) => g.id == t.goalId).firstOrNull;
        if (updated != null && updated.status == GoalStatus.completed && updated.currentAmount < updated.targetAmount) {
          await goalCtrl.updateGoal(updated.copyWith(status: GoalStatus.active));
        }
      }
      if (t.debtId != null) {
        final debtCtrl = locator.get<DebtController>();
        final debt = (debtCtrl.data ?? []).where((d) => d.id == t.debtId).firstOrNull;
        if (debt != null) {
          final newRemaining = debt.remainingAmount + t.amount;
          await debtCtrl.updateDebt(debt.copyWith(
            remainingAmount: newRemaining,
            status: newRemaining > 0 ? DebtStatus.active : debt.status,
          ));
        }
      }
      if (t.subscriptionId != null) {
        final subCtrl = locator.get<SubscriptionController>();
        final sub = (subCtrl.data ?? []).where((s) => s.id == t.subscriptionId).firstOrNull;
        if (sub != null) {
          await subCtrl.updateSubscription(Subscription(
            id: sub.id, userId: sub.userId, name: sub.name, provider: sub.provider,
            amount: sub.amount, billingCycle: sub.billingCycle, status: sub.status,
            nextBillingDate: sub.nextBillingDate, lastBilledDate: null,
            budgetCategoryId: sub.budgetCategoryId, notes: sub.notes,
            colorHex: sub.colorHex, iconCodePoint: sub.iconCodePoint,
            budgetProfileId: sub.budgetProfileId,
          ));
        }
      }
      await _controller.deleteTransaction(t.id!);
      if (mounted) {
        AppToast.success(context, 'Transaction deleted');
      }
    }
  }

  void _showEdit(Transaction t) {
    final cat = t.financeCategoryId != null ? _categoriesMap[t.financeCategoryId] : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditSheet(
        transaction: t,
        currentCategory: cat,
        categories: _categoriesMap.values.toList(),
        onSave: (updated) async {
          await _controller.updateTransaction(updated);
          if (mounted) {
            AppToast.success(context, 'Transaction updated');
          }
        },
        onDelete: () => _confirmDelete(t),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _empty(String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text(sub, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _errorState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 52, color: AppColors.error.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text('Failed to load', style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text(msg, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _controller.loadAllTransactions,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}


class _FilterBar extends StatelessWidget {
  final String selected;
  final List<String> filters;
  final void Function(String) onSelect;

  const _FilterBar({
    required this.selected,
    required this.filters,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final active = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  f,
                  style: AppTextStyles.caption.copyWith(
                    color: active ? AppColors.textOnPrimary : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;

    final label = isToday
        ? 'Today'
        : isYesterday
            ? 'Yesterday'
            : DateFormat('EEEE, MMM d').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}


class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final FinanceCategory? category;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TransactionRow({
    required this.transaction,
    required this.category,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == TransactionType.income;
    final isExpense = t.type == TransactionType.expense;
    final color = isIncome ? AppColors.success : isExpense ? AppColors.error : AppColors.info;
    final display = isExpense ? t.totalCost : isIncome ? t.totalCost : t.amount;
    final sign = isIncome ? '+' : isExpense ? '-' : '';
    final catName = category?.name ?? 'Uncategorized';
    final catIcon = category?.type.icon ?? Icons.category_outlined;

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withValues(alpha: 0.1),
        child: Icon(Icons.delete_outline, color: AppColors.error, size: 22),
      ),
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text('This will delete the transaction permanently.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        return ok == true;
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(catIcon, size: 18, color: color),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.description ?? catName,
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          catName,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                        ),
                        if (t.hasFee) ...[
                          const SizedBox(width: 6),
                          Text(
                            '+${currencyFormatter.currencySymbol}${t.fee.toStringAsFixed(2)} fee',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Amount + time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${currencyFormatter.currencySymbol}${display.abs().toStringAsFixed(2)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(t.date),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _EditSheet extends StatefulWidget {
  final Transaction transaction;
  final FinanceCategory? currentCategory;
  final List<FinanceCategory> categories;
  final Future<void> Function(Transaction) onSave;
  final VoidCallback onDelete;

  const _EditSheet({
    required this.transaction,
    required this.currentCategory,
    required this.categories,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _feeCtrl;
  late DateTime _date;
  late TimeOfDay _time;
  late TransactionType _type;
  FinanceCategory? _category;
  bool _hasFee = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _descCtrl = TextEditingController(text: t.description ?? '');
    _amountCtrl = TextEditingController(text: t.amount.toStringAsFixed(2));
    _feeCtrl = TextEditingController(text: t.fee.toStringAsFixed(2));
    _date = t.date;
    _time = TimeOfDay.fromDateTime(t.date);
    _type = t.type;
    _category = widget.currentCategory;
    _hasFee = t.hasFee;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    final fee = _hasFee ? (double.tryParse(_feeCtrl.text) ?? 0.0) : 0.0;
    final dt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    setState(() => _saving = true);
    try {
      await widget.onSave(widget.transaction.copyWith(
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        amount: amount,
        fee: fee,
        date: dt,
        type: _type,
        financeCategoryId: _category?.id,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: $e');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('Edit Transaction', style: AppTextStyles.h4)),
                TextButton(
                  onPressed: _saving ? null : () {
                    Navigator.pop(context);
                    widget.onDelete();
                  },
                  child: const Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type toggle
            Center(
              child: SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.arrow_downward, size: 14)),
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_upward, size: 14)),
                  ButtonSegment(value: TransactionType.transfer, label: Text('Transfer'), icon: Icon(Icons.swap_horiz, size: 14)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<FinanceCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: widget.categories.map((c) => DropdownMenuItem(
                value: c,
                child: Row(children: [
                  Icon(c.type.icon, size: 16),
                  const SizedBox(width: 8),
                  Text(c.name),
                ]),
              )).toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            // Amount
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${currencyFormatter.currencySymbol} ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                      child: Text(DateFormat('MMM d, y').format(_date), style: AppTextStyles.bodySmall),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fee toggle
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _hasFee,
                    onChanged: (v) => setState(() => _hasFee = v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Include fee', style: AppTextStyles.bodySmall),
                if (_hasFee) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _feeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Fee',
                        prefixText: '${currencyFormatter.currencySymbol} ',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
