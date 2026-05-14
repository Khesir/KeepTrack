import 'package:flutter/material.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';
import 'package:keep_track/core/ui/scoped_screen.dart';
import '../../domain/entities/budget.dart';
import '../controllers/budget_controller.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/budget_type_section.dart';

class BudgetsTabNew extends ScopedScreen {
  const BudgetsTabNew({super.key});

  @override
  State<BudgetsTabNew> createState() => _BudgetsTabNewState();
}

class _BudgetsTabNewState extends ScopedScreenState<BudgetsTabNew> {
  late final BudgetController _controller;

  @override
  void registerServices() {
    _controller = locator.get<BudgetController>();
  }

  @override
  void onReady() {
    _controller.loadBudgetsWithSpentAmounts();
  }

  Future<void> _onRefresh() async {
    await _controller.loadBudgetsWithSpentAmounts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget refreshed!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onManageBudgets() async {
    await Navigator.pushNamed(context, '/budget-management');
    if (mounted) _controller.refreshBudgetsWithSpentAmounts();
  }

  void _onBudgetTap(Budget budget) {
    Navigator.pushNamed(context, AppRoutes.budgetDetail, arguments: budget);
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final desktopBg = isDark
            ? AppColors.textPrimary
            : AppColors.backgroundSecondary;

        return Scaffold(
          backgroundColor: isDesktop ? desktopBg : null,
          body: AsyncStreamBuilder<List<Budget>>(
            state: _controller,
            loadingBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, message) => _BudgetsErrorState(
              message: message,
              onRetry: _controller.loadBudgetsWithSpentAmounts,
            ),
            builder: (context, budgets) {
              final active = budgets
                  .where((b) => b.status == BudgetStatus.active)
                  .toList()
                ..sort((a, b) => b.month.compareTo(a.month));

              final income = active
                  .where((b) => b.budgetType == BudgetType.income)
                  .toList();
              final expense = active
                  .where((b) => b.budgetType == BudgetType.expense)
                  .toList();

              if (income.isEmpty && expense.isEmpty) {
                return _BudgetsEmptyState(
                  isDesktop: isDesktop,
                  onManage: _onManageBudgets,
                );
              }

              return _BudgetsContent(
                incomeBudgets: income,
                expenseBudgets: expense,
                isDesktop: isDesktop,
                onRefresh: _onRefresh,
                onBudgetTap: _onBudgetTap,
                onManage: _onManageBudgets,
              );
            },
          ),
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton.extended(
                  onPressed: _onManageBudgets,
                  icon: const Icon(Icons.add),
                  label: const Text('Manage Budgets'),
                ),
        );
      },
    );
  }
}

class _BudgetsContent extends StatelessWidget {
  final List<Budget> incomeBudgets;
  final List<Budget> expenseBudgets;
  final bool isDesktop;
  final Future<void> Function() onRefresh;
  final void Function(Budget) onBudgetTap;
  final VoidCallback onManage;

  const _BudgetsContent({
    required this.incomeBudgets,
    required this.expenseBudgets,
    required this.isDesktop,
    required this.onRefresh,
    required this.onBudgetTap,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1400 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BudgetsHeader(isDesktop: isDesktop, onManage: onManage),
                SizedBox(height: isDesktop ? AppSpacing.xl : AppSpacing.lg),
                if (isDesktop)
                  _DesktopColumns(
                    incomeBudgets: incomeBudgets,
                    expenseBudgets: expenseBudgets,
                    onBudgetTap: onBudgetTap,
                  )
                else
                  _MobileStack(
                    incomeBudgets: incomeBudgets,
                    expenseBudgets: expenseBudgets,
                    onBudgetTap: onBudgetTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetsHeader extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback onManage;

  const _BudgetsHeader({required this.isDesktop, required this.onManage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Active Budgets',
          style: isDesktop
              ? AppTextStyles.h1
              : Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (isDesktop)
          ElevatedButton.icon(
            onPressed: onManage,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Manage Budgets'),
          ),
      ],
    );
  }
}

class _DesktopColumns extends StatelessWidget {
  final List<Budget> incomeBudgets;
  final List<Budget> expenseBudgets;
  final void Function(Budget) onBudgetTap;

  const _DesktopColumns({
    required this.incomeBudgets,
    required this.expenseBudgets,
    required this.onBudgetTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (incomeBudgets.isNotEmpty)
          Expanded(
            child: BudgetTypeSection(
              title: 'Income Budgets',
              budgets: incomeBudgets,
              color: AppColors.income,
              icon: Icons.arrow_downward,
              isDesktop: true,
              onBudgetTap: onBudgetTap,
            ),
          ),
        if (incomeBudgets.isNotEmpty && expenseBudgets.isNotEmpty)
          const SizedBox(width: AppSpacing.xl),
        if (expenseBudgets.isNotEmpty)
          Expanded(
            child: BudgetTypeSection(
              title: 'Expense Budgets',
              budgets: expenseBudgets,
              color: AppColors.expense,
              icon: Icons.arrow_upward,
              isDesktop: true,
              onBudgetTap: onBudgetTap,
            ),
          ),
      ],
    );
  }
}

class _MobileStack extends StatelessWidget {
  final List<Budget> incomeBudgets;
  final List<Budget> expenseBudgets;
  final void Function(Budget) onBudgetTap;

  const _MobileStack({
    required this.incomeBudgets,
    required this.expenseBudgets,
    required this.onBudgetTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (incomeBudgets.isNotEmpty)
          BudgetTypeSection(
            title: 'Income Budgets',
            budgets: incomeBudgets,
            color: AppColors.income,
            icon: Icons.arrow_downward,
            isDesktop: false,
            onBudgetTap: onBudgetTap,
          ),
        if (incomeBudgets.isNotEmpty && expenseBudgets.isNotEmpty)
          const SizedBox(height: AppSpacing.lg),
        if (expenseBudgets.isNotEmpty)
          BudgetTypeSection(
            title: 'Expense Budgets',
            budgets: expenseBudgets,
            color: AppColors.expense,
            icon: Icons.arrow_upward,
            isDesktop: false,
            onBudgetTap: onBudgetTap,
          ),
      ],
    );
  }
}

class _BudgetsEmptyState extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback onManage;

  const _BudgetsEmptyState({required this.isDesktop, required this.onManage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Active Budgets',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create a budget to start tracking your finances',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (isDesktop) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onManage,
                icon: const Icon(Icons.add),
                label: const Text('Create Budget'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BudgetsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Error loading budgets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
