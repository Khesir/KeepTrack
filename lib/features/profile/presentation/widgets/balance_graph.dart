import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/demo/demo_mode.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

class BalanceGraph extends StatefulWidget {
  const BalanceGraph({super.key});

  @override
  State<BalanceGraph> createState() => _BalanceGraphState();
}

class _BalanceGraphState extends State<BalanceGraph> {
  late final WalletController _walletController;
  late final TransactionController _transactionController;

  @override
  void initState() {
    super.initState();
    _walletController = locator.get<WalletController>();
    _transactionController = locator.get<TransactionController>();
    _walletController.loadWallets();

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DemoMode.enabled
        ? DateTime(now.year, now.month + 1, 0, 23, 59, 59)
        : now;
    _transactionController.loadTransactionsByDateRange(startDate, endDate);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Wallet>>(
      state: _walletController,
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
          child: Text('Error loading wallets: $message'),
        ),
      ),
      builder: (context, wallets) {
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
          errorBuilder: (context, message) => _buildGraphCard(wallets, []),
          builder: (context, transactions) => _buildGraphCard(wallets, transactions),
        );
      },
    );
  }

  Widget _buildGraphCard(List<Wallet> wallets, List<Transaction> transactions) {
    final currentBalance = wallets.where((w) => w.type == WalletType.standard).fold(0.0, (sum, w) => sum + w.balance);
    // Calculate balance trend data
    final balanceData = _calculateBalanceTrend(currentBalance, transactions);

    // Calculate percentage change
    final percentageChange = balanceData.length >= 2
        ? ((balanceData.last.balance - balanceData.first.balance) / balanceData.first.balance * 100)
        : 0.0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Balance Trend',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
              _buildInteractiveChart(context, balanceData)
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
                children: DemoMode.enabled
                    ? [
                        Text('Day 1',  style: _xAxisLabelStyle),
                        Text('Day 16', style: _xAxisLabelStyle),
                        Text('Day 31', style: _xAxisLabelStyle),
                      ]
                    : [
                        Text('30 days ago', style: _xAxisLabelStyle),
                        Text('15 days ago', style: _xAxisLabelStyle),
                        Text('Today',       style: _xAxisLabelStyle),
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

  Widget _buildInteractiveChart(BuildContext context, List<BalanceDataPoint> balanceData) {
    final chartWidth = MediaQuery.of(context).size.width - 80;
    final chartHeight = 200.0;
    final painter = LineChartPainter(
      balanceData,
      primaryColor: Theme.of(context).colorScheme.primary,
    );

    return SizedBox(
      height: chartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final points = painter.getPoints(Size(chartWidth, chartHeight));

          return Stack(
            children: [
              // The chart itself
              CustomPaint(
                size: Size(chartWidth, chartHeight),
                painter: painter,
              ),
              // Tooltip overlays for each node
              ...List.generate(balanceData.length, (index) {
                if (index >= points.length) return const SizedBox();

                final point = points[index];
                final dataPoint = balanceData[index];

                return Positioned(
                  left: point.dx - 8,
                  top: point.dy - 8,
                  child: Tooltip(
                    message: '${DateFormat('MMM d, y').format(dataPoint.date)}\n₱${NumberFormat('#,##0.00').format(dataPoint.balance)}',
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  List<BalanceDataPoint> _calculateBalanceTrend(
    double currentBalance,
    List<Transaction> transactions,
  ) {
    final now = DateTime.now();
    const dataPoints = 15;

    final relevantTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    final DateTime rangeStart;
    final DateTime rangeEnd;

    if (DemoMode.enabled) {
      rangeStart = DateTime(now.year, now.month, 1);
      rangeEnd   = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else {
      rangeStart = now.subtract(const Duration(days: 30));
      rangeEnd   = now;
    }

    final totalMs = rangeEnd.millisecondsSinceEpoch - rangeStart.millisecondsSinceEpoch;

    final balanceHistory = <BalanceDataPoint>[];

    for (int i = 0; i < dataPoints; i++) {
      final fraction = i / (dataPoints - 1);
      final targetDate = DateTime.fromMillisecondsSinceEpoch(
        rangeStart.millisecondsSinceEpoch + (totalMs * fraction).round(),
      );

      double balanceAtDate = currentBalance;
      for (final t in relevantTransactions) {
        if (t.date.isAfter(targetDate)) {
          switch (t.type) {
            case TransactionType.income:
              balanceAtDate -= t.amount;
              break;
            case TransactionType.expense:
              balanceAtDate += t.amount;
              break;
            default:
              break;
          }
        }
      }

      balanceHistory.add(BalanceDataPoint(
        date: targetDate,
        balance: balanceAtDate < 0 ? 0 : balanceAtDate,
      ));
    }

    if (balanceHistory.every((b) => b.balance == balanceHistory.first.balance)) {
      return balanceHistory.map((b) => BalanceDataPoint(
        date: b.date,
        balance: b.balance > 0 ? b.balance : 1000.0,
      )).toList();
    }

    return balanceHistory;
  }
}

class BalanceDataPoint {
  final DateTime date;
  final double balance;

  BalanceDataPoint({required this.date, required this.balance});
}

class LineChartPainter extends CustomPainter {
  final List<BalanceDataPoint> data;
  final Color primaryColor;

  LineChartPainter(this.data, {required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Find min and max for scaling
    final balances = data.map((d) => d.balance).toList();
    final minValue = balances.reduce((a, b) => a < b ? a : b);
    final maxValue = balances.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    // Create points for the line
    final points = <Offset>[];
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i].balance - minValue) / range : 0.5;
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
    return oldDelegate.data != data || oldDelegate.primaryColor != primaryColor;
  }

  // Helper method to get point positions for tooltips
  List<Offset> getPoints(Size size) {
    if (data.isEmpty) return [];

    final balances = data.map((d) => d.balance).toList();
    final minValue = balances.reduce((a, b) => a < b ? a : b);
    final maxValue = balances.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    final points = <Offset>[];
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i].balance - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.9) - (size.height * 0.05);
      points.add(Offset(x, y));
    }

    return points;
  }
}
