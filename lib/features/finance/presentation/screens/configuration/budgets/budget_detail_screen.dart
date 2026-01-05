import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/ui/scoped_screen.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import '../../../../modules/budget/domain/entities/budget.dart';
import '../../../../modules/budget/domain/entities/budget_category.dart';
import '../../../state/account_controller.dart';
import '../../../state/budget_controller.dart';
import '../../../state/transaction_controller.dart';

/// Budget detail screen - Shows details of a specific budget
class BudgetDetailScreen extends ScopedScreen {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ScopedScreenState<BudgetDetailScreen>
    with AppLayoutControlled {
  late final BudgetController _controller;
  late final AccountController _accountController;
  late final TransactionController _transactionController;
  late Budget _currentBudget;
  List<Transaction> _budgetTransactions = [];
  StreamSubscription<AsyncState<List<Budget>>>? _budgetSubscription;

  @override
  void registerServices() {
    _controller = locator.get<BudgetController>();
    _accountController = locator.get<AccountController>();
    _transactionController = locator.get<TransactionController>();
  }

  @override
  void initState() {
    super.initState();
    _currentBudget = widget.budget;
    _loadBudgetTransactions();
    _listenToBudgetUpdates();
  }

  void _listenToBudgetUpdates() {
    _budgetSubscription = _controller.stream.listen((state) {
      if (state is AsyncData<List<Budget>>) {
        final budgets = state.data;
        // Find the updated budget in the list
        final updatedBudget = budgets.where((b) => b.id == _currentBudget.id).firstOrNull;

        // Update local state with the latest budget data
        if (mounted && updatedBudget != null) {
          setState(() {
            _currentBudget = updatedBudget;
          });
        }
      }
    });
  }

  @override
  void onReady() {
    _controller.loadBudgets();
    _accountController.loadAccounts();
  }

  Future<void> _loadBudgetTransactions() async {
    // Listen to transaction stream and filter
    _transactionController.stream.listen((state) {
      if (state is AsyncData<List<Transaction>>) {
        final allTransactions = state.data;

        // Filter transactions based on budget period type
        final List<Transaction> filtered;

        if (_currentBudget.periodType == BudgetPeriodType.monthly) {
          // Monthly budgets: Include only unassigned transactions (budget_id = null)
          // that match category, type, and date

          // Parse the budget month (format: YYYY-MM)
          final parts = _currentBudget.month.split('-');
          if (parts.length != 2) {
            filtered = [];
          } else {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);

            final categoryIds = _currentBudget.categories
                .map((c) => c.financeCategoryId)
                .toSet();
            final budgetType = _currentBudget.budgetType;

            filtered = allTransactions.where((t) {
              // Must have no budget assignment
              if (t.budgetId != null) return false;

              // Date filtering - only transactions in the exact month
              final txYear = t.date.year;
              final txMonth = t.date.month;
              final inDateRange = txYear == year && txMonth == month;

              // Category filtering
              final inBudgetCategory = categoryIds.contains(t.financeCategoryId);

              // Type filtering - match transaction type with budget type
              // IMPORTANT: Exclude transfer transactions from all budget calculations
              final matchesType = (budgetType == BudgetType.income && t.type == TransactionType.income) ||
                                  (budgetType == BudgetType.expense && t.type == TransactionType.expense);
              final isNotTransfer = t.type != TransactionType.transfer;

              return inDateRange && inBudgetCategory && matchesType && isNotTransfer;
            }).toList();
          }
        } else {
          // One-time budgets: Include only transactions explicitly assigned to this budget
          // No date filtering - one-time budgets can span multiple months
          // IMPORTANT: Exclude transfer transactions from all budget calculations
          filtered = allTransactions.where((t) {
            return t.budgetId == _currentBudget.id && t.type != TransactionType.transfer;
          }).toList();
        }

        // Sort by date descending
        filtered.sort((a, b) => b.date.compareTo(a.date));

        if (mounted) {
          setState(() {
            _budgetTransactions = filtered;
          });
        }
      }
    });
  }

