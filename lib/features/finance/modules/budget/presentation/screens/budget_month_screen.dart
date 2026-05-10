import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/scoped_screen.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/utils/currency_formatter.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/payment_enums.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/presentation/state/account_controller.dart';
import 'package:keep_track/features/finance/presentation/state/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/planned_payment_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/features/finance/presentation/screens/transactions/create_transaction_screen.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

// Simple data class for a named group of categories
class _CategoryGroup {
  final String name;
  final List<FinanceCategory> categories;
  const _CategoryGroup(this.name, this.categories);
}

/// Builds grouped category list: one group per active budget in [monthKey],
/// then an "Other" group for any categories not assigned to a budget.
List<_CategoryGroup> _buildGroupedCategories({
  required List<FinanceCategory> allCategories,
  required List<Budget> allBudgets,
  required CategoryType targetType,
  required String monthKey,
}) {
  final targetBudgetType = targetType == CategoryType.income
      ? BudgetType.income
      : BudgetType.expense;

  final monthBudgets = allBudgets
      .where(
        (b) =>
            b.month == monthKey &&
            b.periodType == BudgetPeriodType.monthly &&
            b.status == BudgetStatus.active &&
            b.budgetType == targetBudgetType,
      )
      .toList();

  final typedCats = allCategories.where((c) => c.type == targetType).toList();
  final seenIds = <String>{};
  final groups = <_CategoryGroup>[];

  for (final budget in monthBudgets) {
    final groupCats = <FinanceCategory>[];
    for (final bc in budget.categories) {
      final cat = typedCats.firstWhere(
        (c) => c.id == bc.financeCategoryId,
        orElse: () => FinanceCategory(name: '', type: targetType),
      );
      if (cat.id != null && !seenIds.contains(cat.id)) {
        groupCats.add(cat);
        seenIds.add(cat.id!);
      }
    }
    if (groupCats.isNotEmpty) {
      groups.add(_CategoryGroup(budget.title ?? 'Untitled', groupCats));
    }
  }

  // Only show unbudgeted categories in "Other" when a plan exists for this
  // month — avoids dumping all finance_categories as "Other" when there is
  // no month plan yet.
  if (monthBudgets.isNotEmpty) {
    final others = typedCats
        .where((c) => c.id != null && !seenIds.contains(c.id))
        .toList();
    if (others.isNotEmpty) {
      groups.add(_CategoryGroup('Other', others));
    }
  }

  return groups;
}

