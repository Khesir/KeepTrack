import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/core/ui/scoped_screen.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/features/finance/modules/account/domain/entities/account.dart';
import 'package:persona_codex/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../../../modules/budget/domain/entities/budget.dart';
import '../../../../modules/budget/domain/entities/budget_category.dart';
import '../../../state/account_controller.dart';
import '../../../state/budget_controller.dart';

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
  late Budget _currentBudget;

  @override
  void registerServices() {
    _controller = locator.get<BudgetController>();
    _accountController = locator.get<AccountController>();
  }

  @override
  void initState() {
    super.initState();
    _currentBudget = widget.budget;
  }

  @override
  void onReady() {
    _controller.loadBudgets();
    _accountController.loadAccounts();
  }

  @override
  void onDispose() {
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

    // Reload budget after returning from edit
    _controller.loadBudgets();
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
                      Text(
                        _formatMonthDisplay(_currentBudget.month),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                _buildQuickStat('Spent', _currentBudget.totalSpent, balanceColor),
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
                  'Spent',
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
                      'Spent',
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
}