  @override
  void onDispose() {
    // Cancel budget subscription
    _budgetSubscription?.cancel();
    // Don't dispose controllers - they're singletons
  }

  String _formatMonthDisplay(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      const monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${monthNames[month - 1]} $year';
    } catch (e) {
      return monthStr;
    }
  }

  Future<void> _toggleBudgetStatus() async {
    try {
      final newStatus = _currentBudget.status == BudgetStatus.active
          ? BudgetStatus.closed
          : BudgetStatus.active;

      final updatedBudget = _currentBudget.copyWith(
        status: newStatus,
        closedAt: newStatus == BudgetStatus.closed ? DateTime.now() : null,
      );

      await _controller.updateBudget(updatedBudget);

      setState(() {
        _currentBudget = updatedBudget;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Budget ${newStatus == BudgetStatus.closed ? 'closed' : 'reopened'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating budget: $e')),
        );
      }
    }
  }

  Future<void> _debugBudget() async {
    if (_currentBudget.id == null) return;

    try {
      final debugInfo = await _controller.debugBudgetCategories(_currentBudget.id!);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Budget Debug Info'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Budget Month: ${debugInfo['budget_month']}'),
                const SizedBox(height: 16),
                const Text(
                  'Categories:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((debugInfo['categories'] as List?) ?? []).map((catData) {
                  final cat = catData['category'] as Map<String, dynamic>;
                  final transactions = catData['transactions'] as List;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category ID: ${cat['finance_category_id']}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text('Target: ₱${cat['target_amount']}'),
                          Text('DB Spent: ₱${cat['spent_amount'] ?? 0}'),
                          Text('DB Fees: ₱${cat['fee_spent'] ?? 0}'),
                          Text('Calculated Spent: ₱${catData['calculated_spent']}'),
                          Text('Calculated Fees: ₱${catData['calculated_fees']}'),
                          Text(
                            'Transactions: ${catData['transaction_count']}',
                            style: TextStyle(
                              color: transactions.isEmpty ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (transactions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Transaction Details:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...transactions.map((t) => Text(
                                  '  - ₱${t['amount']} (fee: ₱${t['fee'] ?? 0}) - ${t['description']}',
                                  style: const TextStyle(fontSize: 10),
                                )),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug error: $e')),
        );
      }
    }
  }

  Future<void> _refreshBudget() async {
    try {
      if (_currentBudget.id == null) return;

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Recalculating budget...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Use manual calculation (bypasses broken database function)
      await _controller.manualRecalculateBudgetSpent(_currentBudget.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget recalculated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recalculating budget: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _editBudget() async {
    // Show warning dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Budget'),
        content: const Text(
          'You are about to edit this budget. Changes to category targets may affect your budget tracking and calculations.\n\nDo you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Edit'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Navigate to edit screen
    await Navigator.of(context).pushNamed(
      '/budget/edit',
      arguments: _currentBudget,
    );

    // Reload budget after returning from edit (the stream listener will update the UI)
    await _controller.loadBudgets();
  }

  Future<void> _deleteBudget() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete the budget for ${_formatMonthDisplay(_currentBudget.month)}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _controller.deleteBudget(_currentBudget.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget deleted successfully'),
          ),
        );
        Navigator.of(context).pop(); // Go back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting budget: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine color based on budget status
    final balanceColor = _currentBudget.status == BudgetStatus.closed
        ? (_currentBudget.surplusOrDeficit >= 0 ? Colors.green : Colors.red)
        : (_currentBudget.isOverBudget ? Colors.red : Colors.blue);

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatMonthDisplay(_currentBudget.month)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Budget',
            onPressed: _refreshBudget,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'debug':
                  _debugBudget();
                  break;
                case 'refresh':
                  _refreshBudget();
                  break;
                case 'edit':
                  _editBudget();
                  break;
                case 'toggle_status':
                  _toggleBudgetStatus();
                  break;
                case 'delete':
                  _deleteBudget();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(
                      Icons.bug_report,
                      size: 20,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 12),
                    Text('Debug Info'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text('Refresh Amounts'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text('Edit Budget'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(
                      _currentBudget.status == BudgetStatus.active
                          ? Icons.close
                          : Icons.check_circle,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _currentBudget.status == BudgetStatus.active
                          ? 'Close Budget'
                          : 'Reopen Budget',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.red,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Delete Budget',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AsyncStreamBuilder<List<Account>>(
        state: _accountController,
        builder: (context, accounts) {
          final account = accounts
              .where((acc) => acc.id == _currentBudget.accountId)
              .firstOrNull;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildHeaderCard(colorScheme, balanceColor, account),

                const SizedBox(height: 16),

                // Visual Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildBudgetVisualBar(),
                ),

                const SizedBox(height: 24),

                // Categories Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 12),

                // Categories List
                if (_currentBudget.categories.isEmpty)
                  _buildEmptyCategories()
                else
                  _buildCategoriesList(),

                const SizedBox(height: 24),

                // Transactions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_budgetTransactions.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Transactions List
                if (_budgetTransactions.isEmpty)
                  _buildEmptyTransactions()
                else
                  _buildTransactionsList(),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
        loadingBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(
          child: Text('Error loading account: $message'),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    ColorScheme colorScheme,
    Color balanceColor,
    Account? account,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with month and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show title if available (for one-time budgets), otherwise show month
                      Text(
                        _currentBudget.title != null && _currentBudget.title!.isNotEmpty
                            ? _currentBudget.title!
                            : _formatMonthDisplay(_currentBudget.month),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Show month as subtitle for one-time budgets with title
                      if (_currentBudget.title != null && _currentBudget.title!.isNotEmpty)
                        Text(
                          _formatMonthDisplay(_currentBudget.month),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (account != null)
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: account.colorHex != null
                                    ? Color(
                                        int.parse(
                                          account.colorHex!
                                              .replaceFirst('#', '0xFF'),
                                        ),
                                      )
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              account.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (_currentBudget.status == BudgetStatus.active
                            ? Colors.green
                            : Colors.grey)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentBudget.status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: _currentBudget.status == BudgetStatus.active
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Budget Total
            Text(
              '₱${_currentBudget.budgetTarget.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
            ),
            Text(
              _currentBudget.status == BudgetStatus.closed
                  ? (_currentBudget.surplusOrDeficit >= 0 ? 'Surplus' : 'Deficit')
                  : 'Budget Target',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // Quick stats row
            Row(
              children: [
                _buildQuickStat(
                  _currentBudget.budgetType == BudgetType.income ? 'Earned' : 'Spent',
                  _currentBudget.totalSpent,
                  balanceColor,
                ),
                const SizedBox(width: 16),
                _buildQuickStat(
                  'Remaining',
                  _currentBudget.remainingBudget.abs(),
                  _currentBudget.remainingBudget >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, double amount, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(width: 6),
        Text(
          '₱${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetVisualBar() {
    final spent = _currentBudget.totalSpent;
    final target = _currentBudget.budgetTarget;

    final spentPercentage = target > 0 ? (spent / target).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // HP-style bar
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Stack(
                children: [
                  // Actual spent (gradient based on if over budget)
                  if (spentPercentage > 0)
                    FractionallySizedBox(
                      widthFactor: spentPercentage,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _currentBudget.isOverBudget
                                ? [Colors.red[400]!, Colors.red[600]!]
                                : [Colors.blue[400]!, Colors.blue[600]!],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: (_currentBudget.isOverBudget
                                      ? Colors.red
                                      : Colors.blue)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Amount text overlay
                  Center(
                    child: Text(
                      '₱${spent.toStringAsFixed(0)} / ₱${target.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  _currentBudget.isOverBudget ? Colors.red[500]! : Colors.blue[500]!,
                  _currentBudget.budgetType == BudgetType.income ? 'Earned' : 'Spent',
                ),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.grey[300]!, 'Remaining'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCategories() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No categories',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    // Group categories by type
    final incomeCategories = _currentBudget.categories
        .where((c) => c.financeCategory?.type == CategoryType.income)
        .toList();
    final expenseCategories = _currentBudget.categories
        .where((c) => c.financeCategory?.type == CategoryType.expense)
        .toList();
    final savingsCategories = _currentBudget.categories
        .where((c) => c.financeCategory?.type == CategoryType.savings)
        .toList();
    final investmentCategories = _currentBudget.categories
        .where((c) => c.financeCategory?.type == CategoryType.investment)
        .toList();

    return Column(
      children: [
        if (incomeCategories.isNotEmpty) ...[
          _buildCategorySection('Income', incomeCategories, Colors.green),
          const SizedBox(height: 16),
        ],
        if (expenseCategories.isNotEmpty) ...[
          _buildCategorySection('Expenses', expenseCategories, Colors.red),
          const SizedBox(height: 16),
        ],
        if (savingsCategories.isNotEmpty) ...[
          _buildCategorySection('Savings', savingsCategories, Colors.orange),
          const SizedBox(height: 16),
        ],
        if (investmentCategories.isNotEmpty) ...[
          _buildCategorySection(
            'Investments',
            investmentCategories,
            Colors.purple,
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySection(
    String title,
    List<BudgetCategory> categories,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...categories.map((category) => _buildCategoryCard(category, color)),
      ],
    );
  }

  Widget _buildCategoryCard(BudgetCategory category, Color color) {
    final spent = category.spentAmount ?? 0.0;
    final feeSpent = category.feeSpent ?? 0.0;
    final totalSpent = category.totalSpent;
    final target = category.targetAmount;
    final remaining = target - totalSpent;
    final percentage = target > 0 ? (totalSpent / target).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = totalSpent > target;
    final hasFees = feeSpent > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category.financeCategory?.name ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isOverBudget)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Over Budget',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.financeCategory?.type == CategoryType.income ? 'Earned' : 'Spent',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      '₱${totalSpent.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : color,
                      ),
                    ),
                    if (hasFees)
                      Text(
                        '(₱${spent.toStringAsFixed(2)} + ₱${feeSpent.toStringAsFixed(2)} fees)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Target',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      '₱${target.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      '₱${remaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: remaining >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                isOverBudget ? Colors.red : color,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            if (percentage > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${(percentage * 100).toStringAsFixed(0)}% used',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Transactions in this budget will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Column(
      children: _budgetTransactions.map((transaction) {
        return _buildTransactionCard(transaction);
      }).toList(),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final isExpense = transaction.type == TransactionType.expense;
    final color = isIncome
        ? Colors.green
        : isExpense
            ? Colors.red
            : Colors.blue;

    final displayAmount = isExpense
        ? -transaction.totalCost
        : isIncome
            ? transaction.totalCost
            : transaction.amount;

    // Find the category name from budget categories
    final budgetCategory = _currentBudget.categories
        .where((c) => c.financeCategoryId == transaction.financeCategoryId)
        .firstOrNull;
    final category = budgetCategory?.financeCategory;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            category?.type.icon ?? Icons.category,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description ?? category?.name ?? 'Transaction',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Icon(
              isIncome
                  ? Icons.arrow_downward
                  : isExpense
                      ? Icons.arrow_upward
                      : Icons.swap_horiz,
              size: 12,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              category?.name ?? 'Unknown',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (transaction.hasFee) ...[
              const SizedBox(width: 8),
              Icon(Icons.receipt, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 2),
              Text(
                '+${currencyFormatter.currencySymbol}${transaction.fee.toStringAsFixed(2)} fee',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isExpense ? '-' : isIncome ? '+' : ''}${currencyFormatter.currencySymbol}${displayAmount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isIncome
                    ? Colors.green[700]
                    : isExpense
                        ? Colors.red[700]
                        : Colors.blue[700],
              ),
            ),
            Text(
              DateFormat('MMM d').format(transaction.date),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
