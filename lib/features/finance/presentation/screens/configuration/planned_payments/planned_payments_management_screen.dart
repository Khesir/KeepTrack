import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:persona_codex/features/finance/presentation/screens/configuration/planned_payments/widgets/planned_payment_dialog.dart';
import 'package:persona_codex/features/finance/presentation/state/planned_payment_controller.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';

import '../../../../modules/planned_payment/domain/entities/payment_enums.dart';

class PlannedPaymentsManagementScreen extends StatefulWidget {
  const PlannedPaymentsManagementScreen({super.key});

  @override
  State<PlannedPaymentsManagementScreen> createState() =>
      _PlannedPaymentsManagementScreenState();
}

class _PlannedPaymentsManagementScreenState
    extends State<PlannedPaymentsManagementScreen> {
  late final PlannedPaymentController _controller;
  late final SupabaseService supabaseService;
  @override
  void initState() {
    super.initState();
    _controller = locator.get<PlannedPaymentController>();
    supabaseService = locator.get<SupabaseService>();
    AppLogger.info(supabaseService.userId.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCreateEditDialog({PlannedPayment? payment}) {
    showDialog(
      context: context,
      builder: (_) => PlannedPaymentDialog(
        payment: payment,
        userId: supabaseService.userId!,
        onSave: (savedPayment) {
          if (payment != null) {
            _controller.updatePlannedPayment(savedPayment);
          } else {
            _controller.createPlannedPayment(savedPayment);
          }
        },
      ),
    );
  }

  void _deletePayment(PlannedPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Planned Payment'),
        content: Text('Are you sure you want to delete "${payment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _controller.deletePlannedPayment(payment.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Payment deleted')));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Planned Payments')),
      body: AsyncStreamBuilder<List<PlannedPayment>>(
        state: _controller,
        builder: (context, payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_repeat_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No planned payments yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up recurring and scheduled payments',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: payment.category.color,
                    child: Icon(payment.category.icon, color: Colors.white),
                  ),
                  title: Text(payment.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${payment.payee} • ${payment.frequency.name}'),
                      const SizedBox(height: 4),
                      Text(
                        '\$${payment.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: payment.category.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            payment.isUpcoming
                                ? Icons.warning_amber
                                : Icons.schedule,
                            size: 14,
                            color: payment.isUpcoming
                                ? Colors.orange
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Next: ${payment.nextPaymentDate.year}-${payment.nextPaymentDate.month.toString().padLeft(2, '0')}-${payment.nextPaymentDate.day.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: payment.isUpcoming
                                      ? Colors.orange
                                      : null,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showCreateEditDialog(payment: payment);
                      } else if (value == 'delete') {
                        _deletePayment(payment);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loadingBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.loadPlannedPayments(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Payment'),
      ),
    );
  }
}