/// Shows a scrollable grouped category picker dialog.
/// Returns the selected [FinanceCategory] or null (cancelled).
Future<FinanceCategory?> _showGroupedCategoryDialog(
  BuildContext context, {
  required List<_CategoryGroup> groups,
  required String? selectedId,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  return showDialog<FinanceCategory>(
    context: context,
    builder: (dialogCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
          maxWidth: 420,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Select Category', style: theme.textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in groups) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                        child: Text(
                          group.name.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      for (final cat in group.categories)
                        ListTile(
                          leading: Icon(
                            cat.type.icon,
                            size: 20,
                            color: cat.type.color,
                          ),
                          title: Text(cat.name),
                          selected: selectedId == cat.id,
                          selectedTileColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          trailing: selectedId == cat.id
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(dialogCtx).pop(cat),
                        ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
//endregion

class BudgetMonthScreen extends ScopedScreen {
  const BudgetMonthScreen({super.key});

  @override
  State<BudgetMonthScreen> createState() => _BudgetMonthScreenState();
}

class _BudgetMonthScreenState extends ScopedScreenState<BudgetMonthScreen> {
  late final BudgetController _budgetController;
  late final MonthPlanController _monthPlanController;
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
  Debt? _selectedDebt;

  @override
  void initState() {
    super.initState();
    _budgetController = locator.get<BudgetController>();
    _monthPlanController = locator.get<MonthPlanController>();
    _debtController = locator.get<DebtController>();
    _plannedPaymentController = locator.get<PlannedPaymentController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _accountController = locator.get<AccountController>();
    _transactionController = locator.get<TransactionController>();
    _supabaseService = locator.get<SupabaseService>();
    _loadMonthTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncStreamBuilder<List<MonthPlan>>(
        state: _monthPlanController,
        builder: (context, allMonthPlans) {
          return AsyncStreamBuilder<List<Budget>>(
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
                            allMonthPlans: allMonthPlans,
                            allBudgets: allBudgets,
                            allTransactions: allTransactions,
                            allDebts: allDebts,
                            allPayments: allPayments,
                          );
                        },
                        loadingBuilder: (_) => _buildBody(
                          allMonthPlans: allMonthPlans,
                          allBudgets: allBudgets,
                          allTransactions: allTransactions,
                          allDebts: const [],
                          allPayments: const [],
                        ),
                        errorBuilder: (_, __) => _buildBody(
                          allMonthPlans: allMonthPlans,
                          allBudgets: allBudgets,
                          allTransactions: allTransactions,
                          allDebts: const [],
                          allPayments: const [],
                        ),
                      );
                    },
                    loadingBuilder: (_) => _buildBody(
                      allMonthPlans: allMonthPlans,
                      allBudgets: allBudgets,
                      allTransactions: allTransactions,
                      allDebts: const [],
                      allPayments: const [],
                    ),
                    errorBuilder: (_, __) => _buildBody(
                      allMonthPlans: allMonthPlans,
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
            loadingBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, msg) => Center(child: Text('Error: $msg')),
          );
        },
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, msg) => Center(child: Text('Error: $msg')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => Dialog(
              insetPadding: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                  maxHeight: 700,
                ),
                child: const CreateTransactionScreen(),
              ),
            ),
          );
          if (mounted) _loadMonthTransactions();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Transaction'),
      ),
    );
  }

  Widget _buildBody({
    required List<MonthPlan> allMonthPlans,
    required List<Budget> allBudgets,
    required List<Transaction> allTransactions,
    required List<Debt> allDebts,
    required List<PlannedPayment> allPayments,
  }) {
    // Filter transactions strictly to the selected month
    final monthStart = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final monthEnd = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    final monthTransactions = allTransactions
        .where((t) => !t.date.isBefore(monthStart) && t.date.isBefore(monthEnd))
        .toList();

    // Build spent-per-financeCategoryId map from actual transactions
    final Map<String, double> spentByCategory = {};
    for (final t in monthTransactions) {
      if (t.financeCategoryId != null) {
        spentByCategory[t.financeCategoryId!] =
            (spentByCategory[t.financeCategoryId!] ?? 0.0) + t.amount;
      }
    }

    // month_plan is the authority — no plan means no budgets to show
    final monthPlan = allMonthPlans.cast<MonthPlan?>().firstWhere(
      (p) => p?.month == _monthKey,
      orElse: () => null,
    );
    final hasMonthPlan = monthPlan != null;

    // Only show budgets explicitly listed in the month_plan's budgetIds
    final allowedIds = monthPlan?.budgetIds.toSet() ?? {};
    final monthBudgets = hasMonthPlan
        ? (allBudgets
              .where((b) => b.id != null && allowedIds.contains(b.id))
              .toList()
            ..sort((a, b) {
              if (a.budgetType == b.budgetType) return 0;
              return a.budgetType == BudgetType.income ? -1 : 1;
            }))
        : <Budget>[];

    // Show a debt/receivable in this month if:
    // - It started on or before the end of this month (debt existed by this month)
    // - AND it was not settled before this month started
    //   (active = always show; settled = show only up through the month it was settled)
    bool debtVisibleThisMonth(Debt d) {
      if (d.startDate.isAfter(monthEnd))
        return false; // started after this month
      if (d.status == DebtStatus.active) return true;
      if (d.settledAt == null) return true; // treated as active
      return !d.settledAt!.isBefore(monthStart); // settled this month or later
    }

    final debts = allDebts
        .where((d) => d.type == DebtType.borrowing && debtVisibleThisMonth(d))
        .toList();
    final receivables = allDebts
        .where((d) => d.type == DebtType.lending && debtVisibleThisMonth(d))
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
        (b) => b.id == _selectedCategoryGroup!.id,
      );
      syncedCategoryGroup = idx >= 0 ? monthBudgets[idx] : null;
    }
    BudgetCategory? syncedCategory;
    if (_selectedCategory != null && syncedCategoryGroup != null) {
      final idx = syncedCategoryGroup.categories.indexWhere(
        (c) => c.id == _selectedCategory!.id,
      );
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
          selectedDebt: _selectedDebt,
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
          onDebtClose: () => setState(() => _selectedDebt = null),
          onDebtPay: _showDebtPaymentDialog,
          onEditCategory: syncedCategory != null && syncedCategoryGroup != null
              ? () => _showEditCategorySheet(
                  syncedCategoryGroup!,
                  syncedCategory!,
                )
              : null,
          onEditDebt: _selectedDebt != null
              ? () => _showEditDebtSheet(_selectedDebt!)
              : null,
          onAddCategory: _showAddCategorySheet,
          onCategoryDetailTap: (cat) {
            if (syncedSelected != null) {
              _showCategoryDetail(syncedSelected, cat, monthTransactions);
            }
          },
          onUpdateAmount: _updateCategoryAmount,
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
                  spentByCategory: spentByCategory,
                  activePayments: activePayments,
                  activeDebts: debts,
                  activeReceivables: receivables,
                  onCommitmentsTab: () => _showCommitmentsSheet(activePayments),
                ),
              ),

              if (!hasMonthPlan)
                SliverToBoxAdapter(
                  child: _EmptyBudgetState(
                    monthLabel: _monthLabel,
                    onStart: () => _showStartPlanningSheet(allBudgets),
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
                      spentByCategory: spentByCategory,
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
                  selectedDebt: _selectedDebt,
                  onAdd: () => _showAddDebtSheet(isReceivable: false),
                  onPay: _showDebtPaymentDialog,
                  onEdit: _showEditDebtSheet,
                  onUpdateMonthlyPayment: _updateDebtMonthlyPayment,
                  onSelect: (d) {
                    if (isWide) {
                      setState(
                        () => _selectedDebt = _selectedDebt?.id == d.id
                            ? null
                            : d,
                      );
                    } else {
                      _showDebtDetailSheet(d, monthTransactions);
                    }
                  },
                ),
              ),

              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverToBoxAdapter(
                child: _DebtSection(
                  title: 'RECEIVABLES',
                  debts: receivables,
                  isReceivable: true,
                  selectedDebt: _selectedDebt,
                  onAdd: () => _showAddDebtSheet(isReceivable: true),
                  onPay: _showDebtPaymentDialog,
                  onEdit: _showEditDebtSheet,
                  onUpdateMonthlyPayment: _updateDebtMonthlyPayment,
                  onSelect: (d) {
                    if (isWide) {
                      setState(
                        () => _selectedDebt = _selectedDebt?.id == d.id
                            ? null
                            : d,
                      );
                    } else {
                      _showDebtDetailSheet(d, monthTransactions);
                    }
                  },
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
                onDelete: () => _confirmDeletePlan(monthBudgets),
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

// ---- Helpers ----------
extension BudgetMonthHelpers on _BudgetMonthScreenState {
  // ── Month helpers ─────────────────────────────────────────────────────────

  String get _monthKey =>
      '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';

  String get _monthLabel => DateFormat('MMMM yyyy').format(_currentMonth);

  DateTime get _prevMonthDate =>
      DateTime(_currentMonth.year, _currentMonth.month - 1);

  String get _prevMonthKey =>
      '${_prevMonthDate.year}-${_prevMonthDate.month.toString().padLeft(2, '0')}';

  String get _prevMonthLabel => DateFormat('MMMM yyyy').format(_prevMonthDate);

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedGroup = null;
      _selectedCategory = null;
      _selectedCategoryGroup = null;
      _selectedDebt = null;
    });
    _loadMonthTransactions();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedGroup = null;
      _selectedCategory = null;
      _selectedCategoryGroup = null;
      _selectedDebt = null;
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
}

