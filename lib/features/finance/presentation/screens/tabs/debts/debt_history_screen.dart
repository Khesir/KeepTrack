import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../../../../modules/debt/domain/entities/debt.dart';
import '../../../state/debt_controller.dart';

class DebtHistoryScreen extends StatefulWidget {
  const DebtHistoryScreen({super.key});

  @override
  State<DebtHistoryScreen> createState() => _DebtHistoryScreenState();
}

class _DebtHistoryScreenState extends State<DebtHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final DebtController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<DebtController>();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Debts (Borrowed)'),
            Tab(text: 'Receivables (Lent)'),
          ],
        ),
      ),
      body: AsyncStreamBuilder<List<Debt>>(
        state: _controller,
        builder: (context, allDebts) {
          final settledDebts = allDebts
              .where(
                (d) =>
                    d.type == DebtType.borrowing &&
                    d.status == DebtStatus.settled,
              )
              .toList()
            ..sort((a, b) {
              final aDate = a.settledAt ?? a.updatedAt ?? a.startDate;
              final bDate = b.settledAt ?? b.updatedAt ?? b.startDate;
              return bDate.compareTo(aDate);
            });

          final settledReceivables = allDebts
              .where(
                (d) =>
                    d.type == DebtType.lending &&
                    d.status == DebtStatus.settled,
              )
              .toList()
            ..sort((a, b) {
              final aDate = a.settledAt ?? a.updatedAt ?? a.startDate;
              final bDate = b.settledAt ?? b.updatedAt ?? b.startDate;
              return bDate.compareTo(aDate);
            });

          return TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryList(
                context,
                theme,
                settledDebts,
                DebtType.borrowing,
              ),
              _buildHistoryList(
                context,
                theme,
                settledReceivables,
                DebtType.lending,
              ),
            ],
          );
        },
        loadingBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _controller.loadDebts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    ThemeData theme,
    List<Debt> debts,
    DebtType type,
  ) {
    final isLending = type == DebtType.lending;
    final color = isLending ? Colors.green : Colors.red;

    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isLending
                  ? 'No settled receivables yet'
                  : 'No settled debts yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLending
                  ? 'Receivables you collect will appear here'
                  : 'Debts you pay off will appear here',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group by year
    final grouped = <int, List<Debt>>{};
    for (final debt in debts) {
      final year = (debt.settledAt ?? debt.updatedAt ?? debt.startDate).year;
      grouped.putIfAbsent(year, () => []).add(debt);
    }
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final totalSettled = debts.fold<double>(
      0,
      (sum, d) => sum + d.originalAmount,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Summary banner
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLending ? Icons.call_made : Icons.call_received,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${debts.length} ${isLending ? 'receivable${debts.length != 1 ? 's' : ''}' : 'debt${debts.length != 1 ? 's' : ''}'} settled',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      NumberFormat.currency(
                        symbol: currencyFormatter.currencySymbol,
                        decimalDigits: 2,
                      ).format(totalSettled),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isLending ? 'Total collected' : 'Total repaid',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Grouped list
        for (final year in years) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              year.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...grouped[year]!.map(
            (debt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildHistoryCard(context, debt, color, isLending),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    Debt debt,
    Color color,
    bool isLending,
  ) {
    final settledDate = debt.settledAt ?? debt.updatedAt;
    final fmt = DateFormat('MMM d, yyyy');

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + settled badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isLending ? Icons.call_made : Icons.call_received,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.personName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (debt.description.isNotEmpty)
                        Text(
                          debt.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Settled',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amounts row
            Row(
              children: [
                Expanded(
                  child: _amountCell(
                    context,
                    'Original Amount',
                    debt.originalAmount,
                    color,
                    large: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _amountCell(
                    context,
                    'Amount Paid',
                    debt.paidAmount,
                    Colors.green,
                  ),
                ),
                if (debt.feeAmount > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _amountCell(
                      context,
                      'Fees',
                      debt.feeAmount,
                      Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Dates row
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  'Started: ${fmt.format(debt.startDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
                if (settledDate != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.check_circle,
                    size: 12,
                    color: Colors.green.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Settled: ${fmt.format(settledDate)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),

            if (debt.notes != null && debt.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  debt.notes!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountCell(
    BuildContext context,
    String label,
    double amount,
    Color color, {
    bool large = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          NumberFormat.currency(
            symbol: currencyFormatter.currencySymbol,
            decimalDigits: 2,
          ).format(amount),
          style: TextStyle(
            fontSize: large ? 17 : 14,
            fontWeight: large ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
