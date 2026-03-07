import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/payment_enums.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/presentation/state/account_controller.dart';
import 'package:keep_track/features/finance/presentation/state/budget_controller.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/planned_payment_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmt(double amount) => '₱${NumberFormat('#,##0.00').format(amount)}';

// ─── BudgetMonthScreen ────────────────────────────────────────────────────────

class BudgetMonthScreen extends StatefulWidget {
  const BudgetMonthScreen({super.key});

  @override
  State<BudgetMonthScreen> createState() => _BudgetMonthScreenState();
}

class _BudgetMonthScreenState extends State<BudgetMonthScreen> {
  late final BudgetController _budgetController;
  late final DebtController _debtController;
  late final PlannedPaymentController _plannedPaymentController;
  late final FinanceCategoryController _categoryController;
  late final AccountController _accountController;
  late final TransactionController _transactionController;
  late final SupabaseService _supabaseService;

  DateTime _currentMonth = DateTime.now();
  Budget? _selectedGroup;
  BudgetCategory? _selectedCategory;
  Budget? _selectedCategoryGroup;

  @override
  void initState() {
    super.initState();
    _budgetController = locator.get<BudgetController>();
    _debtController = locator.get<DebtController>();
    _plannedPaymentController = locator.get<PlannedPaymentController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _accountController = locator.get<AccountController>();
    _transactionController = locator.get<TransactionController>();
    _supabaseService = locator.get<SupabaseService>();
    _loadMonthTransactions();
  }

  // ── Month helpers ─────────────────────────────────────────────────────────

  String get _monthKey =>
      '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';

