import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:persona_codex/features/finance/presentation/screens/configuration/debts/widgets/debt_management_dialog.dart';
import 'package:persona_codex/features/finance/presentation/state/debt_controller.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';

class DebtsManagementScreen extends StatefulWidget {
  const DebtsManagementScreen({super.key});

  @override
  State<DebtsManagementScreen> createState() => _DebtsManagementScreenState();
}

class _DebtsManagementScreenState extends State<DebtsManagementScreen> {
  late final DebtController _controller;
  late final SupabaseService supabaseService;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<DebtController>();
    supabaseService = locator.get<SupabaseService>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCreateEditDialog({Debt? debt}) {
    showDialog(
      context: context,
      builder: (context) => DebtManagementDialog(
        debt: debt,
        userId: supabaseService.userId!,
        onSave: (savedDebt) => {
          if (debt != null)
            {_controller.updateDebt(savedDebt)}
          else
            {_controller.createDebt(savedDebt)},
        },
      ),
    );
  }

  void _deleteDebt(Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Debt'),
        content: Text(
          'Are you sure you want to delete the debt with "${debt.personName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _controller.deleteDebt(debt.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Debt deleted')));
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
      appBar: AppBar(title: const Text('Manage Debts')),
      body: AsyncStreamBuilder<List<Debt>>(
        state: _controller,
        builder: (context, debts) {
          if (debts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No debts yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your lending and borrowing',
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
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];
              final isLending = debt.type == DebtType.lending;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isLending ? Colors.green : Colors.orange,
                    child: Icon(
                      isLending ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(debt.personName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.description),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: debt.progress / 100,
                        backgroundColor:
                            (isLending ? Colors.green : Colors.orange)
                                .withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLending ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${debt.paidAmount.toStringAsFixed(2)} paid of \$${debt.originalAmount.toStringAsFixed(2)} (${debt.progress.toStringAsFixed(1)}%)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (debt.dueDate != null)
                        Text(
                          'Due: ${debt.dueDate!.year}-${debt.dueDate!.month.toString().padLeft(2, '0')}-${debt.dueDate!.day.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: debt.isOverdue ? Colors.red : null,
                              ),
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
                        _showCreateEditDialog(debt: debt);
                      } else if (value == 'delete') {
                        _deleteDebt(debt);
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
                onPressed: () => _controller.loadDebts(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Debt'),
      ),
    );
  }
}
