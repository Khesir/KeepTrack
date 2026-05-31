import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/domain/entities/transaction_plan.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_plan_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/transaction_detail_sheet.dart';

class TransactionPlannerScreen extends ScopedScreen {
  const TransactionPlannerScreen({super.key});

  @override
  State<TransactionPlannerScreen> createState() => _TransactionPlannerScreenState();
}

class _TransactionPlannerScreenState extends ScopedScreenState<TransactionPlannerScreen>
    with AppLayoutControlled {
  late final TransactionPlanController _planController;
  late final TransactionController _txController;
  late final FinanceCategoryController _catController;

  Map<String, FinanceCategory> _categoriesMap = {};
  Map<String, String> _profileNames = {};
  String _historyFilter = 'All';
  StreamSubscription? _catSub;

  static const _filters = ['All', 'Income', 'Expense', 'Savings', 'Goals'];

  late final BudgetProfileController _profileController;

  @override
  void registerServices() {
    _planController = locator.get<TransactionPlanController>();
    _txController = locator.get<TransactionController>();
    _catController = locator.get<FinanceCategoryController>();
    _profileController = locator.get<BudgetProfileController>();
  }

  @override
  void initState() {
    super.initState();
    _catSub = _catController.stream.listen((s) {
      if (!mounted) return;
      if (s is AsyncData<List<FinanceCategory>>) {
        setState(() => _categoriesMap = {for (final c in s.data) if (c.id != null) c.id!: c});
      }
    });
    final profiles = _profileController.data ?? [];
    _profileNames = {for (final p in profiles) if (p.id != null) p.id!: p.name};
  }

  @override
  void onReady() {
    configureLayout(title: 'Transactions', showBottomNav: true);
    _catController.loadCategories();
    _txController.loadAllTransactions();
    _planController.loadPlans();
  }

  @override
  void onDispose() {
    _catSub?.cancel();
  }

  void _showAddPlanSheet([TransactionPlan? plan]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanFormSheet(
        plan: plan,
        categoriesMap: _categoriesMap,
        onSave: (p) => plan == null ? _planController.createPlan(p) : _planController.updatePlan(p),
        onDelete: plan != null ? () => _planController.deletePlan(plan.id!) : null,
      ),
    );
  }

  void _showCompletePlanSheet(TransactionPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompletePlanSheet(
        plan: plan,
        onConfirm: (amount, date) async {
          await _planController.completePlan(plan.id!, amount: amount, date: date);
          await _txController.createTransaction(Transaction(
            userId: locator.get<AuthController>().currentUser?.id,
            amount: amount,
            type: plan.type,
            description: plan.description,
            date: date,
            financeCategoryId: plan.financeCategoryId,
            budgetProfileId: plan.budgetProfileId,
            notes: plan.notes,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AsyncStreamBuilder<List<TransactionPlan>>(
        state: _planController,
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, msg) => Center(child: Text(msg)),
        builder: (_, plans) => AsyncStreamBuilder<List<Transaction>>(
          state: _txController,
          loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, msg) => Center(child: Text(msg)),
          builder: (_, txs) => _Feed(
            plans: plans,
            transactions: txs,
            categoriesMap: _categoriesMap,
            profileNames: _profileNames,
            historyFilter: _historyFilter,
            filters: _filters,
            isDark: isDark,
            onFilterChange: (f) => setState(() => _historyFilter = f),
            onEditPlan: _showAddPlanSheet,
            onCompletePlan: _showCompletePlanSheet,
            onCancelPlan: (p) => _planController.cancelPlan(p.id!),
          ),
        ),
      ),
    );
  }
}

// ─── Feed ─────────────────────────────────────────────────────────────────────

class _Feed extends StatelessWidget {
  final List<TransactionPlan> plans;
  final List<Transaction> transactions;
  final Map<String, FinanceCategory> categoriesMap;
  final Map<String, String> profileNames;
  final String historyFilter;
  final List<String> filters;
  final bool isDark;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<TransactionPlan> onEditPlan;
  final ValueChanged<TransactionPlan> onCompletePlan;
  final Future<void> Function(TransactionPlan) onCancelPlan;

  const _Feed({
    required this.plans, required this.transactions, required this.categoriesMap,
    required this.profileNames,
    required this.historyFilter, required this.filters, required this.isDark,
    required this.onFilterChange, required this.onEditPlan,
    required this.onCompletePlan, required this.onCancelPlan,
  });

  @override
  Widget build(BuildContext context) {
    final pending = plans.where((p) => p.isPending).toList()
      ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
    final overdueCount = pending.where((p) => p.isOverdue).length;

    final filtered = _filterTxs()..sort((a, b) => b.date.compareTo(a.date));

    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.18)
        : AppColors.border.withValues(alpha: 0.45);

