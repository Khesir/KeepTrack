import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Accounts Tab with Card Design
class AccountsTabNew extends StatefulWidget {
  const AccountsTabNew({super.key});

  @override
  State<AccountsTabNew> createState() => _AccountsTabNewState();
}

class _AccountsTabNewState extends State<AccountsTabNew> {
  @override
  Widget build(BuildContext context) {
    // Calculate total balance
    final totalBalance = dummyAccounts.fold<double>(
      0,
      (sum, account) => sum + account.balance,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Balance Summary Card
          _buildTotalBalanceCard(totalBalance),
          const SizedBox(height: 24),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Accounts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${dummyAccounts.length} accounts',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Accounts List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dummyAccounts.length,
            itemBuilder: (context, index) {
              final account = dummyAccounts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAccountCard(account),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard(double totalBalance) {
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(totalBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Across ${dummyAccounts.length} accounts',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(AccountItem account) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to account detail
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: account.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      account.icon,
                      color: account.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          account.type,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: account.isActive ? Colors.green[50] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      account.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: account.isActive ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Balance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(account.balance),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: account.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Income',
                      NumberFormat.compactCurrency(symbol: '₱').format(account.monthlyIncome),
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Expenses',
                      NumberFormat.compactCurrency(symbol: '₱').format(account.monthlyExpenses),
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Transactions',
                      '${account.transactionCount}',
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              // Last Transaction
              if (account.lastTransaction != null) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Last transaction: ${_formatDate(account.lastTransaction!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

// Account Data Class
class AccountItem {
  final String id;
  final String name;
  final String type;
  final double balance;
  final Color color;
  final IconData icon;
  final bool isActive;
  final double monthlyIncome;
  final double monthlyExpenses;
  final int transactionCount;
  final DateTime? lastTransaction;

  AccountItem({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    required this.icon,
    this.isActive = true,
    this.monthlyIncome = 0,
    this.monthlyExpenses = 0,
    this.transactionCount = 0,
    this.lastTransaction,
  });
}

// Dummy Account Data
final dummyAccounts = [
  AccountItem(
    id: '1',
    name: 'Main Wallet',
    type: 'Cash',
    balance: 45000.00,
    color: Colors.green[700]!,
    icon: Icons.account_balance_wallet,
    monthlyIncome: 85000,
    monthlyExpenses: 40000,
    transactionCount: 24,
    lastTransaction: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  AccountItem(
    id: '2',
    name: 'Savings Account',
    type: 'Bank Account',
    balance: 125000.00,
    color: Colors.blue[700]!,
    icon: Icons.savings,
    monthlyIncome: 5000,
    monthlyExpenses: 2000,
    transactionCount: 8,
    lastTransaction: DateTime.now().subtract(const Duration(days: 3)),
  ),
  AccountItem(
    id: '3',
    name: 'Credit Card',
    type: 'Credit',
    balance: -15000.00,
    color: Colors.red[700]!,
    icon: Icons.credit_card,
    monthlyIncome: 0,
    monthlyExpenses: 15000,
    transactionCount: 18,
    lastTransaction: DateTime.now().subtract(const Duration(days: 1)),
  ),
  AccountItem(
    id: '4',
    name: 'Investment Fund',
    type: 'Investment',
    balance: 250000.00,
    color: Colors.purple[700]!,
    icon: Icons.trending_up,
    monthlyIncome: 8500,
    monthlyExpenses: 0,
    transactionCount: 4,
    lastTransaction: DateTime.now().subtract(const Duration(days: 7)),
  ),
  AccountItem(
    id: '5',
    name: 'Emergency Fund',
    type: 'Savings',
    balance: 80000.00,
    color: Colors.orange[700]!,
    icon: Icons.security,
    isActive: true,
    monthlyIncome: 10000,
    monthlyExpenses: 0,
    transactionCount: 2,
    lastTransaction: DateTime.now().subtract(const Duration(days: 15)),
  ),
];
