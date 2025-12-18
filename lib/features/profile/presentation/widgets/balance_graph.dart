import 'package:flutter/material.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';

class BalanceGraph extends StatefulWidget {
  const BalanceGraph({super.key});

  @override
  State<BalanceGraph> createState() => _BalanceGraphState();
}

class _BalanceGraphState extends State<BalanceGraph> {
  String _selectedAccount = 'All Accounts';

  @override
  Widget build(BuildContext context) {
    // Mock data - will be replaced with actual account data from database
    final accounts = ['All Accounts', 'Main Wallet', 'Savings', 'Cash'];
    final balanceData = _getBalanceData(_selectedAccount);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
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
                    color: GCashColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedAccount,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    items: accounts.map((String account) {
                      return DropdownMenuItem<String>(
                        value: account,
                        child: Text(account),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedAccount = newValue;
                        });
                      }
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
                color: GCashColors.primary.withOpacity(0.05),
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
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${balanceData.last.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: GCashColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+12.5%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
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
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width - 80, 200),
                painter: LineChartPainter(balanceData),
              ),
            ),
            const SizedBox(height: 12),

            // X-axis labels
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

  List<double> _getBalanceData(String account) {
    // Mock data - different balances for different accounts
    switch (account) {
      case 'Main Wallet':
        return [15000, 14500, 16000, 15800, 17200, 16500, 18000, 17800, 19000, 18500, 20000, 19800, 21000, 20500, 22000];
      case 'Savings':
        return [30000, 30500, 31000, 31200, 32000, 32500, 33000, 33200, 34000, 34500, 35000, 35200, 36000, 36500, 37000];
      case 'Cash':
        return [5000, 4800, 4500, 4200, 5000, 4700, 5200, 5000, 5500, 5300, 6000, 5800, 6200, 6000, 6500];
      default: // All Accounts
        return [50000, 49800, 51500, 51200, 54200, 53700, 56200, 56000, 58500, 58300, 61000, 60800, 63200, 63000, 65500];
    }
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;

  LineChartPainter(this.data);

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
          GCashColors.primary.withOpacity(0.3),
          GCashColors.primary.withOpacity(0.05),
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
      ..color = GCashColors.primary
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
      ..color = GCashColors.primary
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