    return CustomScrollView(
      slivers: [
        // ── Upcoming plans ────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SectionLabel(
            label: 'UPCOMING PLANS',
            isDark: isDark,
            trailing: pending.isEmpty
                ? null
                : overdueCount > 0
                    ? _Badge('$overdueCount overdue', AppColors.error)
                    : _Badge('${pending.length}', AppColors.textTertiary),
          ),
        ),
        if (pending.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1C) : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 0.5),
                ),
                child: Column(children: [
                  Icon(Icons.event_available_rounded, size: 28, color: AppColors.textDisabled),
                  const SizedBox(height: 8),
                  Text('No upcoming plans', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Tap + to schedule a future transaction',
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
                ]),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => TweenAnimationBuilder<double>(
                  key: ValueKey(pending[i].id),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 450),
                  curve: Interval(
                    (i * 0.08).clamp(0.0, 0.6),
                    ((i * 0.08) + 0.4).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                  builder: (_, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
                  ),
                  child: _PlanCard(
                    plan: pending[i],
                    category: categoriesMap[pending[i].financeCategoryId],
                    isDark: isDark,
                    onEdit: () => onEditPlan(pending[i]),
                    onComplete: () => onCompletePlan(pending[i]),
                    onCancel: () => onCancelPlan(pending[i]),
                  ),
                ),
                childCount: pending.length,
              ),
            ),
          ),

        // ── History ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Divider(height: 1, color: borderColor),
          ),
        ),
        SliverToBoxAdapter(
          child: _SectionLabel(label: 'HISTORY', isDark: isDark),
        ),

        // Filter chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              children: filters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _FilterChip(
                  label: f, selected: historyFilter == f,
                  isDark: isDark, onTap: () => onFilterChange(f),
                ),
              )).toList(),
            ),
          ),
        ),


        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Transactions
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textDisabled),
                const SizedBox(height: 10),
                Text('No transactions',
                    style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
              ]),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final t = filtered[i];
                  final showDate = i == 0 || !_sameDay(t.date, filtered[i - 1].date);
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(t.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 450),
                    curve: Interval(
                      (i * 0.08).clamp(0.0, 0.6),
                      ((i * 0.08) + 0.4).clamp(0.0, 1.0),
                      curve: Curves.easeOut,
                    ),
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDate) _DateHeader(date: t.date, isDark: isDark),
                        _TxRow(transaction: t, category: categoriesMap[t.financeCategoryId], profileName: t.budgetProfileId != null ? profileNames[t.budgetProfileId] : null, isDark: isDark),
                      ],
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  List<Transaction> _filterTxs() => switch (historyFilter) {
        'Income' => transactions.where((t) => t.type == TransactionType.income).toList(),
        'Expense' => transactions.where((t) => t.type == TransactionType.expense).toList(),
        'Savings' => transactions.where((t) => t.savingsId != null).toList(),
        'Goals' => transactions.where((t) => t.goalId != null).toList(),
        _ => [...transactions],
      };

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Plan card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final TransactionPlan plan;
  final FinanceCategory? category;
  final bool isDark;
  final VoidCallback onEdit, onComplete;
  final Future<void> Function() onCancel;

  const _PlanCard({
    required this.plan, required this.category, required this.isDark,
    required this.onEdit, required this.onComplete, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = plan.type == TransactionType.income;
    final typeColor = isIncome ? AppColors.success : AppColors.error;
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = plan.isOverdue
        ? AppColors.error.withValues(alpha: 0.35)
        : (isDark ? AppColors.border.withValues(alpha: 0.18) : AppColors.border.withValues(alpha: 0.4));
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: typeColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(plan.description,
                        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      if (category != null) ...[
                        Container(width: 5, height: 5,
                            decoration: BoxDecoration(color: _catColor(category!.type), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(category!.name,
                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 6),
                      ],
                      _DueChip(plan: plan),
                    ]),
                  ]),
                ),
                const SizedBox(width: 8),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    '${isIncome ? '+' : '-'}${currencyFormatter.format(plan.amount, decimalDigits: 2)}',
                    style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w700, color: typeColor,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  const SizedBox(height: 6),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    _SmallButton(label: 'Done', color: AppColors.success, onTap: onComplete),
                    const SizedBox(width: 4),
                    _PopupMenu(onEdit: onEdit, onCancel: onCancel, isDark: isDark),
                  ]),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Color _catColor(CategoryType t) => switch (t) {
        CategoryType.income => AppColors.success,
        CategoryType.expense => AppColors.error,
        CategoryType.savings => AppColors.info,
        CategoryType.investment => AppColors.accent,
        CategoryType.transfer => AppColors.textSecondary,
      };
}

