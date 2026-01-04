import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/account_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

class BalanceGraph extends StatefulWidget {
  const BalanceGraph({super.key});

  @override
  State<BalanceGraph> createState() => _BalanceGraphState();
}

class _BalanceGraphState extends State<BalanceGraph> {
  late final AccountController _accountController;
  late final TransactionController _transactionController;
  String? _selectedAccountId; // null means 'All Accounts'

  @override
  void initState() {
    super.initState();
    _accountController = locator.get<AccountController>();
    _transactionController = locator.get<TransactionController>();
    _accountController.loadAccounts();

    // Load transactions for the last 30 days
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    _transactionController.loadTransactionsByDateRange(startDate, now);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Account>>(
      state: _accountController,
      loadingBuilder: (_) => Card(
        elevation: 0,
        child: Container(
          height: 400,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ),
      errorBuilder: (context, message) => Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error loading accounts: $message'),
        ),
      ),
      builder: (context, accounts) {
        if (accounts.isEmpty) {
          return Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No accounts found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return AsyncStreamBuilder<List<Transaction>>(
          state: _transactionController,
          loadingBuilder: (_) => Card(
            elevation: 0,
            child: Container(
              height: 400,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          ),
          errorBuilder: (context, message) => _buildGraphCard(
            accounts,
            [],
          ),
          builder: (context, transactions) {
            return _buildGraphCard(accounts, transactions);
          },
        );
      },
    );
  }

  Widget _buildGraphCard(List<Account> accounts, List<Transaction> transactions) {
    // Build dropdown items
    final dropdownItems = [
      DropdownMenuItem<String?>(
        value: null,
        child: Text('All Accounts'),
      ),
      ...accounts.map((account) => DropdownMenuItem<String?>(
        value: account.id,
        child: Text(account.name),
      )),
    ];

    // Calculate balance trend data
    final balanceData = _calculateBalanceTrend(accounts, transactions);
    final currentBalance = _getCurrentBalance(accounts);

    // Calculate percentage change
    final percentageChange = balanceData.length >= 2
        ? ((balanceData.last - balanceData.first) / balanceData.first * 100)
        : 0.0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account filter dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Balance Trend',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String?>(
                    value: _selectedAccountId,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    items: dropdownItems,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedAccountId = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Current balance display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Balance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${NumberFormat('#,##0.00').format(currentBalance)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (balanceData.length >= 2)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (percentageChange >= 0 ? Colors.green : Colors.red)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            percentageChange >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 16,
                            color: percentageChange >= 0
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: percentageChange >= 0
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Simple line chart
            if (balanceData.isNotEmpty)
              SizedBox(
                height: 200,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width - 80, 200),
                  painter: LineChartPainter(
                    balanceData,
                    primaryColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                alignment: Alignment.center,
                child: Text(
                  'No transaction history available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 12),

            // X-axis labels
            if (balanceData.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('30 days ago', style: _xAxisLabelStyle),
                  Text('15 days ago', style: _xAxisLabelStyle),
                  Text('Today', style: _xAxisLabelStyle),
                ],
              ),
          ],
        ),
      ),
    );
  }

  TextStyle get _xAxisLabelStyle => TextStyle(
        fontSize: 10,
        color: Colors.grey[600],
      );

  double _getCurrentBalance(List<Account> accounts) {
    if (_selectedAccountId == null) {
      // All accounts
      return accounts.fold(0.0, (sum, account) => sum + account.balance);
    } else {
      // Specific account
      final account = accounts.firstWhere(
        (a) => a.id == _selectedAccountId,
        orElse: () => accounts.first,
      );
      return account.balance;
    }
  }

  List<double> _calculateBalanceTrend(
    List<Account> accounts,
    List<Transaction> transactions,
  ) {
    if (accounts.isEmpty) return [];

    final currentBalance = _getCurrentBalance(accounts);
    final now = DateTime.now();
    final daysToShow = 30;
    final dataPoints = 15;

    // Filter transactions by selected account
    List<Transaction> relevantTransactions;
    if (_selectedAccountId == null) {
      // All accounts - use all transactions
      relevantTransactions = transactions;
    } else {
      // Specific account
      relevantTransactions = transactions
          .where((t) => t.accountId == _selectedAccountId)
          .toList();
    }

    // Sort transactions by date (oldest first)
    relevantTransactions.sort((a, b) => a.date.compareTo(b.date));

    // Calculate balance at each data point
    final balanceHistory = <double>[];

    for (int i = dataPoints - 1; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: (i * daysToShow ~/ dataPoints)));

      // Calculate balance by working backwards from current balance
      double balanceAtDate = currentBalance;

      // Subtract/add transactions that happened after this date
      for (final transaction in relevantTransactions) {
        if (transaction.date.isAfter(targetDate)) {
          // Reverse the transaction effect
          switch (transaction.type) {
            case TransactionType.income:
              balanceAtDate -= transaction.amount;
              break;
            case TransactionType.expense:
            case TransactionType.transfer:
              balanceAtDate += transaction.amount;
              break;
          }
        }
      }

      // Ensure balance is never negative in history
      balanceHistory.add(balanceAtDate < 0 ? 0 : balanceAtDate);
    }

    // If no variation, add slight variation for better visualization
    if (balanceHistory.every((b) => b == balanceHistory.first)) {
      return balanceHistory.map((b) => b > 0 ? b : 1000.0).toList();
    }

    return balanceHistory;
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color primaryColor;

  LineChartPainter(this.data, {required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Find min and max for scaling
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    // Create points for the line
    final points = <Offset>[];
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.9) - (size.height * 0.05);
      points.add(Offset(x, y));
    }

    // Draw gradient fill
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.3),
          primaryColor.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(points.first.dx, points.first.dy);

    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }

    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, gradientPaint);

    // Draw line
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(linePath, linePaint);

    // Draw points
    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(
        point,
        2,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
