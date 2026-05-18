import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/ui/scoped_screen.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import '../../domain/entities/budget.dart';
import '../controllers/budget_controller.dart';
import '../../../../presentation/state/transaction_controller.dart';
import '../helpers/month_formatter.dart';
import '../widgets/budget_category_section.dart';
import '../widgets/budget_header_card.dart';
import '../widgets/budget_transaction_card.dart';
import '../widgets/budget_visual_bar.dart';

class BudgetDetailScreen extends ScopedScreen {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends ScopedScreenState<BudgetDetailScreen>
    with AppLayoutControlled {
  late final BudgetController _controller;
  late final TransactionController _transactionController;

  late Budget _currentBudget;
  List<Transaction> _budgetTransactions = [];
  StreamSubscription<AsyncState<List<Budget>>>? _budgetSubscription;
  StreamSubscription<AsyncState<List<Transaction>>>? _transactionSubscription;
  String? _selectedCategoryId;

  List<Transaction> get _filteredTransactions {
    if (_selectedCategoryId == null) return _budgetTransactions;
    return _budgetTransactions
        .where((t) => t.financeCategoryId == _selectedCategoryId)
        .toList();
  }

  @override
  void registerServices() {
    _controller = locator.get<BudgetController>();
    _transactionController = locator.get<TransactionController>();
  }

  @override
  void initState() {
    super.initState();
    _currentBudget = widget.budget;
    _listenToBudgetUpdates();
    _listenToTransactions();
  }

  @override
  void onReady() {
    _controller.refreshBudgetsWithSpentAmounts();
    _transactionController.loadAllTransactions();
  }

  void _listenToBudgetUpdates() {
    _budgetSubscription = _controller.stream.listen((state) {
      if (state is AsyncData<List<Budget>>) {
        final updated = state.data
            .where((b) => b.id == _currentBudget.id)
            .firstOrNull;
        if (mounted && updated != null) {
          setState(() => _currentBudget = updated);
        }
      }
    });
  }

  void _listenToTransactions() {
    _transactionSubscription = _transactionController.stream.listen((state) {
      if (state is AsyncData<List<Transaction>>) {
        final filtered = _filterTransactions(state.data);
        if (mounted) setState(() => _budgetTransactions = filtered);
      }
    });
  }

  List<Transaction> _filterTransactions(List<Transaction> all) {
    if (_currentBudget.periodType == BudgetPeriodType.monthly) {
      final parts = _currentBudget.month.split('-');
      if (parts.length != 2) return [];
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final categoryIds =
          _currentBudget.categories.map((c) => c.financeCategoryId).toSet();

      return all.where((t) {
        if (t.budgetId != null) return false;
        final inMonth = t.date.year == year && t.date.month == month;
        final inCategory = categoryIds.contains(t.financeCategoryId);
        final matchesType =
            (_currentBudget.budgetType == BudgetType.income &&
                t.type == TransactionType.income) ||
            (_currentBudget.budgetType == BudgetType.expense &&
                t.type == TransactionType.expense);
        return inMonth && inCategory && matchesType &&
            t.type != TransactionType.transfer;
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    return all
        .where((t) =>
            t.budgetId == _currentBudget.id &&
            t.type != TransactionType.transfer)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  void onDispose() {
    _budgetSubscription?.cancel();
    _transactionSubscription?.cancel();
  }

  void _toggleCategoryFilter(String categoryId) {
    setState(() {
      _selectedCategoryId =
          _selectedCategoryId == categoryId ? null : categoryId;
    });
  }

  Future<void> _refreshBudget() async {
    if (_currentBudget.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
              ),
            ),
            SizedBox(width: 12),
            Text('Recalculating budget...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );
    await _controller.manualRecalculateBudgetSpent(_currentBudget.id!);
    await _transactionController.loadAllTransactions();
    if (mounted) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Budget recalculated successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleBudgetStatus() async {
    final newStatus = _currentBudget.status == BudgetStatus.active
        ? BudgetStatus.closed
        : BudgetStatus.active;
    final updated = _currentBudget.copyWith(
      status: newStatus,
      closedAt: newStatus == BudgetStatus.closed ? DateTime.now() : null,
    );
    await _controller.updateBudget(updated);
    setState(() => _currentBudget = updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Budget ${newStatus == BudgetStatus.closed ? 'closed' : 'reopened'} successfully',
          ),
        ),
      );
    }
  }

  Future<void> _editBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Budget'),
        content: const Text(
          'Changes to category targets may affect your budget tracking.\n\nDo you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Navigator.of(context).pushNamed('/budget/edit', arguments: _currentBudget);
    await _controller.refreshBudgetsWithSpentAmounts();
  }

  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete the budget for ${formatMonthDisplay(_currentBudget.month)}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _controller.deleteBudget(_currentBudget.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget deleted successfully')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final balanceColor = _currentBudget.status == BudgetStatus.closed
        ? (_currentBudget.surplusOrDeficit >= 0 ? AppColors.success : AppColors.error)
        : (_currentBudget.isOverBudget ? AppColors.error : AppColors.info);

    return Scaffold(
      appBar: AppBar(
        title: Text(formatMonthDisplay(_currentBudget.month)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Budget',
            onPressed: _refreshBudget,
          ),
          _BudgetActionsMenu(
            budget: _currentBudget,
            onRefresh: _refreshBudget,
            onEdit: _editBudget,
            onToggleStatus: _toggleBudgetStatus,
            onDelete: _deleteBudget,
          ),
        ],
      ),
      body: isDesktop
          ? _DesktopLayout(
              budget: _currentBudget,
              balanceColor: balanceColor,
              transactions: _filteredTransactions,
              selectedCategoryId: _selectedCategoryId,
              onCategoryTap: _toggleCategoryFilter,
              onClearFilter: () => setState(() => _selectedCategoryId = null),
            )
          : _MobileLayout(
              budget: _currentBudget,
              balanceColor: balanceColor,
              transactions: _filteredTransactions,
              selectedCategoryId: _selectedCategoryId,
              onCategoryTap: _toggleCategoryFilter,
              onClearFilter: () => setState(() => _selectedCategoryId = null),
            ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Budget budget;
  final Color balanceColor;
  final List<Transaction> transactions;
  final String? selectedCategoryId;
  final void Function(String) onCategoryTap;
  final VoidCallback onClearFilter;

  const _DesktopLayout({
    required this.budget,
    required this.balanceColor,
    required this.transactions,
    required this.selectedCategoryId,
    required this.onCategoryTap,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BudgetHeaderCard(
                  budget: budget,
                  balanceColor: balanceColor,
                ),
                const SizedBox(height: AppSpacing.md),
                BudgetVisualBar(budget: budget),
                const SizedBox(height: AppSpacing.lg),
                _CategoriesHeader(
                  selectedCategoryId: selectedCategoryId,
                  onClear: onClearFilter,
                ),
                const SizedBox(height: AppSpacing.sm + 4),
                if (budget.categories.isEmpty)
                  const _EmptyCategoriesState()
                else
                  BudgetCategorySection(
                    budget: budget,
                    selectedCategoryId: selectedCategoryId,
                    isDesktop: true,
                    onCategoryTap: onCategoryTap,
                  ),
              ],
            ),
          ),
        ),
        Container(
          width: 450,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Column(
            children: [
              _TransactionsHeader(
                transactions: transactions,
                selectedCategoryId: selectedCategoryId,
              ),
              const Divider(height: 1),
              Expanded(
                child: transactions.isEmpty
                    ? _EmptyTransactionsState(
                        isFiltered: selectedCategoryId != null,
                      )
                    : _TransactionsList(transactions: transactions, budget: budget),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Budget budget;
  final Color balanceColor;
  final List<Transaction> transactions;
  final String? selectedCategoryId;
  final void Function(String) onCategoryTap;
  final VoidCallback onClearFilter;

  const _MobileLayout({
    required this.budget,
    required this.balanceColor,
    required this.transactions,
    required this.selectedCategoryId,
    required this.onCategoryTap,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BudgetHeaderCard(budget: budget, balanceColor: balanceColor),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: BudgetVisualBar(budget: budget),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _CategoriesHeader(
              selectedCategoryId: selectedCategoryId,
              onClear: onClearFilter,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          if (budget.categories.isEmpty)
            const _EmptyCategoriesState()
          else
            BudgetCategorySection(
              budget: budget,
              selectedCategoryId: selectedCategoryId,
              isDesktop: false,
              onCategoryTap: onCategoryTap,
            ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _TransactionsHeader(
              transactions: transactions,
              selectedCategoryId: selectedCategoryId,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          if (transactions.isEmpty)
            _EmptyTransactionsState(isFiltered: selectedCategoryId != null)
          else
            _TransactionsList(transactions: transactions, budget: budget),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _CategoriesHeader extends StatelessWidget {
  final String? selectedCategoryId;
  final VoidCallback onClear;

  const _CategoriesHeader({
    required this.selectedCategoryId,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Categories',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (selectedCategoryId != null)
          TextButton.icon(
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Clear Filter'),
            onPressed: onClear,
          ),
      ],
    );
  }
}

class _TransactionsHeader extends StatelessWidget {
  final List<Transaction> transactions;
  final String? selectedCategoryId;

  const _TransactionsHeader({
    required this.transactions,
    required this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final total = transactions.fold<double>(0.0, (sum, t) {
      if (t.type == TransactionType.expense) return sum - t.totalCost;
      if (t.type == TransactionType.income) return sum + t.totalCost;
      return sum + t.amount;
    });
    final isNegative = total < 0;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${transactions.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (transactions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  'Total: ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${isNegative ? '-' : '+'}₱${total.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isNegative ? AppColors.error : AppColors.success,
                  ),
                ),
                if (selectedCategoryId != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Filtered',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionsList extends StatelessWidget {
  final List<Transaction> transactions;
  final Budget budget;

  const _TransactionsList({required this.transactions, required this.budget});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: transactions.length,
      itemBuilder: (_, index) {
        final t = transactions[index];
        final budgetCat = budget.categories
            .where((c) => c.financeCategoryId == t.financeCategoryId)
            .firstOrNull;
        return BudgetTransactionCard(
          transaction: t,
          budgetCategory: budgetCat,
        );
      },
    );
  }
}

class _EmptyCategoriesState extends StatelessWidget {
  const _EmptyCategoriesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(Icons.category_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No categories',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactionsState extends StatelessWidget {
  final bool isFiltered;

  const _EmptyTransactionsState({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isFiltered
                  ? 'No transactions in this category'
                  : 'No transactions yet',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              isFiltered
                  ? 'Click the category again to clear filter'
                  : 'Transactions in this budget will appear here',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetActionsMenu extends StatelessWidget {
  final Budget budget;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _BudgetActionsMenu({
    required this.budget,
    required this.onRefresh,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'refresh':
            onRefresh();
          case 'edit':
            onEdit();
          case 'toggle':
            onToggleStatus();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'refresh',
          child: Row(children: [
            Icon(Icons.refresh, size: 20),
            SizedBox(width: 12),
            Text('Refresh Amounts'),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit, size: 20),
            SizedBox(width: 12),
            Text('Edit Budget'),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'toggle',
          child: Row(children: [
            Icon(
              budget.status == BudgetStatus.active
                  ? Icons.close
                  : Icons.check_circle,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              budget.status == BudgetStatus.active
                  ? 'Close Budget'
                  : 'Reopen Budget',
            ),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete, size: 20, color: AppColors.error),
            SizedBox(width: 12),
            Text('Delete Budget', style: TextStyle(color: AppColors.error)),
          ]),
        ),
      ],
    );
  }
}