class _DueChip extends StatelessWidget {
  final TransactionPlan plan;
  const _DueChip({required this.plan});

  @override
  Widget build(BuildContext context) {
    if (plan.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: Text('Overdue', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error)),
      );
    }
    if (plan.isDueToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: Text('Today', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning)),
      );
    }
    return Text(DateFormat('MMM d').format(plan.plannedDate),
        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary));
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SmallButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ),
  );
}

class _PopupMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final Future<void> Function() onCancel;
  final bool isDark;
  const _PopupMenu({required this.onEdit, required this.onCancel, required this.isDark});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    iconSize: 16,
    padding: EdgeInsets.zero,
    icon: Icon(Icons.more_horiz_rounded, size: 16, color: AppColors.textTertiary),
    onSelected: (v) { if (v == 'edit') onEdit(); if (v == 'cancel') onCancel(); },
    itemBuilder: (_) => [
      PopupMenuItem(value: 'edit', child: Row(children: [
        const Icon(Icons.edit_outlined, size: 14), const SizedBox(width: 10),
        Text('Edit', style: GoogleFonts.dmSans(fontSize: 13)),
      ])),
      PopupMenuItem(value: 'cancel', child: Row(children: [
        Icon(Icons.close_rounded, size: 14, color: AppColors.error), const SizedBox(width: 10),
        Text('Cancel plan', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.error)),
      ])),
    ],
  );
}

// ─── Date header ──────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final bool isDark;
  const _DateHeader({required this.date, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('EEE, MMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 4),
      child: Row(children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondary : AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(child: Divider(height: 1, color: AppColors.border.withValues(alpha: isDark ? 0.18 : 0.35))),
      ]),
    );
  }
}

// ─── Transaction row ──────────────────────────────────────────────────────────

class _TxRow extends StatelessWidget {
  final Transaction transaction;
  final FinanceCategory? category;
  final String? profileName;
  final bool isDark;
  const _TxRow({required this.transaction, required this.category, required this.isDark, this.profileName});

  @override
  Widget build(BuildContext context) {
    final isIn = transaction.type == TransactionType.income;
    final color = isIn ? AppColors.success : AppColors.error;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    final tags = [
      if (transaction.savingsId != null) ('Savings', AppColors.info),
      if (transaction.goalId != null) ('Goal', AppColors.accent),
      if (transaction.debtId != null) ('Debt', AppColors.error),
      if (transaction.subscriptionId != null) ('Sub', AppColors.warning),
    ];
    final profileLabel = profileName;

    return InkWell(
      onTap: () => TransactionDetailSheet.show(context, transaction: transaction),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Icon(isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(transaction.description ?? (category != null ? (isIn ? 'Earns ${category!.name}' : 'Pays ${category!.name}') : (isIn ? 'Income' : 'Expense')),
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: fg),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              if (category != null) ...[
                Container(width: 5, height: 5,
                    decoration: BoxDecoration(color: _catColor(category!.type), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(category!.name, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              ],
              ...tags.map((tag) => Container(
                margin: const EdgeInsets.only(left: 5),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: tag.$2.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(tag.$1, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: tag.$2)),
              )),
              if (profileLabel != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.25), width: 0.5),
                  ),
                  child: Text(profileLabel, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.accent)),
                ),
              ],
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${isIn ? '+' : '-'}${currencyFormatter.format(transaction.amount, decimalDigits: 2)}',
              style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w700, color: color,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          if (transaction.fee > 0)
            Text('fee ${currencyFormatter.format(transaction.fee, decimalDigits: 2)}',
                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary)),
        ]),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
      ]),
    ));
  }

  Color _catColor(CategoryType t) => switch (t) {
        CategoryType.income => AppColors.success,
        CategoryType.expense => AppColors.error,
        CategoryType.savings => AppColors.info,
        CategoryType.investment => AppColors.accent,
        CategoryType.transfer => AppColors.textSecondary,
      };
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  final Widget? trailing;
  const _SectionLabel({required this.label, required this.isDark, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
    child: Row(children: [
      Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 0.8)),
      if (trailing != null) ...[const SizedBox(width: 8), trailing!],
    ]),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );
}

// ─── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected, isDark;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: selected ? null : Border.all(color: isDark ? AppColors.border.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Text(label, style: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : (isDark ? AppColors.primaryForeground : AppColors.textPrimary))),
    ),
  );
}

