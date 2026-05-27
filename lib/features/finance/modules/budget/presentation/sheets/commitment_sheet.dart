import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/presentation/state/planned_payment_controller.dart';
import '../../../planned_payment/domain/entities/planned_payment.dart';
import '../helpers/currency_formatter.dart';

class CommitmentsSheet extends StatelessWidget {
  final List<PlannedPayment> payments;
  final PlannedPaymentController plannedPaymentController;

  const CommitmentsSheet({
    super.key,
    required this.payments,
    required this.plannedPaymentController,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text('Upcoming Commitments', style: AppTextStyles.h4),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: payments.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, i) => _CommitmentTile(
                payment: payments[i],
                plannedPaymentController: plannedPaymentController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitmentTile extends StatelessWidget {
  final PlannedPayment payment;
  final PlannedPaymentController plannedPaymentController;

  const _CommitmentTile({
    required this.payment,
    required this.plannedPaymentController,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d').format(payment.nextPaymentDate);

    return ListTile(
      title: Text(
        payment.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${payment.payee} · $dateStr · ${payment.frequency.displayName}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatCurrency(payment.amount),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => _showRecordDialog(context, payment),
            child: const Text('Record'),
          ),
          TextButton(
            onPressed: () => _skipPayment(context, payment),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecordDialog(
    BuildContext context,
    PlannedPayment payment,
  ) async {
    final amountCtrl = TextEditingController(
      text: payment.amount.toStringAsFixed(2),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Record: ${payment.name}'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₱',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount')),
                );
                return;
              }
              try {
                await ApiClient.instance.post(
                  '/planned-payments/${payment.id}/pay',
                  data: {
                    'paidDate': DateTime.now().toIso8601String(),
                    'createTransaction': true,
                  },
                );
                plannedPaymentController.loadPlannedPayments();
                if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
              } catch (e) {
                if (dialogCtx.mounted) {
                  ScaffoldMessenger.of(
                    dialogCtx,
                  ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment recorded')));
    }
    amountCtrl.dispose();
  }

  Future<void> _skipPayment(
    BuildContext context,
    PlannedPayment payment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip Payment'),
        content: Text(
          'Skip "${payment.name}"? Next payment date will advance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
    if (confirmed == true && payment.id != null) {
      await plannedPaymentController.recordPayment(payment.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment skipped')));
      }
    }
  }
}