  String get _monthLabel => DateFormat('MMMM yyyy').format(_currentMonth);

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedGroup = null;
      _selectedCategory = null;
      _selectedCategoryGroup = null;
    });
    _loadMonthTransactions();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedGroup = null;
      _selectedCategory = null;
      _selectedCategoryGroup = null;
    });
    _loadMonthTransactions();
  }

  void _loadMonthTransactions() {
    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final end = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      1,
    ).subtract(const Duration(microseconds: 1));
    _transactionController.loadTransactionsByDateRange(start, end);
  }

  List<Budget> _budgetsForMonth(List<Budget> all, String key) => all
      .where((b) => b.month == key && b.status == BudgetStatus.active)
      .toList();

  // ── Dialogs / sheets ─────────────────────────────────────────────────────

  void _showAddCategorySheet(Budget group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddCategorySheet(
        group: group,
        categoryController: _categoryController,
        supabaseService: _supabaseService,
        onSave: (cat) => _budgetController.addCategory(group.id!, cat),
      ),
    );
  }

  void _showEditCategorySheet(Budget group, BudgetCategory cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditCategorySheet(
        group: group,
        category: cat,
        categoryController: _categoryController,
        budgetController: _budgetController,
      ),
    );
  }

  void _showEditGroupSheet(Budget group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditGroupSheet(
        group: group,
        budgetController: _budgetController,
      ),
    );
  }

  Future<void> _updateCategoryAmount(
    Budget group,
    BudgetCategory cat,
    double amount,
  ) async {
    await _budgetController.updateCategory(
      group.id!,
      cat.copyWith(targetAmount: amount),
    );
  }

  void _showCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateGroupSheet(
        monthKey: _monthKey,
        monthLabel: _monthLabel,
        budgetController: _budgetController,
        supabaseService: _supabaseService,
      ),
    );
  }

  Future<void> _confirmDeleteCategory(Budget group, BudgetCategory cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Remove "${cat.financeCategory?.name ?? 'category'}" from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true && cat.id != null) {
      await _budgetController.deleteCategory(group.id!, cat.id!);
    }
  }

  void _showCategoryDetail(
    Budget group,
    BudgetCategory cat,
    List<Transaction> allTransactions,
  ) {
    final catTxns =
        allTransactions
            .where((t) => t.financeCategoryId == cat.financeCategoryId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryDetailSheet(
        category: cat,
        transactions: catTxns,
        isIncomeGroup: group.budgetType == BudgetType.income,
      ),
    );
  }

  void _showCommitmentsSheet(List<PlannedPayment> payments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommitmentsSheet(
        payments: payments,
        accountController: _accountController,
        categoryController: _categoryController,
        supabaseService: _supabaseService,
        plannedPaymentController: _plannedPaymentController,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncStreamBuilder<List<Budget>>(
        state: _budgetController,
        builder: (context, allBudgets) {
          return AsyncStreamBuilder<List<Transaction>>(
            state: _transactionController,
            builder: (context, allTransactions) {
              return AsyncStreamBuilder<List<Debt>>(
                state: _debtController,
                builder: (context, allDebts) {
                  return AsyncStreamBuilder<List<PlannedPayment>>(
                    state: _plannedPaymentController,
                    builder: (context, allPayments) {
                      return _buildBody(
                        allBudgets: allBudgets,
                        allTransactions: allTransactions,
                        allDebts: allDebts,
                        allPayments: allPayments,
                      );
                    },
                    loadingBuilder: (_) => _buildBody(
                      allBudgets: allBudgets,
                      allTransactions: allTransactions,
                      allDebts: const [],
                      allPayments: const [],
                    ),
                    errorBuilder: (_, __) => _buildBody(
                      allBudgets: allBudgets,
                      allTransactions: allTransactions,
                      allDebts: const [],
                      allPayments: const [],
                    ),
                  );
                },
                loadingBuilder: (_) => _buildBody(
                  allBudgets: allBudgets,
                  allTransactions: allTransactions,
                  allDebts: const [],
                  allPayments: const [],
                ),
                errorBuilder: (_, __) => _buildBody(
                  allBudgets: allBudgets,
                  allTransactions: allTransactions,
                  allDebts: const [],
                  allPayments: const [],
                ),
              );
            },
            loadingBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, msg) => Center(child: Text('Error: $msg')),
          );
        },
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, msg) => Center(child: Text('Error: $msg')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.transactionCreate),
        icon: const Icon(Icons.add),
        label: const Text('New Transaction'),
      ),
    );
  }

  Widget _buildBody({
    required List<Budget> allBudgets,
    required List<Transaction> allTransactions,
    required List<Debt> allDebts,
    required List<PlannedPayment> allPayments,
  }) {
    final monthBudgets = _budgetsForMonth(allBudgets, _monthKey)
      ..sort((a, b) {
        // Income always before expense
        if (a.budgetType == b.budgetType) return 0;
        return a.budgetType == BudgetType.income ? -1 : 1;
      });

    // Filter transactions strictly to the selected month
    final monthStart = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final monthEnd = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    final monthTransactions = allTransactions
        .where((t) =>
            !t.date.isBefore(monthStart) && t.date.isBefore(monthEnd))
        .toList();

    final debts = allDebts
        .where(
          (d) => d.type == DebtType.borrowing && d.status == DebtStatus.active,
        )
        .toList();
    final receivables = allDebts
        .where(
          (d) => d.type == DebtType.lending && d.status == DebtStatus.active,
        )
        .toList();
    final activePayments = allPayments
        .where((p) => p.status == PaymentStatus.active)
        .toList();

    // Keep _selectedGroup in sync: clear if it no longer exists this month
    if (_selectedGroup != null &&
        !monthBudgets.any((b) => b.id == _selectedGroup!.id)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() {
          _selectedGroup = null;
          _selectedCategory = null;
          _selectedCategoryGroup = null;
        }),
      );
    }
    // Sync selected group data from the latest stream snapshot
    final syncedSelected = _selectedGroup == null
        ? null
        : monthBudgets.firstWhere(
            (b) => b.id == _selectedGroup!.id,
            orElse: () => _selectedGroup!,
          );
    // Sync selected category from the latest stream snapshot
    Budget? syncedCategoryGroup;
    if (_selectedCategoryGroup != null) {
      final idx = monthBudgets.indexWhere(
          (b) => b.id == _selectedCategoryGroup!.id);
      syncedCategoryGroup = idx >= 0 ? monthBudgets[idx] : null;
    }
    BudgetCategory? syncedCategory;
    if (_selectedCategory != null && syncedCategoryGroup != null) {
      final idx = syncedCategoryGroup.categories.indexWhere(
          (c) => c.id == _selectedCategory!.id);
      syncedCategory = idx >= 0
          ? syncedCategoryGroup.categories[idx]
          : _selectedCategory;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        Widget buildSummaryPanel() => _SideSummaryPanel(
          selectedGroup: syncedSelected,
          selectedCategory: syncedCategory,
          selectedCategoryGroup: syncedCategoryGroup,
          allBudgets: monthBudgets,
          allTransactions: monthTransactions,
          onClose: () => setState(() {
            _selectedGroup = null;
            _selectedCategory = null;
            _selectedCategoryGroup = null;
          }),
          onCategoryPanelClose: () => setState(() {
            _selectedCategory = null;
            _selectedCategoryGroup = null;
          }),
          onEditCategory: syncedCategory != null && syncedCategoryGroup != null
              ? () => _showEditCategorySheet(syncedCategoryGroup!, syncedCategory!)
              : null,
          onAddCategory: _showAddCategorySheet,
          onCategoryDetailTap: (cat) {
            if (syncedSelected != null) {
              _showCategoryDetail(syncedSelected, cat, monthTransactions);
            }
          },
          onUpdateAmount: _updateCategoryAmount,
          onCategoryDelete: _confirmDeleteCategory,
        );

        Widget budgetCard = Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border),
          ),
          child: CustomScrollView(
            slivers: [
              // Budget totals summary
              SliverToBoxAdapter(
                child: _BudgetSummaryBar(
                  monthBudgets: monthBudgets,
                  activePayments: activePayments,
                  onCommitmentsTab: () =>
                      _showCommitmentsSheet(activePayments),
                ),
              ),

              if (monthBudgets.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyBudgetState(
                    monthLabel: _monthLabel,
                    onStart: _showCreateGroupSheet,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final group = monthBudgets[i];
                    return _BudgetGroupCard(
                      group: group,
                      monthLabel: _monthLabel,
                      isSelected: _selectedGroup?.id == group.id,
                      onSelect: () => setState(() {
                        _selectedGroup = _selectedGroup?.id == group.id
                            ? null
                            : group;
                      }),
                      onEditGroup: () => _showEditGroupSheet(group),
                      onAddRow: () => _showAddCategorySheet(group),
                      onCategoryEditTap: (cat) =>
                          _showEditCategorySheet(group, cat),
                      onCategoryDetailTap: (cat) {
                        if (isWide) {
                          setState(() {
                            _selectedCategory = cat;
                            _selectedCategoryGroup = group;
                          });
                        } else {
                          _showCategoryDetail(group, cat, monthTransactions);
                        }
                      },
                      onUpdateAmount: (cat, amount) =>
                          _updateCategoryAmount(group, cat, amount),
                      onCategoryDelete: (cat) =>
                          _confirmDeleteCategory(group, cat),
                    );
                  }, childCount: monthBudgets.length),
                ),

              SliverToBoxAdapter(
                child: _GhostAddRow(
                  label: 'Add Budget Group',
                  onTap: _showCreateGroupSheet,
                ),
              ),

              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverToBoxAdapter(
                child: _DebtSection(
                  title: 'DEBTS',
                  debts: debts,
                  isReceivable: false,
                  onAdd: () =>
                      Navigator.pushNamed(context, AppRoutes.debtsManagement),
                ),
              ),

              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverToBoxAdapter(
                child: _DebtSection(
                  title: 'RECEIVABLES',
                  debts: receivables,
                  isReceivable: true,
                  onAdd: () =>
                      Navigator.pushNamed(context, AppRoutes.debtsManagement),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );

        return Column(
          children: [
            // Full-width month nav — fully outside both cards
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: _MonthHeader(
                monthLabel: _monthLabel,
                onPrev: _prevMonth,
                onNext: _nextMonth,
                onSummaryTap: isWide
                    ? null
                    : () => _showSummarySheet(context, buildSummaryPanel()),
              ),
            ),

            // Cards row
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: budgetCard),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 320,
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: AppColors.border),
                              ),
                              child: buildSummaryPanel(),
                            ),
                          ),
                        ],
                      )
                    : budgetCard,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSummarySheet(BuildContext context, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        builder: (_, __) => Card(
          margin: EdgeInsets.zero,
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Budget Summary Bar (inside budget card) ──────────────────────────────────

class _BudgetSummaryBar extends StatelessWidget {
  final List<Budget> monthBudgets;
  final List<PlannedPayment> activePayments;
  final VoidCallback onCommitmentsTab;

  const _BudgetSummaryBar({
    required this.monthBudgets,
    required this.activePayments,
    required this.onCommitmentsTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double incomeReceived = 0;
    double expenseSpent = 0;
    for (final b in monthBudgets) {
      if (b.budgetType == BudgetType.income) {
        incomeReceived += b.totalIncomeReceived;
      } else {
        expenseSpent += b.totalExpensesSpent;
      }
    }
    final net = incomeReceived - expenseSpent;
    final netColor = net >= 0 ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SummaryChip(
                label: 'Income',
                value: _fmt(incomeReceived),
                valueColor: AppColors.success,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Expenses',
                value: _fmt(expenseSpent),
                valueColor: AppColors.error,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: net >= 0 ? 'Left' : 'Over',
                value: _fmt(net.abs()),
                valueColor: netColor,
              ),
            ],
          ),
          if (activePayments.isNotEmpty) ...[
            const SizedBox(height: 8),
            ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: CircleAvatar(
                radius: 9,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  '${activePayments.length}',
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
              label: const Text('Upcoming Commitments',
                  style: TextStyle(fontSize: 12)),
              onPressed: onCommitmentsTab,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryChip({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Month Header ─────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onSummaryTap;

  const _MonthHeader({
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
    this.onSummaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
        Expanded(
          child: Text(
            monthLabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3,
          ),
        ),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        if (onSummaryTap != null)
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: onSummaryTap,
            tooltip: 'Summary & Transactions',
          ),
      ],
    );
  }
}

// ─── Empty Budget State ───────────────────────────────────────────────────────

class _EmptyBudgetState extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onStart;

  const _EmptyBudgetState({required this.monthLabel, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 72,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No budget for $monthLabel',
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start planning your monthly budget.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.add),
                label: Text('Start Planning for $monthLabel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Budget Group Card ────────────────────────────────────────────────────────

class _BudgetGroupCard extends StatelessWidget {
  final Budget group;
  final String monthLabel;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEditGroup;
  final VoidCallback onAddRow;
  final void Function(BudgetCategory) onCategoryDetailTap;
  final void Function(BudgetCategory) onCategoryEditTap;
  final Future<void> Function(BudgetCategory, double) onUpdateAmount;
  final void Function(BudgetCategory) onCategoryDelete;

  const _BudgetGroupCard({
    required this.group,
    required this.monthLabel,
    required this.isSelected,
    required this.onSelect,
    required this.onEditGroup,
    required this.onAddRow,
    required this.onCategoryDetailTap,
    required this.onCategoryEditTap,
    required this.onUpdateAmount,
    required this.onCategoryDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = group.budgetType == BudgetType.income;
    final totalPlanned = group.budgetTarget;
    final totalActual = group.totalSpent;
    final diff = totalActual - totalPlanned; // positive = over/extra
    final progress = totalPlanned > 0
        ? (totalActual / totalPlanned).clamp(0.0, 1.0)
        : 0.0;
    // For income: over is good (green). For expense: over is bad (red).
    final isOverBudget = totalActual > totalPlanned;
    final overColor = isIncome ? AppColors.success : AppColors.error;
    final progressColor = isOverBudget
        ? overColor
        : progress > 0.85 && !isIncome
        ? AppColors.warning
        : AppColors.accent;

    // Pill label & color
    final pillLabel = isIncome
        ? diff > 0
            ? '${_fmt(diff)} Extra'
            : '${_fmt(-diff)} Left'
        : diff > 0
            ? '${_fmt(diff)} Over'
            : '${_fmt(-diff)} Left';
    final pillColor = isIncome
        ? diff > 0
            ? AppColors.success
            : AppColors.textSecondary
        : diff > 0
            ? AppColors.error
            : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        InkWell(
          onTap: onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.06)
                : Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Selection indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 3,
                      height: 16,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        group.title ?? monthLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Actual / Planned
                    Text(
                      _fmt(totalActual),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isOverBudget
                            ? overColor
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' / ${_fmt(totalPlanned)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Left / Extra / Over pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: pillColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pillLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: pillColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      color: AppColors.textTertiary,
                      onPressed: onEditGroup,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: AppColors.textTertiary.withValues(
                      alpha: 0.15,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // ── Category rows ────────────────────────────────────────────────
        if (group.categories.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.2),
            child: Row(
              children: const [
                Expanded(
                  child: Text('Category',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('Planned',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500)),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Text('Spent',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ...group.categories.map((cat) => _CategoryRow(
              key: ValueKey(cat.id ?? cat.financeCategoryId),
              category: cat,
              isIncomeGroup: isIncome,
              accentColor: AppColors.accent,
              onDetailTap: () => onCategoryDetailTap(cat),
              onEditTap: () => onCategoryEditTap(cat),
              onUpdateAmount: (amount) => onUpdateAmount(cat, amount),
              onLongPress: () => onCategoryDelete(cat),
            )),
        _GhostAddRow(label: 'Add Category', onTap: onAddRow),
      ],
    );
  }
}

// ─── Category Row (with inline amount editing + progress bar) ─────────────────

class _CategoryRow extends StatefulWidget {
  final BudgetCategory category;
  final bool isIncomeGroup;
  final Color accentColor;
  final VoidCallback onDetailTap;
  final VoidCallback onEditTap;
  final Future<void> Function(double) onUpdateAmount;
  final VoidCallback onLongPress;

  const _CategoryRow({
    super.key,
    required this.category,
    required this.isIncomeGroup,
    required this.accentColor,
    required this.onDetailTap,
    required this.onEditTap,
    required this.onUpdateAmount,
    required this.onLongPress,
  });

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _amountCtrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.category.targetAmount.toStringAsFixed(2),
    );
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_CategoryRow old) {
    super.didUpdateWidget(old);
    // Sync display when the stream updates the category (but not while editing)
    if (!_editing &&
        old.category.targetAmount != widget.category.targetAmount) {
      _amountCtrl.text = widget.category.targetAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      _commitEdit();
    }
  }

  void _startEdit() => setState(() {
    _editing = true;
    _amountCtrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _amountCtrl.text.length,
    );
  });

  Future<void> _commitEdit() async {
    final amount = double.tryParse(_amountCtrl.text);
    // Revert if invalid or unchanged
    if (amount == null ||
        amount <= 0 ||
        amount == widget.category.targetAmount) {
      _amountCtrl.text = widget.category.targetAmount.toStringAsFixed(2);
      if (mounted) setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onUpdateAmount(amount);
    } finally {
      if (mounted) {
        setState(() {
          _editing = false;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final planned = widget.category.targetAmount;
    final actual = widget.category.spentAmount ?? 0.0;
    final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0;
    final isOver = actual > planned;
    final isIncome = widget.isIncomeGroup;
    // Income: over = good (green). Expense: over = bad (red).
    final overColor = isIncome ? AppColors.success : AppColors.error;
    final progressColor = isOver
        ? overColor
        : progress > 0.85 && !isIncome
        ? AppColors.warning
        : widget.accentColor;

    return InkWell(
      onTap: widget.onDetailTap,
      onLongPress: widget.onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category name
                Expanded(
                  child: Text(
                    widget.category.financeCategory?.name ?? '—',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Edit button
                GestureDetector(
                  onTap: widget.onEditTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                // Planned amount — tap to edit inline
                GestureDetector(
                  onTap: _editing ? null : _startEdit,
                  child: SizedBox(
                    width: 80,
                    child: _editing
                        ? TextField(
                            controller: _amountCtrl,
                            focusNode: _focusNode,
                            autofocus: true,
                            textAlign: TextAlign.right,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: widget.accentColor,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: widget.accentColor,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: _saving
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _commitEdit(),
                          )
                        : Text(
                            _fmt(planned),
                            textAlign: TextAlign.right,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.dotted,
                              decorationColor: AppColors.textTertiary,
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 8),

                // Actual amount (read-only)
                SizedBox(
                  width: 72,
                  child: Text(
                    _fmt(actual),
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isOver
                          ? overColor
                          : actual > 0
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: AppColors.textTertiary.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction Mini Row ─────────────────────────────────────────────────────

class _TransactionMiniRow extends StatelessWidget {
  final Transaction transaction;

  const _TransactionMiniRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amtColor = isIncome ? AppColors.success : AppColors.error;
    final sign = isIncome ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Text(
            DateFormat('MMM d').format(transaction.date),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              transaction.description ?? '—',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$sign${_fmt(transaction.amount)}',
            style: AppTextStyles.caption.copyWith(
              color: amtColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Detail Content (shared between sheet and side panel) ────────────

class _CategoryDetailContent extends StatelessWidget {
  final BudgetCategory category;
  final List<Transaction> transactions;
  final bool isIncomeGroup;
  final ScrollController? scrollController;

  const _CategoryDetailContent({
    required this.category,
    required this.transactions,
    this.isIncomeGroup = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final planned = category.targetAmount;
    final actual = category.spentAmount ?? 0.0;
    final diff = actual - planned; // positive = over/extra
    final isOver = diff > 0;
    // Income: over = green (good). Expense: over = red (bad).
    final overColor = isIncomeGroup ? AppColors.success : AppColors.error;
    final progressColor = isOver
        ? overColor
        : isIncomeGroup
            ? AppColors.accent
            : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.financeCategory?.name ?? 'Category',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatChip(
                    label: 'Planned',
                    value: _fmt(planned),
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Actual',
                    value: _fmt(actual),
                    color: actual > 0
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: isIncomeGroup
                        ? (isOver ? 'Extra' : 'Pending')
                        : (isOver ? 'Over by' : 'Left'),
                    value: _fmt(diff.abs()),
                    color: isIncomeGroup
                        ? (isOver ? AppColors.success : AppColors.textSecondary)
                        : (isOver ? AppColors.error : AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: planned > 0
                      ? (actual / planned).clamp(0.0, 1.0)
                      : 0.0,
                  minHeight: 6,
                  backgroundColor:
                      AppColors.textTertiary.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'TRANSACTIONS',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),

        // Transactions list
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Text(
                    'No transactions yet',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = transactions[i];
                    final isIncome = t.type == TransactionType.income;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MMM d').format(t.date),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.description ?? '—',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${isIncome ? '+' : '-'}${_fmt(t.amount)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isIncome
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Category Detail Sheet (mobile bottom sheet wrapper) ─────────────────────

class _CategoryDetailSheet extends StatelessWidget {
  final BudgetCategory category;
  final List<Transaction> transactions;
  final bool isIncomeGroup;

  const _CategoryDetailSheet({
    required this.category,
    required this.transactions,
    this.isIncomeGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: _CategoryDetailContent(
              category: category,
              transactions: transactions,
              isIncomeGroup: isIncomeGroup,
              scrollController: scrollCtrl,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Group Ghost Button ───────────────────────────────────────────────────

class _GhostAddRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GhostAddRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Tab Panel ─────────────────────────────────────────────────────────

class _SideSummaryPanel extends StatefulWidget {
  final Budget? selectedGroup;
  final BudgetCategory? selectedCategory;
  final Budget? selectedCategoryGroup;
  final List<Budget> allBudgets;
  final List<Transaction> allTransactions;
  final VoidCallback onClose;
  final VoidCallback onCategoryPanelClose;
  final VoidCallback? onEditCategory;
  final void Function(Budget) onAddCategory;
  final void Function(BudgetCategory) onCategoryDetailTap;
  final Future<void> Function(Budget, BudgetCategory, double) onUpdateAmount;
  final void Function(Budget, BudgetCategory) onCategoryDelete;

  const _SideSummaryPanel({
    required this.selectedGroup,
    required this.selectedCategory,
    required this.selectedCategoryGroup,
    required this.allBudgets,
    required this.allTransactions,
    required this.onClose,
    required this.onCategoryPanelClose,
    this.onEditCategory,
    required this.onAddCategory,
    required this.onCategoryDetailTap,
    required this.onUpdateAmount,
    required this.onCategoryDelete,
  });

  @override
  State<_SideSummaryPanel> createState() => _SideSummaryPanelState();
}

class _SideSummaryPanelState extends State<_SideSummaryPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;

  bool get _isCategoryMode => widget.selectedCategory != null;

  int get _tabCount => widget.selectedGroup != null ? 1 : 2;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _isCategoryMode ? 1 : _tabCount, vsync: this);
  }

  @override
  void didUpdateWidget(_SideSummaryPanel old) {
    super.didUpdateWidget(old);
    final wasCategory = old.selectedCategory != null;
    final isCategory = widget.selectedCategory != null;
    final wasGroup = old.selectedGroup != null;
    final isGroup = widget.selectedGroup != null;

    final modeChanged = wasCategory != isCategory ||
        old.selectedCategory?.id != widget.selectedCategory?.id ||
        wasGroup != isGroup ||
        old.selectedGroup?.id != widget.selectedGroup?.id;

    if (modeChanged) {
      _tabController.dispose();
      _tabController = TabController(
          length: isCategory ? 1 : (isGroup ? 1 : 2), vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = widget.selectedCategory;
    final group = widget.selectedGroup;

    // ── Category detail mode ───────────────────────────────────────────
    if (cat != null) {
      final catTxns = widget.allTransactions
          .where((t) => t.financeCategoryId == cat.financeCategoryId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar with back button
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  onPressed: widget.onCategoryPanelClose,
                  color: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    cat.financeCategory?.name ?? 'Category',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onEditCategory != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    onPressed: widget.onEditCategory,
                    color: AppColors.textTertiary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit category',
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 15),
                  onPressed: widget.onClose,
                  color: AppColors.textTertiary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _CategoryDetailContent(
              category: cat,
              transactions: catTxns,
              isIncomeGroup:
                  widget.selectedCategoryGroup?.budgetType == BudgetType.income,
            ),
          ),
        ],
      );
    }

    // ── Group / default mode ───────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.4),
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: group == null
              ? TabBar(
                  controller: _tabController,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: const [
                    Tab(text: 'Summary'),
                    Tab(text: 'Transactions'),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              group.title ?? '',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 15),
                            onPressed: widget.onClose,
                            color: AppColors.textTertiary,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(fontSize: 12),
                      tabs: const [Tab(text: 'Transactions')],
                    ),
                  ],
                ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: group == null
                ? [
                    _AllSummaryTab(budgets: widget.allBudgets),
                    _AllTransactionsTab(transactions: widget.allTransactions),
                  ]
                : [
                    _GroupTransactionsTab(
                      transactions: widget.allTransactions
                          .where((t) => t.budgetId == group.id)
                          .toList()
                        ..sort((a, b) => b.date.compareTo(a.date)),
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}

// ─── All Groups Summary Tab (Two Donut Charts by Category) ───────────────────

// Simple data model for a chart slice
class _ChartItem {
  final String name;
  final double value;
  const _ChartItem(this.name, this.value);
}

class _AllSummaryTab extends StatelessWidget {
  final List<Budget> budgets;

  const _AllSummaryTab({required this.budgets});

  static const _incomePalette = [
    Color(0xFF12B886),
    Color(0xFF2F9E44),
    Color(0xFF087F5B),
    Color(0xFF40C057),
    Color(0xFF63E6BE),
    Color(0xFF20C997),
  ];

  static const _expensePalette = [
    Color(0xFF4C6EF5),
    Color(0xFFF76707),
    Color(0xFFE64980),
    Color(0xFF7950F2),
    Color(0xFF1C7ED6),
    Color(0xFFE67700),
    Color(0xFFAE3EC9),
    Color(0xFF0CA678),
    Color(0xFFD6336C),
    Color(0xFF3BC9DB),
  ];

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return Center(
        child: Text('No budget groups yet.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiary)),
      );
    }

    // Flatten categories per type
    final incomeItems = budgets
        .where((b) => b.budgetType == BudgetType.income)
        .expand((b) => b.categories)
        .map((c) => _ChartItem(
              c.financeCategory?.name ?? '—',
              c.spentAmount ?? 0,
            ))
        .where((i) => i.value > 0)
        .toList();

    final expenseItems = budgets
        .where((b) => b.budgetType == BudgetType.expense)
        .expand((b) => b.categories)
        .map((c) => _ChartItem(
              c.financeCategory?.name ?? '—',
              c.spentAmount ?? 0,
            ))
        .where((i) => i.value > 0)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (incomeItems.isNotEmpty) ...[
            _DonutSection(
              label: 'INCOME',
              labelColor: AppColors.success,
              items: incomeItems,
              palette: _incomePalette,
              centerLabel: 'received',
            ),
            const SizedBox(height: 24),
          ],
          if (expenseItems.isNotEmpty)
            _DonutSection(
              label: 'EXPENSES',
              labelColor: AppColors.error,
              items: expenseItems,
              palette: _expensePalette,
              centerLabel: 'spent',
            ),
          if (incomeItems.isEmpty && expenseItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No transactions yet this month.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DonutSection extends StatelessWidget {
  final String label;
  final Color labelColor;
  final List<_ChartItem> items;
  final List<Color> palette;
  final String centerLabel;

  const _DonutSection({
    required this.label,
    required this.labelColor,
    required this.items,
    required this.palette,
    required this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (s, i) => s + i.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _DonutChartPainter(
              items: items,
              palette: palette,
              totalValue: total,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmt(total),
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    centerLabel,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((e) {
          final color = palette[e.key % palette.length];
          final pct = total > 0
              ? (e.value.value / total * 100).toStringAsFixed(1)
              : '0.0';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.value.name,
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ),
                Text('$pct%',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Text(_fmt(e.value.value),
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<_ChartItem> items;
  final List<Color> palette;
  final double totalValue;

  _DonutChartPainter({
    required this.items,
    required this.palette,
    required this.totalValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.height / 2) - 8;
    final strokeWidth = radius * 0.38;
    final rect = Rect.fromCircle(
        center: Offset(cx, cy), radius: radius - strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (totalValue <= 0) {
      paint.color = AppColors.textTertiary.withValues(alpha: 0.15);
      canvas.drawCircle(Offset(cx, cy), radius - strokeWidth / 2, paint);
      return;
    }

    double startAngle = -1.5708; // -π/2 (top)
    for (var i = 0; i < items.length; i++) {
      final val = items[i].value;
      if (val <= 0) continue;
      final sweep = (val / totalValue) * 6.2832;
      paint.color = palette[i % palette.length];
      canvas.drawArc(rect, startAngle, sweep - 0.03, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) =>
      old.totalValue != totalValue || old.items != items;
}

// ─── All Transactions Tab ─────────────────────────────────────────────────────

class _AllTransactionsTab extends StatelessWidget {
  final List<Transaction> transactions;

  const _AllTransactionsTab({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));

    if (sorted.isEmpty) {
      return Center(
        child: Text(
          'No transactions this month.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (_, i) => _TransactionMiniRow(transaction: sorted[i]),
    );
  }
}

// ─── Group Transactions Tab ───────────────────────────────────────────────────

class _GroupTransactionsTab extends StatelessWidget {
  final List<Transaction> transactions;

  const _GroupTransactionsTab({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions for this group.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (_, i) => _TransactionMiniRow(transaction: transactions[i]),
    );
  }
}

// ─── Create Budget Group Sheet ────────────────────────────────────────────────

class _CreateGroupSheet extends StatefulWidget {
  final String monthKey;
  final String monthLabel;
  final BudgetController budgetController;
  final SupabaseService supabaseService;

  const _CreateGroupSheet({
    required this.monthKey,
    required this.monthLabel,
    required this.budgetController,
    required this.supabaseService,
  });

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  late final TextEditingController _titleCtrl;
  BudgetType _budgetType = BudgetType.expense;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.monthLabel);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.budgetController.createBudget(
        Budget(
          month: widget.monthKey,
          title: _titleCtrl.text.trim().isEmpty
              ? widget.monthLabel
              : _titleCtrl.text.trim(),
          budgetType: _budgetType,
          periodType: BudgetPeriodType.monthly,
          status: BudgetStatus.active,
          userId: widget.supabaseService.userId,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('New Budget Group', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              widget.monthLabel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Group name
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g., Housing, Food & Dining',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),

            // Income / Expense toggle
            Center(
              child: SegmentedButton<BudgetType>(
                segments: const [
                  ButtonSegment(
                    value: BudgetType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward, size: 14),
                  ),
                  ButtonSegment(
                    value: BudgetType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward, size: 14),
                  ),
                ],
                selected: {_budgetType},
                onSelectionChanged: (s) =>
                    setState(() => _budgetType = s.first),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Budget Group Sheet ──────────────────────────────────────────────────

class _EditGroupSheet extends StatefulWidget {
  final Budget group;
  final BudgetController budgetController;

  const _EditGroupSheet({
    required this.group,
    required this.budgetController,
  });

  @override
  State<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<_EditGroupSheet> {
  late final TextEditingController _titleCtrl;
  late BudgetType _budgetType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.group.title ?? '');
    _budgetType = widget.group.budgetType;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.budgetController.updateBudget(
        widget.group.copyWith(title: title, budgetType: _budgetType),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit Budget Group', style: AppTextStyles.h4),
            const SizedBox(height: 20),

            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),

            Center(
              child: SegmentedButton<BudgetType>(
                segments: const [
                  ButtonSegment(
                    value: BudgetType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward, size: 14),
                  ),
                  ButtonSegment(
                    value: BudgetType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward, size: 14),
                  ),
                ],
                selected: {_budgetType},
                onSelectionChanged: (s) =>
                    setState(() => _budgetType = s.first),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Category Sheet ──────────────────────────────────────────────────────

class _EditCategorySheet extends StatefulWidget {
  final Budget group;
  final BudgetCategory category;
  final FinanceCategoryController categoryController;
  final BudgetController budgetController;

  const _EditCategorySheet({
    required this.group,
    required this.category,
    required this.categoryController,
    required this.budgetController,
  });

  @override
  State<_EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<_EditCategorySheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.category.financeCategory?.name ?? '',
    );
    _amountCtrl = TextEditingController(
      text: widget.category.targetAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a category name')));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _saving = true);
    try {
      // Update FinanceCategory name if changed
      final fc = widget.category.financeCategory;
      if (fc != null && fc.name != name) {
        await widget.categoryController.updateCategory(
          fc.copyWith(name: name),
        );
      }
      // Update planned amount if changed
      if (amount != widget.category.targetAmount) {
        await widget.budgetController.updateCategory(
          widget.group.id!,
          widget.category.copyWith(targetAmount: amount),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit Category', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              widget.group.title ?? '',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Planned Amount',
                border: OutlineInputBorder(),
                prefixText: '₱ ',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Debt / Receivable Section ────────────────────────────────────────────────

class _DebtSection extends StatelessWidget {
  final String title;
  final List<Debt> debts;
  final bool isReceivable;
  final VoidCallback onAdd;

  const _DebtSection({
    required this.title,
    required this.debts,
    required this.isReceivable,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          child: Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  isReceivable ? 'Outstanding' : 'Balance',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: Text(
                  isReceivable ? 'Expected' : 'Planned',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: Text(
                  isReceivable ? 'Received' : 'Paid',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...debts.map(
          (d) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.personName,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (d.isOverdue)
                        Text(
                          'Overdue',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    _fmt(d.remainingAmount),
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    _fmt(d.monthlyPaymentAmount),
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    _fmt(d.paidAmount),
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Ghost add button
        _GhostAddRow(
          label: isReceivable ? 'Add Receivable' : 'Add Debt',
          onTap: onAdd,
        ),
      ],
    );
  }
}

// ─── Add Category Sheet ───────────────────────────────────────────────────────

class _AddCategorySheet extends StatefulWidget {
  final Budget group;
  final FinanceCategoryController categoryController;
  final SupabaseService supabaseService;
  final Future<void> Function(BudgetCategory) onSave;

  const _AddCategorySheet({
    required this.group,
    required this.categoryController,
    required this.supabaseService,
    required this.onSave,
  });

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add Category', style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              widget.group.title ?? '',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Groceries, Netflix, Salary',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Planned Amount',
                border: OutlineInputBorder(),
                prefixText: '₱ ',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a category name')));
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _saving = true);
    try {
      // Derive CategoryType from the group's BudgetType
      final catType = widget.group.budgetType == BudgetType.income
          ? CategoryType.income
          : CategoryType.expense;

      // Check if a matching FinanceCategory already exists — reuse it, don't duplicate
      final currentState = widget.categoryController.state;
      final currentCats = currentState is AsyncData<List<FinanceCategory>>
          ? currentState.data
          : <FinanceCategory>[];
      final existing = currentCats.where(
        (c) => c.name.toLowerCase() == name.toLowerCase() && c.type == catType,
      ).firstOrNull;

      FinanceCategory created;
      if (existing != null) {
        created = existing;
      } else {
        // Create a new FinanceCategory in the DB
        await widget.categoryController.createCategory(
          FinanceCategory(
            name: name,
            type: catType,
            userId: widget.supabaseService.userId,
          ),
        );
        // Find the freshly created category in the updated cache
        final updatedState = widget.categoryController.state;
        final updatedCats = updatedState is AsyncData<List<FinanceCategory>>
            ? updatedState.data
            : <FinanceCategory>[];
        created = updatedCats.firstWhere(
          (c) =>
              c.name.toLowerCase() == name.toLowerCase() && c.type == catType,
          orElse: () => FinanceCategory(name: name, type: catType),
        );
      }

      await widget.onSave(
        BudgetCategory(
          budgetId: widget.group.id!,
          financeCategoryId: created.id ?? '',
          targetAmount: amount,
          financeCategory: created,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }
}

// ─── Edit Amount Dialog ───────────────────────────────────────────────────────

class _EditAmountDialog extends StatefulWidget {
  final BudgetCategory category;
  final Future<void> Function(double) onSave;

  const _EditAmountDialog({required this.category, required this.onSave});

  @override
  State<_EditAmountDialog> createState() => _EditAmountDialogState();
}

class _EditAmountDialogState extends State<_EditAmountDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.category.targetAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit ${widget.category.financeCategory?.name ?? 'Category'}',
      ),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Planned Amount',
          border: OutlineInputBorder(),
          prefixText: '₱ ',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_controller.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(amount);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }
}

// ─── Upcoming Commitments Sheet ───────────────────────────────────────────────

class _CommitmentsSheet extends StatelessWidget {
  final List<PlannedPayment> payments;
  final AccountController accountController;
  final FinanceCategoryController categoryController;
  final SupabaseService supabaseService;
  final PlannedPaymentController plannedPaymentController;

  const _CommitmentsSheet({
    required this.payments,
    required this.accountController,
    required this.categoryController,
    required this.supabaseService,
    required this.plannedPaymentController,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text('Upcoming Commitments', style: AppTextStyles.h4),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: payments.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, i) => _CommitmentTile(
                payment: payments[i],
                accountController: accountController,
                categoryController: categoryController,
                supabaseService: supabaseService,
                plannedPaymentController: plannedPaymentController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitmentTile extends StatelessWidget {
  final PlannedPayment payment;
  final AccountController accountController;
  final FinanceCategoryController categoryController;
  final SupabaseService supabaseService;
  final PlannedPaymentController plannedPaymentController;

  const _CommitmentTile({
    required this.payment,
    required this.accountController,
    required this.categoryController,
    required this.supabaseService,
    required this.plannedPaymentController,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d').format(payment.nextPaymentDate);

    return ListTile(
      title: Text(
        payment.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${payment.payee} · $dateStr · ${payment.frequency.displayName}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _fmt(payment.amount),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => _showRecordDialog(context, payment),
            child: const Text('Record'),
          ),
          TextButton(
            onPressed: () => _skipPayment(context, payment),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecordDialog(
    BuildContext context,
    PlannedPayment payment,
  ) async {
    final amountCtrl = TextEditingController(
      text: payment.amount.toStringAsFixed(2),
    );
    String? selectedAccountId;
    String? selectedCategoryId;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Record: ${payment.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              AsyncStreamBuilder<List<Account>>(
                state: accountController,
                builder: (_, accounts) => DropdownButtonFormField<String>(
                  initialValue: selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    border: OutlineInputBorder(),
                  ),
                  items: accounts
                      .map(
                        (a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                      )
                      .toList(),
                  onChanged: (v) => selectedAccountId = v,
                ),
                loadingBuilder: (_) => const CircularProgressIndicator(),
                errorBuilder: (_, m) => Text(m),
              ),
              const SizedBox(height: 12),
              AsyncStreamBuilder<List<FinanceCategory>>(
                state: categoryController,
                builder: (_, cats) {
                  final exp = cats
                      .where((c) => c.type == CategoryType.expense)
                      .toList();
                  return DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: exp
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedCategoryId = v,
                  );
                },
                loadingBuilder: (_) => const CircularProgressIndicator(),
                errorBuilder: (_, m) => Text(m),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount')),
                );
                return;
              }
              if (selectedAccountId == null) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('Select an account')),
                );
                return;
              }
              if (selectedCategoryId == null) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('Select a category')),
                );
                return;
              }
              try {
                await supabaseService.client.rpc(
                  'create_planned_payment_transaction',
                  params: {
                    'p_user_id': supabaseService.userId,
                    'p_account_id': selectedAccountId,
                    'p_finance_category_id': selectedCategoryId,
                    'p_amount': amount,
                    'p_type': 'expense',
                    'p_description': 'Paid: ${payment.name}',
                    'p_date': DateTime.now().toIso8601String(),
                    'p_notes': null,
                    'p_planned_payment_id': payment.id,
                    'p_fee': 0.0,
                    'p_fee_description': null,
                  },
                );
                plannedPaymentController.loadPlannedPayments();
                if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
              } catch (e) {
                if (dialogCtx.mounted) {
                  ScaffoldMessenger.of(
                    dialogCtx,
                  ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment recorded')));
    }
    amountCtrl.dispose();
  }

  Future<void> _skipPayment(
    BuildContext context,
    PlannedPayment payment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip Payment'),
        content: Text(
          'Skip "${payment.name}"? Next payment date will advance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
    if (confirmed == true && payment.id != null) {
      await plannedPaymentController.recordPayment(payment.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment skipped')));
      }
    }
  }
}
