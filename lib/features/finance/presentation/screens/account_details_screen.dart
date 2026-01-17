import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

/// Daily finance data for bar graph
class DailyAccountData {
  final DateTime date;
  final double income;
  final double expense;
  final double transfer;

  DailyAccountData({
    required this.date,
    required this.income,
    required this.expense,
    required this.transfer,
  });
}

class AccountDetailsScreen extends ScopedScreen {
  final Account account;

  const AccountDetailsScreen({super.key, required this.account});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ScopedScreenState<AccountDetailsScreen>
    with AppLayoutControlled {
  late final TransactionController _transactionController;
  int _daysToShow = 15;

  @override
  void registerServices() {
    _transactionController = locator.get<TransactionController>();
  }

  @override
  void onReady() {
    configureLayout(title: widget.account.name, showBottomNav: false);
    _transactionController.loadTransactionsByAccount(widget.account.id!);
  }

  List<DailyAccountData> _processTransactionsToDaily(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: _daysToShow - 1));

    // Create a map with all dates initialized to zero
    final Map<String, DailyAccountData> dailyMap = {};
    for (int i = 0; i < _daysToShow; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      dailyMap[dateKey] = DailyAccountData(
        date: date,
        income: 0,
        expense: 0,
        transfer: 0,
      );
    }

    // Aggregate transactions by date
    for (final transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (dailyMap.containsKey(dateKey)) {
        final existing = dailyMap[dateKey]!;
        switch (transaction.type) {
          case TransactionType.income:
            dailyMap[dateKey] = DailyAccountData(
              date: existing.date,
              income: existing.income + transaction.amount,
              expense: existing.expense,
              transfer: existing.transfer,
            );
            break;
          case TransactionType.expense:
            dailyMap[dateKey] = DailyAccountData(
              date: existing.date,
              income: existing.income,
              expense: existing.expense + transaction.amount,
              transfer: existing.transfer,
            );
            break;
          case TransactionType.transfer:
            dailyMap[dateKey] = DailyAccountData(
              date: existing.date,
              income: existing.income,
              expense: existing.expense,
              transfer: existing.transfer + transaction.amount,
            );
            break;
        }
      }
    }

