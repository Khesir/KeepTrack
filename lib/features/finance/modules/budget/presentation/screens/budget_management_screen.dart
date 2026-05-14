import 'package:flutter/material.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/scoped_screen.dart';
import '../../domain/entities/budget.dart';
import '../controllers/budget_controller.dart';
import '../sections/budget_summary_section.dart';
import '../widgets/budget_list_card.dart';

class BudgetManagementScreen extends ScopedScreen {
  const BudgetManagementScreen({super.key});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState
    extends ScopedScreenState<BudgetManagementScreen>
    with AppLayoutControlled {
  late final BudgetController _controller;
  BudgetStatus? _filterStatus;

  @override
  void registerServices() {
    _controller = locator.get<BudgetController>();
  }

  @override
  void onReady() {
    _controller.refreshBudgetsWithSpentAmounts();
  }

  void _createBudget() {
    context.goToBudgetCreate().then((created) {
      _controller.refreshBudgetsWithSpentAmounts();
      if (created == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _openBudget(Budget budget) {
    context
        .goToBudgetDetail(budget)
        .then((_) => _controller.refreshBudgetsWithSpentAmounts());
  }

  Future<void> _refreshAllBudgets() async {
    final budgets = _controller.state is AsyncData<List<Budget>>
        ? (_controller.state as AsyncData<List<Budget>>).data
        : <Budget>[];

    for (final budget in budgets) {
      if (budget.id != null && budget.status == BudgetStatus.active) {
        try {
          await _controller.manualRecalculateBudgetSpent(budget.id!);
        } catch (_) {
          // continue with next budget
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All budgets refreshed!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Budgets'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh All Budgets',
            onPressed: _refreshAllBudgets,
          ),
          if (_filterStatus != null)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              tooltip: 'Clear Filter',
              onPressed: () => setState(() => _filterStatus = null),
            ),
          PopupMenuButton<BudgetStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Budgets',
            onSelected: (status) => setState(() => _filterStatus = status),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All Budgets')),
              const PopupMenuDivider(),
              _statusMenuItem(BudgetStatus.active, AppColors.success, 'Active'),
              _statusMenuItem(BudgetStatus.closed, AppColors.textTertiary, 'Closed'),
            ],
          ),
        ],
      ),
      body: AsyncStreamBuilder<List<Budget>>(
        state: _controller,
        builder: (context, budgets) {
          if (budgets.isEmpty) {
            return _EmptyState(
              colorScheme: colorScheme,
              onCreateBudget: _createBudget,
            );
          }

          final filtered = _filterStatus == null
              ? budgets
              : budgets.where((b) => b.status == _filterStatus).toList();

          return Column(
            children: [
              BudgetSummarySection(
                budgets: budgets,
                onCreateBudget: _createBudget,
                onOpenBudget: _openBudget,
              ),
              if (_filterStatus != null)
                _FilterBanner(
                  filterStatus: _filterStatus!,
                  count: filtered.length,
                  onClear: () => setState(() => _filterStatus = null),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? _FilteredEmptyState(
                        colorScheme: colorScheme,
                        filterStatus: _filterStatus,
                        onClearFilter: () =>
                            setState(() => _filterStatus = null),
                      )
                    : RefreshIndicator(
                        onRefresh: _controller.loadBudgetsWithSpentAmounts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filtered.length,
                          itemBuilder: (_, index) => BudgetListCard(
                            budget: filtered[index],
                            onTap: () => _openBudget(filtered[index]),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
        loadingBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, message) => _ErrorState(
          message: message,
          onRetry: _controller.loadBudgetsWithSpentAmounts,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBudget,
        icon: const Icon(Icons.add),
        label: const Text('Create Budget'),
      ),
    );
  }

  PopupMenuItem<BudgetStatus?> _statusMenuItem(
    BudgetStatus status,
    Color color,
    String label,
  ) {
    return PopupMenuItem(
      value: status,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _FilterBanner extends StatelessWidget {
  final BudgetStatus filterStatus;
  final int count;
  final VoidCallback onClear;

  const _FilterBanner({
    required this.filterStatus,
    required this.count,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.infoLight,
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          Text('Showing ${filterStatus.displayName} budgets ($count)'),
          const Spacer(),
          TextButton(onPressed: onClear, child: const Text('Clear Filter')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final VoidCallback onCreateBudget;

  const _EmptyState({required this.colorScheme, required this.onCreateBudget});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No budgets yet',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create your first monthly budget to start\ntracking your income and expenses',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: onCreateBudget,
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final BudgetStatus? filterStatus;
  final VoidCallback onClearFilter;

  const _FilteredEmptyState({
    required this.colorScheme,
    required this.filterStatus,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No ${filterStatus?.displayName.toLowerCase() ?? ''} budgets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try adjusting your filter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: onClearFilter,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to Load Budgets',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