// ─── Complete plan sheet ──────────────────────────────────────────────────────

class _CompletePlanSheet extends StatefulWidget {
  final TransactionPlan plan;
  final Future<void> Function(double amount, DateTime date) onConfirm;
  const _CompletePlanSheet({required this.plan, required this.onConfirm});

  @override
  State<_CompletePlanSheet> createState() => _CompletePlanSheetState();
}

class _CompletePlanSheetState extends State<_CompletePlanSheet> {
  late final TextEditingController _amountCtrl;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.plan.amount.toStringAsFixed(2));
  }

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    try {
      await widget.onConfirm(amount, _date);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final isIncome = widget.plan.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Record Transaction', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
              Text(widget.plan.description,
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
          const SizedBox(height: 20),
          TextField(
            controller: _amountCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.dmMono(fontSize: 15, color: fg),
            decoration: InputDecoration(
              labelText: 'Actual Amount',
              prefixText: '${currencyFormatter.currencySymbol} ',
              helperText: 'Planned: ${currencyFormatter.format(widget.plan.amount, decimalDigits: 2)}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: color, width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 90)),
                  lastDate: DateTime.now().add(const Duration(days: 1)));
              if (d != null) setState(() => _date = d);
            },
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date',
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(DateFormat('MMM d, y').format(_date),
                  style: GoogleFonts.dmSans(fontSize: 14, color: fg)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Confirm & Record', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Plan form sheet ──────────────────────────────────────────────────────────

class _PlanFormSheet extends StatefulWidget {
  final TransactionPlan? plan;
  final Map<String, FinanceCategory> categoriesMap;
  final void Function(TransactionPlan) onSave;
  final VoidCallback? onDelete;
  const _PlanFormSheet({this.plan, required this.categoriesMap, required this.onSave, this.onDelete});

  @override
  State<_PlanFormSheet> createState() => _PlanFormSheetState();
}

class _PlanFormSheetState extends State<_PlanFormSheet> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final FinanceCategoryController _catController;
  late final BudgetProfileController _profileController;
  late final BudgetController _budgetController;
  late TransactionType _type;
  late DateTime _date;
  String? _categoryId;
  String? _selectedProfileId;
  String? _selectedProfileName;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _amountCtrl = TextEditingController(text: p != null ? p.amount.toStringAsFixed(2) : '');
    _type = p?.type ?? TransactionType.expense;
    _date = p?.plannedDate ?? DateTime.now().add(const Duration(days: 1));
    _categoryId = p?.financeCategoryId;
    _catController = locator.get<FinanceCategoryController>();
    _profileController = locator.get<BudgetProfileController>();
    _budgetController = locator.get<BudgetController>();
    _initProfile(p?.budgetProfileId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedProfileId == null && mounted) {
        setState(() => _initProfile(p?.budgetProfileId));
      }
    });
  }

  void _initProfile(String? preferredId) {
    final s = _profileController.state;
    if (s is! AsyncData<List<BudgetProfile>>) return;
    final profiles = s.data;
    if (profiles.isEmpty) return;
    final resolved = preferredId != null
        ? profiles.where((p) => p.id == preferredId).firstOrNull
        : null;
    final profile = resolved ?? profiles.where((p) => p.isMain).firstOrNull ?? profiles.first;
    _selectedProfileId = profile.id;
    _selectedProfileName = profile.name;
  }

  Set<String>? get _allowedCategoryIds {
    if (_selectedProfileId == null) return null;
    final s = _budgetController.state;
    if (s is! AsyncData<List<Budget>>) return null;
    return s.data
        .where((b) => b.budgetProfileId == _selectedProfileId)
        .expand((b) => b.categories.map((c) => c.financeCategoryId))
        .toSet();
  }

  @override
  void dispose() { _descCtrl.dispose(); _amountCtrl.dispose(); super.dispose(); }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text);
    if (_descCtrl.text.trim().isEmpty || amount == null || amount <= 0) return;
    widget.onSave(TransactionPlan(
      id: widget.plan?.id,
      userId: locator.get<AuthController>().currentUser?.id ?? '',
      description: _descCtrl.text.trim(),
      amount: amount,
      type: _type,
      plannedDate: _date,
      financeCategoryId: _categoryId,
      budgetProfileId: _selectedProfileId,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final isIncome = _type == TransactionType.income;
    final typeColor = isIncome ? AppColors.success : AppColors.error;
    final selectedCat = _categoryId != null ? widget.categoriesMap[_categoryId] : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Text(widget.plan == null ? 'Plan a Transaction' : 'Edit Plan',
                style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
            const Spacer(),
            if (widget.onDelete != null)
              IconButton(
                onPressed: () { widget.onDelete!(); Navigator.pop(context); },
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
          ]),
          const SizedBox(height: 16),
          // Type selector
          Row(children: [
            Expanded(child: _TypePill(label: 'Expense', icon: Icons.arrow_upward_rounded,
                color: AppColors.error, selected: !isIncome, onTap: () => setState(() => _type = TransactionType.expense))),
            const SizedBox(width: 8),
            Expanded(child: _TypePill(label: 'Income', icon: Icons.arrow_downward_rounded,
                color: AppColors.success, selected: isIncome, onTap: () => setState(() => _type = TransactionType.income))),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _descCtrl, autofocus: true,
            style: GoogleFonts.dmSans(fontSize: 14, color: fg),
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: typeColor, width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.dmMono(fontSize: 14, color: fg),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '${currencyFormatter.currencySymbol} ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: typeColor, width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          // Budget profile picker
          InkWell(
            onTap: () => _pickProfile(context),
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Budget Profile *',
                suffixIcon: const Icon(Icons.chevron_right_rounded, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _selectedProfileId == null ? AppColors.error.withValues(alpha: 0.6) : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _selectedProfileId == null ? AppColors.error.withValues(alpha: 0.5) : AppColors.border,
                  ),
                ),
              ),
              child: Text(
                _selectedProfileName ?? 'Select a budget profile',
                style: GoogleFonts.dmSans(fontSize: 14,
                    color: _selectedProfileId != null ? fg : (_selectedProfileId == null ? AppColors.error : AppColors.textTertiary)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Category picker — only shown after profile is selected
          if (_selectedProfileId != null) ...[
            InkWell(
              onTap: () => _pickCategory(context),
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Category (optional)',
                  suffixIcon: const Icon(Icons.chevron_right_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(selectedCat?.name ?? 'Select category',
                    style: GoogleFonts.dmSans(fontSize: 14,
                        color: selectedCat != null ? fg : AppColors.textTertiary)),
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Date picker
          InkWell(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _date = d);
            },
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Planned for',
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(DateFormat('EEE, MMM d, y').format(_date),
                  style: GoogleFonts.dmSans(fontSize: 14, color: fg)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(backgroundColor: typeColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(widget.plan == null ? 'Save Plan' : 'Update Plan',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  void _pickProfile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final s = _profileController.state;
    final profiles = s is AsyncData<List<BudgetProfile>> ? s.data : <BudgetProfile>[];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text('Budget Profile', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: fg))),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: profiles.length,
              itemBuilder: (_, i) {
                final p = profiles[i];
                final sel = _selectedProfileId == p.id;
                return ListTile(
                  title: Text(p.name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: fg)),
                  trailing: sel ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
                  onTap: () { setState(() { _selectedProfileId = p.id; _selectedProfileName = p.name; _categoryId = null; }); Navigator.pop(context); },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  void _pickCategory(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    final targetType = _type == TransactionType.income ? CategoryType.income : CategoryType.expense;
    final allowed = _allowedCategoryIds;

    final s = _catController.state;
    final categories = (s is AsyncData<List<FinanceCategory>>
        ? s.data
            .where((c) => c.type == targetType && !c.isArchive)
            .where((c) => allowed == null || (c.id != null && allowed.contains(c.id)))
            .toList()
        : <FinanceCategory>[])
      ..sort((a, b) => a.name.compareTo(b.name));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text('Select Category', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: fg))),
          ListTile(
            leading: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.textSecondary),
            title: Text('None', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
            onTap: () { setState(() => _categoryId = null); Navigator.pop(context); },
          ),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _selectedProfileId != null ? 'No categories in this budget profile' : 'No categories found',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final c = categories[i];
                  final selected = _categoryId == c.id;
                  return ListTile(
                    leading: Container(width: 8, height: 8,
                        decoration: BoxDecoration(color: _catColor(c.type), shape: BoxShape.circle)),
                    title: Text(c.name, style: GoogleFonts.dmSans(fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: fg)),
                    trailing: selected ? Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
                    onTap: () { setState(() => _categoryId = c.id); Navigator.pop(context); },
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  Color _catColor(CategoryType t) => switch (t) {
        CategoryType.income => AppColors.success,
        CategoryType.expense => AppColors.error,
        CategoryType.savings => AppColors.info,
        CategoryType.investment => AppColors.accent,
        CategoryType.transfer => AppColors.textSecondary,
      };
}

class _TypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypePill({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : (isDark ? const Color(0xFF2A2A28) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color.withValues(alpha: 0.45) : Colors.transparent, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: selected ? color : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.dmSans(fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? color : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