    // Convert to list and sort by date
    final result = dailyMap.values.toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final accountColor = widget.account.colorHex != null
        ? Color(int.parse(widget.account.colorHex!.replaceFirst('#', '0xff')))
        : Colors.blue[700]!;
    final accountIcon = IconHelper.fromString(widget.account.iconCodePoint);

    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return Scaffold(
          backgroundColor: isDesktop
              ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF09090B)
                    : AppColors.backgroundSecondary)
              : null,
          appBar: AppBar(
            title: Text(widget.account.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: AsyncStreamBuilder<List<Transaction>>(
            state: _transactionController,
            loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: $message'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _transactionController
                        .loadTransactionsByAccount(widget.account.id!),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            builder: (context, transactions) {
              // Filter transactions for this account
              final accountTransactions = transactions.where((t) =>
                  t.accountId == widget.account.id ||
                  t.toAccountId == widget.account.id).toList();

              // Sort by date descending
              accountTransactions.sort((a, b) => b.date.compareTo(a.date));

              // Calculate totals
              double totalIncome = 0;
              double totalExpense = 0;
              double totalTransfer = 0;

              for (final t in accountTransactions) {
                switch (t.type) {
                  case TransactionType.income:
                    totalIncome += t.amount;
                    break;
                  case TransactionType.expense:
                    totalExpense += t.amount;
                    break;
                  case TransactionType.transfer:
                    totalTransfer += t.amount;
                    break;
                }
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1200 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Info Card
                        _buildAccountInfoCard(accountColor, accountIcon, isDesktop),
                        SizedBox(height: isDesktop ? AppSpacing.xl : 24),

                        // Summary Cards
                        _buildSummaryCards(
                          totalIncome,
                          totalExpense,
                          totalTransfer,
                          isDesktop,
                        ),
                        SizedBox(height: isDesktop ? AppSpacing.xl : 24),

                        // Bar Graph
                        _buildBarGraph(accountTransactions, isDesktop),
                        SizedBox(height: isDesktop ? AppSpacing.xl : 24),

                        // Transactions List
                        _buildTransactionsList(accountTransactions, isDesktop),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAccountInfoCard(Color accountColor, IconData accountIcon, bool isDesktop) {
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accountColor, accountColor.withOpacity(0.7)],
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(accountIcon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.account.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.account.accountType.toString().split('.').last,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Current Balance',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.currency(
                symbol: currencyFormatter.currencySymbol,
                decimalDigits: 2,
              ).format(widget.account.balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.account.bankAccountNumber != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    widget.account.bankAccountNumber!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    double totalIncome,
    double totalExpense,
    double totalTransfer,
    bool isDesktop,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Income',
            totalIncome,
            Colors.green,
            Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Expense',
            totalExpense,
            Colors.red,
            Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Transfer',
            totalTransfer,
            Colors.blue,
            Icons.swap_horiz,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(
                symbol: currencyFormatter.currencySymbol,
                decimalDigits: 0,
              ).format(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarGraph(List<Transaction> transactions, bool isDesktop) {
    final data = _processTransactionsToDaily(transactions);
    final maxAmount = data.fold<double>(
      0,
      (max, d) {
        final dayMax = [d.income, d.expense, d.transfer].reduce((a, b) => a > b ? a : b);
        return dayMax > max ? dayMax : max;
      },
    );

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: _daysToShow,
                    isDense: true,
                    underline: const SizedBox(),
                    items: [7, 15, 30].map((days) {
                      return DropdownMenuItem<int>(
                        value: days,
                        child: Text('$days days', style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _daysToShow = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Legend
            Row(
              children: [
                _buildLegendIndicator(Colors.green, 'Income'),
                const SizedBox(width: 16),
                _buildLegendIndicator(Colors.red, 'Expense'),
                const SizedBox(width: 16),
                _buildLegendIndicator(Colors.blue, 'Transfer'),
              ],
            ),
            const SizedBox(height: 16),

            // Bar Graph
            SizedBox(
              height: isDesktop ? 200 : 160,
              child: data.isEmpty || maxAmount == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No transactions in this period',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = (constraints.maxWidth - (data.length - 1) * 6) / (data.length * 3);
                        final clampedBarWidth = barWidth.clamp(3.0, 16.0);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: data.map((dayData) {
                            final incomeHeight = maxAmount > 0
                                ? (dayData.income / maxAmount) * (isDesktop ? 160 : 120)
                                : 0.0;
                            final expenseHeight = maxAmount > 0
                                ? (dayData.expense / maxAmount) * (isDesktop ? 160 : 120)
                                : 0.0;
                            final transferHeight = maxAmount > 0
                                ? (dayData.transfer / maxAmount) * (isDesktop ? 160 : 120)
                                : 0.0;

                            return Tooltip(
                              message: '${DateFormat('MMM d').format(dayData.date)}\n'
                                  'Income: ${currencyFormatter.currencySymbol}${NumberFormat('#,##0').format(dayData.income)}\n'
                                  'Expense: ${currencyFormatter.currencySymbol}${NumberFormat('#,##0').format(dayData.expense)}\n'
                                  'Transfer: ${currencyFormatter.currencySymbol}${NumberFormat('#,##0').format(dayData.transfer)}',
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Income bar
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: clampedBarWidth,
                                        height: incomeHeight,
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.8),
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(3),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 1),
                                      // Expense bar
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: clampedBarWidth,
                                        height: expenseHeight,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.8),
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(3),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 1),
                                      // Transfer bar
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: clampedBarWidth,
                                        height: transferHeight,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.8),
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('d').format(dayData.date),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${transactions.length} transaction${transactions.length != 1 ? 's' : ''}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    Color typeColor;
    IconData typeIcon;
    String prefix;

    switch (transaction.type) {
      case TransactionType.income:
        typeColor = Colors.green;
        typeIcon = Icons.arrow_downward;
        prefix = '+';
        break;
      case TransactionType.expense:
        typeColor = Colors.red;
        typeIcon = Icons.arrow_upward;
        prefix = '-';
        break;
      case TransactionType.transfer:
        typeColor = Colors.blue;
        typeIcon = Icons.swap_horiz;
        prefix = transaction.accountId == widget.account.id ? '-' : '+';
        break;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(typeIcon, color: typeColor, size: 20),
        ),
        title: Text(
          transaction.description ?? transaction.type.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy - h:mm a').format(transaction.date),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Text(
          '$prefix${NumberFormat.currency(
            symbol: currencyFormatter.currencySymbol,
            decimalDigits: 2,
          ).format(transaction.amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: typeColor,
          ),
        ),
      ),
    );
  }
}
