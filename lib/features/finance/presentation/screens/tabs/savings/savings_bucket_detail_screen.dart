import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/screens/configuration/savings/widget/savings_management_dialog.dart';
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

class SavingsBucketDetailScreen extends StatefulWidget {
  final SavingsBucket bucket;

  const SavingsBucketDetailScreen({super.key, required this.bucket});

  @override
  State<SavingsBucketDetailScreen> createState() => _SavingsBucketDetailScreenState();
}

class _SavingsBucketDetailScreenState extends State<SavingsBucketDetailScreen> {
  late final TransactionController _txController;
  late final SavingsController _savingsController;
  late SavingsBucket _bucket;

  @override
  void initState() {
    super.initState();
    _txController = locator.get<TransactionController>();
    _savingsController = locator.get<SavingsController>();
    _bucket = widget.bucket;
    _txController.loadTransactionsBySavings(_bucket.id!);

    _savingsController.stream.listen((state) {
      if (state is AsyncData<List<SavingsBucket>>) {
        final updated = state.data.where((b) => b.id == _bucket.id).firstOrNull;
        if (updated != null && mounted) setState(() => _bucket = updated);
      }
    });
  }

  Color get _bucketColor => _bucket.colorHex != null
      ? Color(int.parse(_bucket.colorHex!.replaceFirst('#', '0xff')))
      : AppColors.primary;

  void _showEditDialog() {
    final userId = locator.get<AuthController>().currentUser?.id ?? '';
    showDialog(
      context: context,
      builder: (_) => SavingsManagementDialog(
        bucket: _bucket,
        userId: userId,
        onSave: (b) => _savingsController.updateSavingsBucket(b),
        onDelete: () async {
          await _savingsController.deleteSavingsBucket(_bucket.id!);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showAddEntrySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddEntrySheet(
        bucket: _bucket,
        onSave: (tx) async {
          await _txController.createTransaction(tx);
          final newBalance = _bucket.balance +
              (tx.type == TransactionType.income ? tx.amount : -tx.amount);
          await _savingsController.updateSavingsBucket(
            _bucket.copyWith(balance: newBalance),
          );
          _txController.loadTransactionsBySavings(_bucket.id!);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_bucket.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _showEditDialog),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntrySheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
      body: Column(
        children: [
          _BucketHeader(bucket: _bucket, color: _bucketColor),
          const Divider(height: 1),
          Expanded(
            child: StreamStateBuilder<AsyncState<List<Transaction>>>(
              state: _txController,
              builder: (context, state) {
                if (state is AsyncLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AsyncError) {
                  return Center(child: Text((state as AsyncError).message));
                }
                final transactions = (state as AsyncData<List<Transaction>>).data
                  ..sort((a, b) => b.date.compareTo(a.date));
                if (transactions.isEmpty) return _buildEmpty();
                return _buildLog(transactions);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('No entries yet', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Text(
            'Tap + to record a deposit or withdrawal',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLog(List<Transaction> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: transactions.length,
      itemBuilder: (context, i) {
        final t = transactions[i];
        final showHeader = i == 0 ||
            !_sameDay(t.date, transactions[i - 1].date);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) _DateHeader(date: t.date),
            _EntryRow(transaction: t),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _BucketHeader extends StatelessWidget {
  final SavingsBucket bucket;
  final Color color;

  const _BucketHeader({required this.bucket, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: color.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Balance', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            '${currencyFormatter.currencySymbol} ${bucket.balance.toStringAsFixed(2)}',
            style: AppTextStyles.h2.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        DateFormat('MMMM d, y').format(date),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final Transaction transaction;

  const _EntryRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction.type == TransactionType.income;
    final color = isDeposit ? AppColors.success : AppColors.error;
    final sign = isDeposit ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? (isDeposit ? 'Deposit' : 'Withdrawal'),
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('h:mm a').format(transaction.date),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '$sign${currencyFormatter.currencySymbol} ${transaction.amount.toStringAsFixed(2)}',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEntrySheet extends StatefulWidget {
  final SavingsBucket bucket;
  final Future<void> Function(Transaction) onSave;

  const _AddEntrySheet({required this.bucket, required this.onSave});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TransactionType _type = TransactionType.income;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      final tx = Transaction(
        amount: amount,
        type: _type,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        date: DateTime.now(),
        savingsId: widget.bucket.id,
      );
      await widget.onSave(tx);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text('Add Entry', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(widget.bucket.name, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Center(
              child: SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Deposit'),
                    icon: Icon(Icons.arrow_downward, size: 14),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Withdrawal'),
                    icon: Icon(Icons.arrow_upward, size: 14),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${currencyFormatter.currencySymbol} ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
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
