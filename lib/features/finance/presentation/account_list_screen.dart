import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import '../modules/account/domain/entities/account.dart';
import '../modules/transaction/domain/entities/transaction.dart' as finance_transaction;
import 'state/account_controller.dart';
import 'state/transaction_controller.dart';
import 'widgets/recent_transactions_card.dart';
import 'screens/create_edit_account_screen.dart';

/// Screen for displaying list of accounts
class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  late AccountController _accountController;
  late TransactionController _transactionController;

  @override
  void initState() {
    super.initState();
    _accountController = locator.get<AccountController>();
    _transactionController = locator.get<TransactionController>();
    _transactionController.loadRecentTransactions(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _accountController.loadAccounts();
          await _transactionController.loadRecentTransactions(limit: 5);
        },
        child: CustomScrollView(
          slivers: [
            // Recent Transactions Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    AsyncStreamBuilder<List<finance_transaction.Transaction>>(
                      state: _transactionController,
                      builder: (context, transactions) {
                        return RecentTransactionsCard(
                          transactions: transactions,
                        );
                      },
                      errorBuilder: (context, message) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Failed to load recent transactions',
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      },
                    ),
              ),
            ),

            // TODO: Planned Payments Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Planned Payments',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coming soon - track recurring payments',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Accounts Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Accounts',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Accounts List
            AsyncStreamBuilder<List<Account>>(
              state: _accountController,
              builder: (context, accounts) {
                final colorScheme = Theme.of(context).colorScheme;

                if (accounts.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No accounts yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first financial account',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Filter active accounts
                final activeAccounts = accounts
                    .where((a) => !a.isArchived)
                    .toList();
                final archivedAccounts = accounts
                    .where((a) => a.isArchived)
                    .toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < activeAccounts.length) {
                        final account = activeAccounts[index];
                        return _buildAccountCard(context, account);
                      } else if (index == activeAccounts.length &&
                          archivedAccounts.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            'Archived',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        );
                      } else {
                        final archivedIndex = index - activeAccounts.length - 1;
                        final account = archivedAccounts[archivedIndex];
                        return _buildAccountCard(
                          context,
                          account,
                          isArchived: true,
                        );
                      }
                    },
                    childCount:
                        activeAccounts.length +
                        archivedAccounts.length +
                        (archivedAccounts.isNotEmpty ? 1 : 0),
                  ),
                );
              },
              errorBuilder: (context, message) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load accounts',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _accountController.loadAccounts(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loadingBuilder: (context) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateAccount(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    Account account, {
    bool isArchived = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final accountColor = account.colorHex != null
        ? _parseColor(account.colorHex!)
        : Colors.blue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToEditAccount(context, account),
        onLongPress: () => _showAccountOptions(context, account),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accountColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: accountColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isArchived ? Colors.grey : null,
                        decoration: isArchived ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (account.bankAccountNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        account.bankAccountNumber!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (isArchived) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Archived',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${account.balance.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: account.balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Balance',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  void _navigateToCreateAccount(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEditAccountScreen()),
    );

    if (result == true) {
      await _accountController.loadAccounts();
    }
  }

  void _navigateToEditAccount(BuildContext context, Account account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditAccountScreen(account: account),
      ),
    );

    if (result == true) {
      await _accountController.loadAccounts();
    }
  }

  void _showAccountOptions(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditAccount(context, account);
              },
            ),
            ListTile(
              leading: Icon(
                account.isArchived ? Icons.unarchive : Icons.archive,
              ),
              title: Text(account.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () async {
                Navigator.pop(context);
                if (account.isArchived) {
                  await _accountController.unarchiveAccount(account.id!);
                } else {
                  await _accountController.archiveAccount(account.id!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await _showDeleteConfirmation(context);
                if (confirmed == true) {
                  await _accountController.deleteAccount(account.id!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete this account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