// ---- Dialogs ----------
extension BudgetMonthDialogSheets on _BudgetMonthScreenState {
  void _showAddCategorySheet(Budget group) {
    if (group.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget group is still saving. Please wait a moment.'),
        ),
      );
      return;
    }
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
      builder: (sheetCtx) => _EditCategorySheet(
        group: group,
        category: cat,
        categoryController: _categoryController,
        budgetController: _budgetController,
        onDelete: () async {
          Navigator.pop(sheetCtx);
          await _confirmDeleteCategory(group, cat);
        },
      ),
    );
  }

  void _showEditGroupSheet(Budget group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => _EditGroupSheet(
        group: group,
        budgetController: _budgetController,
        onDelete: () async {
          Navigator.pop(sheetCtx);
          await _confirmDeleteGroup(group);
        },
      ),
    );
  }

  Future<void> _confirmDeleteGroup(Budget group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Budget Group'),
        content: Text(
          'Delete "${group.title ?? 'this group'}" and all its categories?',
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
    if (ok == true && group.id != null) {
      await _budgetController.deleteBudget(group.id!);
    }
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

  Future<void> _updateDebtMonthlyPayment(Debt debt, double amount) async {
    await _debtController.updateDebt(
      debt.copyWith(monthlyPaymentAmount: amount),
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
        monthPlanController: _monthPlanController,
        supabaseService: _supabaseService,
      ),
    );
  }

  /// Shown when no budget exists for the month — creates the MonthPlan first,
  /// then offers "Copy from previous month" or "Start fresh".
  void _showStartPlanningSheet(List<Budget> allBudgets) {
    final prevBudgets = allBudgets
        .where(
          (b) =>
              b.month == _prevMonthKey &&
              b.periodType == BudgetPeriodType.monthly &&
              b.status == BudgetStatus.active,
        )
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StartPlanningSheet(
        monthKey: _monthKey,
        monthLabel: _monthLabel,
        prevMonthKey: _prevMonthKey,
        prevMonthLabel: _prevMonthLabel,
        hasPrevBudgets: prevBudgets.isNotEmpty,
        monthPlanController: _monthPlanController,
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

  Future<void> _showDebtPaymentDialog(Debt debt) async {
    final isReceivable = debt.type == DebtType.lending;
    final amountCtrl = TextEditingController(
      text: debt.monthlyPaymentAmount > 0
          ? debt.monthlyPaymentAmount.toStringAsFixed(2)
          : '',
    );
    final feeCtrl = TextEditingController();
    String? selectedAccountId;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(
            isReceivable
                ? 'Collect from ${debt.personName}'
                : 'Pay ${debt.personName}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Remaining balance info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining balance',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        formatCurrency(debt.remainingAmount),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    prefixText: '₱',
                    border: const OutlineInputBorder(),
                    helperText: debt.monthlyPaymentAmount > 0
                        ? 'Monthly: ${formatCurrency(debt.monthlyPaymentAmount)}'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Fee (optional)',
                    prefixText: '₱',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                AsyncStreamBuilder<List<Account>>(
                  state: _accountController,
                  builder: (_, accounts) => DropdownButtonFormField<String>(
                    initialValue: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                    ),
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedAccountId = v,
                  ),
                  loadingBuilder: (_) => const LinearProgressIndicator(),
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
                if (amount > debt.remainingAmount) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Amount exceeds remaining balance of ${formatCurrency(debt.remainingAmount)}',
                      ),
                    ),
                  );
                  return;
                }
                if (selectedAccountId == null) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(content: Text('Select an account')),
                  );
                  return;
                }
                try {
                  final fee = double.tryParse(feeCtrl.text) ?? 0.0;
                  await ApiClient.instance.post(
                    '/debts/${debt.id}/pay',
                    data: {
                      'accountId': selectedAccountId,
                      'amount': amount,
                      if (fee > 0) 'fee': fee,
                    },
                  );
                  // Adjust account balance (backend creates transaction directly,
                  // bypassing the frontend repo layer that normally handles this)
                  final balanceDelta = isReceivable
                      ? amount -
                            fee // income: receive amount minus fee
                      : -(amount + fee); // expense: pay amount plus fee
                  await _accountController.adjustBalance(
                    selectedAccountId!,
                    balanceDelta,
                  );
                  // Refresh debts, transactions, and budget spent amounts
                  _debtController.loadDebts();
                  _loadMonthTransactions();
                  _budgetController.refreshBudgetsWithSpentAmounts();
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(
                      dialogCtx,
                    ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              child: Text(isReceivable ? 'Collect' : 'Pay'),
            ),
          ],
        ),
      ),
    );

    amountCtrl.dispose();
    feeCtrl.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isReceivable ? 'Collection recorded' : 'Payment recorded',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showDebtDetailSheet(Debt debt, List<Transaction> allTransactions) {
    final debtTxns = allTransactions.where((t) => t.debtId == debt.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _DebtDetailContent(
          debt: debt,
          transactions: debtTxns,
          scrollController: controller,
          onPay: () {
            Navigator.pop(context);
            _showDebtPaymentDialog(debt);
          },
        ),
      ),
    );
  }

  void _showAddDebtSheet({required bool isReceivable}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddDebtSheet(
        isReceivable: isReceivable,
        accountController: _accountController,
        categoryController: _categoryController,
        supabaseService: _supabaseService,
        onSave: (debt, categoryId) async {
          if (debt.accountId != null && categoryId != null) {
            await _debtController.createDebtWithCategory(debt, categoryId);
          } else {
            await _debtController.createDebtOnly(debt);
          }
        },
      ),
    );
  }

  void _showEditDebtSheet(Debt debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditDebtSheet(
        debt: debt,
        onSave: (updated) async {
          await _debtController.updateDebt(updated);
        },
      ),
    );
  }

  Future<void> _confirmDeletePlan(List<Budget> monthBudgets) async {
    // Look up the MonthPlan for the current month
    final planState = _monthPlanController.state;
    final plans = planState is AsyncData<List<MonthPlan>>
        ? planState.data
        : <MonthPlan>[];
    final plan = plans.cast<MonthPlan?>().firstWhere(
      (p) => p?.month == _monthKey,
      orElse: () => null,
    );

    // Nothing to delete if no plan and no budgets
    if (plan == null && monthBudgets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No plan found for this month.')),
      );
      return;
    }

    bool deleteAll = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text('Delete plan for $_monthLabel?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The month plan record will be removed.'),
              if (monthBudgets.isNotEmpty) ...[
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: deleteAll,
                  onChanged: (v) =>
                      setDialogState(() => deleteAll = v ?? false),
                  title: const Text(
                    'Also delete all budget groups and categories',
                  ),
                  subtitle: Text(
                    '${monthBudgets.length} group${monthBudgets.length == 1 ? '' : 's'} will be permanently removed',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading dialog while deleting
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Deleting…'),
            ],
          ),
        ),
      ),
    );

    try {
      if (deleteAll && plan != null && plan.id != null) {
        await _monthPlanController.deleteMonthPlanWithBudgets(
          plan.id!,
          _monthKey,
        );
        await _budgetController.refreshBudgetsWithSpentAmounts();
      } else if (deleteAll && plan == null) {
        // No plan row, just delete the budgets directly
        for (final b in monthBudgets) {
          if (b.id != null) await _budgetController.deleteBudget(b.id!);
        }
      } else if (plan != null && plan.id != null) {
        await _monthPlanController.deleteMonthPlan(plan.id!);
      }

      if (mounted) {
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteAll
                  ? 'Plan and all budget groups deleted.'
                  : 'Plan deleted. Budget groups kept.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
}

//region Category Detail Sheet
// ─── Category Detail Sheet (mobile bottom sheet wrapper) ─────────────────────

//endregion

//region Add Group Ghost Button
// ─── Add Group Ghost Button ───────────────────────────────────────────────────

//region Create Budget Group Sheet
// ─── Create Budget Group Sheet ────────────────────────────────────────────────
//endregion

//region Edit Budget Group Sheet
// ─── Edit Budget Group Sheet ──────────────────────────────────────────────────

class _EditGroupSheet extends StatefulWidget {
  final Budget group;
  final BudgetController budgetController;
  final VoidCallback? onDelete;

  const _EditGroupSheet({
    required this.group,
    required this.budgetController,
    this.onDelete,
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
            if (widget.onDelete != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _saving ? null : widget.onDelete,
                  child: const Text(
                    'Delete Group',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

//endregion

//region Edit Category Sheet
// ─── Edit Category Sheet ──────────────────────────────────────────────────────

class _EditCategorySheet extends StatefulWidget {
  final Budget group;
  final BudgetCategory category;
  final FinanceCategoryController categoryController;
  final BudgetController budgetController;
  final VoidCallback? onDelete;

  const _EditCategorySheet({
    required this.group,
    required this.category,
    required this.categoryController,
    required this.budgetController,
    this.onDelete,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a category name')));
      return;
    }
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _saving = true);
    try {
      // Update FinanceCategory name if changed
      final fc = widget.category.financeCategory;
      if (fc != null && fc.name != name) {
        await widget.categoryController.updateCategory(fc.copyWith(name: name));
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
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
            if (widget.onDelete != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _saving ? null : widget.onDelete,
                  child: const Text(
                    'Delete Category',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
//endregion

//region Debt / Receivable Section
// ─── Debt / Receivable Section ────────────────────────────────────────────────

class _DebtSection extends StatelessWidget {
  final String title;
  final List<Debt> debts;
  final bool isReceivable;
  final Debt? selectedDebt;
  final VoidCallback onAdd;
  final void Function(Debt) onPay;
  final void Function(Debt) onEdit;
  final void Function(Debt) onSelect;
  final Future<void> Function(Debt, double) onUpdateMonthlyPayment;

  const _DebtSection({
    required this.title,
    required this.debts,
    required this.isReceivable,
    required this.onAdd,
    required this.onPay,
    required this.onEdit,
    required this.onSelect,
    required this.onUpdateMonthlyPayment,
    this.selectedDebt,
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
              const SizedBox(
                width: 78,
              ), // spacer for Edit + Pay/Collect button columns
            ],
          ),
        ),
        ...debts.map(
          (d) => _DebtRow(
            key: ValueKey(d.id),
            debt: d,
            isReceivable: isReceivable,
            isSelected: selectedDebt?.id == d.id,
            onSelect: () => onSelect(d),
            onPay: () => onPay(d),
            onEdit: () => onEdit(d),
            onUpdateMonthlyPayment: (amount) =>
                onUpdateMonthlyPayment(d, amount),
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
//endregion

//region Debt Row
// ─── Debt Row (with inline planned-amount editing) ────────────────────────────

class _DebtRow extends StatefulWidget {
  final Debt debt;
  final bool isReceivable;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final Future<void> Function(double) onUpdateMonthlyPayment;

  const _DebtRow({
    super.key,
    required this.debt,
    required this.isReceivable,
    required this.isSelected,
    required this.onSelect,
    required this.onPay,
    required this.onEdit,
    required this.onUpdateMonthlyPayment,
  });

  @override
  State<_DebtRow> createState() => _DebtRowState();
}

class _DebtRowState extends State<_DebtRow> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _amountCtrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.debt.monthlyPaymentAmount.toStringAsFixed(2),
    );
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_DebtRow old) {
    super.didUpdateWidget(old);
    if (!_editing &&
        old.debt.monthlyPaymentAmount != widget.debt.monthlyPaymentAmount) {
      _amountCtrl.text = widget.debt.monthlyPaymentAmount.toStringAsFixed(2);
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
    if (!_focusNode.hasFocus && _editing) _commitEdit();
  }

  void _startEdit() => setState(() {
    _editing = true;
    _amountCtrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _amountCtrl.text.length,
    );
  });

  Future<void> _commitEdit() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount < 0 || amount == widget.debt.monthlyPaymentAmount) {
      _amountCtrl.text = widget.debt.monthlyPaymentAmount.toStringAsFixed(2);
      if (mounted) setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onUpdateMonthlyPayment(amount);
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
    final theme = Theme.of(context);
    final d = widget.debt;

    return Material(
      color: widget.isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.07)
          : Colors.transparent,
      child: InkWell(
        onTap: widget.onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // Name + overdue
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.personName,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: widget.isSelected
                            ? theme.colorScheme.primary
                            : AppColors.textPrimary,
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
              // Balance
              SizedBox(
                width: 70,
                child: Text(
                  formatCurrency(d.remainingAmount),
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Planned — tap to edit (absorb tap so row select doesn't fire)
              GestureDetector(
                onTap: _editing ? null : _startEdit,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 70,
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
                              borderSide: const BorderSide(
                                color: AppColors.accent,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: AppColors.accent,
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
                          formatCurrency(d.monthlyPaymentAmount),
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
              const SizedBox(width: 6),
              // Paid
              SizedBox(
                width: 70,
                child: Text(
                  formatCurrency(d.paidAmount),
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),

              const SizedBox(width: 4),
              // Pay / Collect button
              if (d.status == DebtStatus.active)
                SizedBox(
                  height: 28,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: widget.onPay,
                    child: Text(
                      widget.isReceivable ? 'Collect' : 'Pay',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isReceivable
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 46),
            ],
          ),
        ),
      ),
    );
  }
}
//endregion

//region Add Category Sheet
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
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a category name')));
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final budgetId = widget.group.id;
    if (budgetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget group has no ID — please try again.'),
        ),
      );
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
      final existing = currentCats
          .where(
            (c) =>
                c.name.toLowerCase() == name.toLowerCase() && c.type == catType,
          )
          .firstOrNull;

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
          budgetId: budgetId,
          financeCategoryId: created.id ?? '',
          targetAmount: amount,
          financeCategory: created,
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
}
//endregion

//region Edit Amount Dialog
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
//endregion

//region Upcoming Commitments Sheet
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
            formatCurrency(payment.amount),
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
              try {
                await ApiClient.instance.post(
                  '/planned-payments/${payment.id}/pay',
                  data: {
                    'paidDate': DateTime.now().toIso8601String(),
                    'createTransaction': true,
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
//endregion

//region AddDebt /Receivable Sheet
// ─── Add Debt / Receivable Sheet ──────────────────────────────────────────────

class _AddDebtSheet extends StatefulWidget {
  final bool isReceivable;
  final AccountController accountController;
  final FinanceCategoryController categoryController;
  final SupabaseService supabaseService;
  final Future<void> Function(Debt debt, String? categoryId) onSave;

  const _AddDebtSheet({
    required this.isReceivable,
    required this.accountController,
    required this.categoryController,
    required this.supabaseService,
    required this.onSave,
  });

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();

  late DebtType _type;
  String? _accountId;
  String? _categoryId;
  FinanceCategory? _selectedCategory;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.isReceivable ? DebtType.lending : DebtType.borrowing;
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _personCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a person name')));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    // If one of account/category is filled, require both (they're needed together for the initial transaction)
    if ((_accountId != null) != (_categoryId != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select both account and category to record the initial transaction, or leave both empty to skip it.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final debt = Debt(
        type: _type,
        personName: name,
        description: _descCtrl.text.trim(),
        originalAmount: amount,
        remainingAmount: amount,
        startDate: DateTime.now(),
        dueDate: _dueDate,
        userId: widget.supabaseService.userId,
        accountId: _accountId,
        monthlyPaymentAmount: double.tryParse(_monthlyCtrl.text) ?? 0,
      );
      await widget.onSave(debt, _categoryId);
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
    final isReceivable = _type == DebtType.lending;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
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

              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isReceivable ? 'Add Receivable' : 'Add Debt',
                      style: AppTextStyles.h4,
                    ),
                  ),
                  SegmentedButton<DebtType>(
                    segments: const [
                      ButtonSegment(
                        value: DebtType.borrowing,
                        label: Text('Debt'),
                      ),
                      ButtonSegment(
                        value: DebtType.lending,
                        label: Text('Receivable'),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() {
                      _type = s.first;
                      _categoryId = null; // reset category when type changes
                    }),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Person name
              TextField(
                controller: _personCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: isReceivable ? 'Borrower Name' : 'Lender Name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₱ ',
                ),
              ),
              const SizedBox(height: 12),

              // Initial transaction (optional)
              Text(
                'Initial Transaction (optional)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isReceivable
                    ? 'Records money leaving your wallet when you lend it.'
                    : 'Records money entering your wallet when you borrow.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              AsyncStreamBuilder<List<Account>>(
                state: widget.accountController,
                builder: (_, accounts) => DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  decoration: const InputDecoration(
                    labelText: 'Account (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('— Skip —'),
                    ),
                    ...accounts.map(
                      (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _accountId = v),
                ),
                loadingBuilder: (_) => const LinearProgressIndicator(),
                errorBuilder: (_, m) => Text(m),
              ),
              const SizedBox(height: 12),

              // Category picker (grouped by budget)
              AsyncStreamBuilder<List<FinanceCategory>>(
                state: widget.categoryController,
                builder: (_, allCats) {
                  final budgetCtrl = locator.get<BudgetController>();
                  final allBudgets = budgetCtrl.data ?? [];
                  final targetType = isReceivable
                      ? CategoryType.expense
                      : CategoryType.income;
                  final groups = _buildGroupedCategories(
                    allCategories: allCats,
                    allBudgets: allBudgets,
                    targetType: targetType,
                    monthKey:
                        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
                  );
                  return InkWell(
                    onTap: () async {
                      final picked = await _showGroupedCategoryDialog(
                        context,
                        groups: groups,
                        selectedId: _categoryId,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedCategory = picked;
                          _categoryId = picked.id;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Category (optional)',
                        border: const OutlineInputBorder(),
                        helperText: isReceivable
                            ? 'Expense category — money lent out'
                            : 'Income category — money borrowed',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_selectedCategory != null) ...[
                            Icon(
                              _selectedCategory!.type.icon,
                              size: 16,
                              color: _selectedCategory!.type.color,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _selectedCategory?.name ?? '— Skip —',
                              style: TextStyle(
                                color: _selectedCategory == null
                                    ? AppColors.textTertiary
                                    : null,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.unfold_more,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loadingBuilder: (_) => const LinearProgressIndicator(),
                errorBuilder: (_, m) => Text(m),
              ),
              const SizedBox(height: 12),

              // Description (optional)
              TextField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Monthly payment (optional)
              TextField(
                controller: _monthlyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monthly Payment (optional)',
                  border: OutlineInputBorder(),
                  prefixText: '₱ ',
                  helperText: 'Fixed amount expected each month',
                ),
              ),
              const SizedBox(height: 12),

              // Due date (optional)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date (optional)'),
                subtitle: Text(
                  _dueDate != null
                      ? DateFormat('MMM d, yyyy').format(_dueDate!)
                      : 'Not set',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _dueDate = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (d != null) setState(() => _dueDate = d);
                      },
                    ),
                  ],
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
                      : Text(isReceivable ? 'Add Receivable' : 'Add Debt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//endregion

//region Edit Debt / Receivable Sheet
// ─── Edit Debt / Receivable Sheet ─────────────────────────────────────────────

class _EditDebtSheet extends StatefulWidget {
  final Debt debt;
  final Future<void> Function(Debt updated) onSave;

  const _EditDebtSheet({required this.debt, required this.onSave});

  @override
  State<_EditDebtSheet> createState() => _EditDebtSheetState();
}

class _EditDebtSheetState extends State<_EditDebtSheet> {
  late final TextEditingController _personCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _monthlyCtrl;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _personCtrl = TextEditingController(text: d.personName);
    _descCtrl = TextEditingController(text: d.description);
    _monthlyCtrl = TextEditingController(
      text: d.monthlyPaymentAmount > 0
          ? d.monthlyPaymentAmount.toStringAsFixed(2)
          : '',
    );
    _dueDate = d.dueDate;
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _descCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _personCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a person name')));
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = widget.debt.copyWith(
        personName: name,
        description: _descCtrl.text.trim(),
        monthlyPaymentAmount:
            double.tryParse(_monthlyCtrl.text) ??
            widget.debt.monthlyPaymentAmount,
        dueDate: _dueDate,
      );
      await widget.onSave(updated);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.debt.type == DebtType.lending
                  ? 'Receivable updated!'
                  : 'Debt updated!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
    final isReceivable = widget.debt.type == DebtType.lending;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
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

              Text(
                isReceivable ? 'Edit Receivable' : 'Edit Debt',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 20),

              // Person name
              TextField(
                controller: _personCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: isReceivable ? 'Borrower Name' : 'Lender Name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Monthly payment
              TextField(
                controller: _monthlyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: isReceivable
                      ? 'Expected Monthly (optional)'
                      : 'Monthly Payment (optional)',
                  border: const OutlineInputBorder(),
                  prefixText: '₱ ',
                  helperText: 'Fixed amount expected each month',
                ),
              ),
              const SizedBox(height: 12),

              // Due date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date (optional)'),
                subtitle: Text(
                  _dueDate != null
                      ? DateFormat('MMM d, yyyy').format(_dueDate!)
                      : 'Not set',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _dueDate = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (d != null) setState(() => _dueDate = d);
                      },
                    ),
                  ],
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
                      : Text(isReceivable ? 'Save Receivable' : 'Save Debt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//endregion
