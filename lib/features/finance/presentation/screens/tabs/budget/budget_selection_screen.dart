import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/budget_month_filter.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

class BudgetSelectionScreen extends StatefulWidget {
  final VoidCallback onMonthlyTap;
  final void Function(BudgetProfile) onProfileTap;
  final VoidCallback onNewProfile;

  const BudgetSelectionScreen({
    super.key,
    required this.onMonthlyTap,
    required this.onProfileTap,
    required this.onNewProfile,
  });

  @override
  State<BudgetSelectionScreen> createState() => _BudgetSelectionScreenState();
}

class _BudgetSelectionScreenState extends State<BudgetSelectionScreen> {
  late final BudgetController _budgetController;
  late final TransactionController _txController;
  late final BudgetProfileController _profileController;
  late final DebtController _debtController;
  late final SubscriptionController _subController;
  late final GoalController _goalController;

  @override
  void initState() {
    super.initState();
    _budgetController = locator.get<BudgetController>();
    _txController = locator.get<TransactionController>();
    _profileController = locator.get<BudgetProfileController>();
    _debtController = locator.get<DebtController>();
    _subController = locator.get<SubscriptionController>();
    _goalController = locator.get<GoalController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _budgetController.loadBudgets();
      final now = DateTime.now();
      _txController.loadTransactionsByDateRange(
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 1),
      );
      _debtController.loadDebts();
      _subController.loadSubscriptions();
      _goalController.loadGoals();
    });
    _profileController.stream.listen((_) { if (mounted) setState(() {}); });
  }

  Widget _buildContent(
    bool isDark,
    List<Budget> budgets,
    List<Transaction> txs,
    List<Debt> debts,
    List<Subscription> subs,
    List<Goal> goals,
  ) {
    final profiles = (_profileController.state is AsyncData<List<BudgetProfile>>
        ? (_profileController.state as AsyncData<List<BudgetProfile>>).data
        : <BudgetProfile>[]);
    final mainProfile = profiles.where((p) => p.isMain).firstOrNull;
    final otherProfiles = profiles.where((p) => !p.isMain).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show the main card when a profile is explicitly pinned as main.
        // No fallback "Monthly Budget" – users must create a real profile.
        if (mainProfile != null) ...[
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: child),
            ),
            child: _MainCard(
              isDark: isDark, budgets: budgets, txs: txs, debts: debts,
              subs: subs, goals: goals, mainProfile: mainProfile,
              onTap: () => widget.onProfileTap(mainProfile),
            ),
          ),
          const SizedBox(height: 28),
        ],
        _BranchesList(
          isDark: isDark, profiles: otherProfiles, budgets: budgets,
          txs: txs, debts: debts, subs: subs, goals: goals,
          onNew: widget.onNewProfile, onTap: widget.onProfileTap,
          onSetMain: (p) => _profileController.setAsMain(p.id!),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: AsyncStreamBuilder<List<Budget>>(
        state: _budgetController,
        builder: (_, budgets) => AsyncStreamBuilder<List<Transaction>>(
          state: _txController,
          builder: (_, txs) => AsyncStreamBuilder<List<Debt>>(
            state: _debtController,
            builder: (_, d) => AsyncStreamBuilder<List<Subscription>>(
              state: _subController,
              builder: (_, s) => AsyncStreamBuilder<List<Goal>>(
                state: _goalController,
                builder: (_, g) => _buildContent(isDark, budgets, txs, d, s, g),
                loadingBuilder: (_) => _buildContent(isDark, budgets, txs, d, s, const []),
                errorBuilder: (_, __) => _buildContent(isDark, budgets, txs, d, s, const []),
              ),
              loadingBuilder: (_) => _buildContent(isDark, budgets, txs, d, const [], const []),
              errorBuilder: (_, __) => _buildContent(isDark, budgets, txs, d, const [], const []),
            ),
            loadingBuilder: (_) => _buildContent(isDark, budgets, txs, const [], const [], const []),
            errorBuilder: (_, __) => _buildContent(isDark, budgets, txs, const [], const [], const []),
          ),
          loadingBuilder: (_) => _buildContent(isDark, budgets, const [], const [], const [], const []),
          errorBuilder: (_, __) => _buildContent(isDark, budgets, const [], const [], const [], const []),
        ),
        loadingBuilder: (_) => _buildContent(isDark, const [], const [], const [], const [], const []),
        errorBuilder: (_, __) => _buildContent(isDark, const [], const [], const [], const [], const []),
      ),
    );
  }
}


class _MainCard extends StatelessWidget {
  final bool isDark;
  final List<Budget> budgets;
  final List<Transaction> txs;
  final List<Debt> debts;
  final List<Subscription> subs;
  final List<Goal> goals;
  final BudgetProfile? mainProfile;
  final VoidCallback onTap;

  const _MainCard({required this.isDark, required this.budgets, required this.txs, required this.debts, required this.subs, required this.goals, required this.mainProfile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final mainId = mainProfile?.id;
    final monthBudgets = budgets.where((b) => b.month == monthKey && b.status == BudgetStatus.active && (mainId != null ? b.budgetProfileId == mainId : b.budgetProfileId == null)).toList();
    final spent = BudgetMonthFilter.buildSpentByCategory(txs);

    double sumSpent(bool income) => monthBudgets
        .where((b) => (b.budgetType == BudgetType.income) == income)
        .fold(0.0, (s, b) => s + b.categories.fold(0.0, (cs, c) => cs + (spent[c.financeCategoryId] ?? 0.0)));
    double sumPlanned(bool income) => monthBudgets
        .where((b) => (b.budgetType == BudgetType.income) == income)
        .fold(0.0, (s, b) => s + b.budgetTarget);

    final actualIncome = sumSpent(true);
    final plannedIncome = sumPlanned(true);
    final actualExpenses = sumSpent(false);
    final plannedExpenses = sumPlanned(false);
    final net = actualIncome - actualExpenses;
    final isPositive = net >= 0;

    final cardBg = isDark ? const Color(0xFF232321) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: isDark ? 0.12 : 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 5, height: 5, decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('MAIN', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success, letterSpacing: 0.4)),
                ]),
              ),
              const Spacer(),
              Text(
                DateFormat('MMMM yyyy').format(now),
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.textTertiary),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                mainProfile?.name ?? 'Monthly Budget',
                style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: net),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (_, v, __) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    '${isPositive ? '+' : ''}${currencyFormatter.format(v, decimalDigits: 0)}',
                    style: GoogleFonts.dmMono(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: isPositive ? AppColors.success : AppColors.error,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      isPositive ? 'surplus' : 'deficit',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              _ProgressRow(label: 'Inflow', actual: actualIncome, planned: plannedIncome, color: AppColors.success),
              const SizedBox(height: 8),
              _ProgressRow(label: 'Outflow', actual: actualExpenses, planned: plannedExpenses, color: AppColors.error),
              const SizedBox(height: 14),
              _CountPillRow(
                isDark: isDark,
                subsCount: subs.length,
                debtsCount: debts.where((d) => d.status == DebtStatus.active && d.budgetProfileId == null).length,
                goalsCount: goals.where((g) => g.status == GoalStatus.active && g.budgetProfileId == null).length,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double actual, planned;
  final Color color;

  const _ProgressRow({required this.label, required this.actual, required this.planned, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, v, __) => Column(children: [
        Row(children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            '${currencyFormatter.format(actual * v, decimalDigits: 0)} / ${currencyFormatter.format(planned, decimalDigits: 0)}',
            style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.textSecondary, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(children: [
            Container(height: 4, color: color.withValues(alpha: 0.12)),
            FractionallySizedBox(widthFactor: progress * v, child: Container(height: 4, color: color)),
          ]),
        ),
      ]),
    );
  }
}

class _MiniProgressRow extends StatelessWidget {
  final String label;
  final double actual, planned;
  final Color color;

  const _MiniProgressRow({required this.label, required this.actual, required this.planned, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, v, __) => Column(children: [
        Row(children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary)),
          const Spacer(),
          Text(
            '${currencyFormatter.format(actual * v, decimalDigits: 0)} / ${currencyFormatter.format(planned, decimalDigits: 0)}',
            style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.textTertiary, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ]),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(children: [
            Container(height: 3, color: color.withValues(alpha: 0.12)),
            FractionallySizedBox(widthFactor: progress * v, child: Container(height: 3, color: color)),
          ]),
        ),
      ]),
    );
  }
}


class _BranchesList extends StatelessWidget {
  final bool isDark;
  final List<BudgetProfile> profiles;
  final List<Budget> budgets;
  final List<Transaction> txs;
  final List<Debt> debts;
  final List<Subscription> subs;
  final List<Goal> goals;
  final VoidCallback onNew;
  final void Function(BudgetProfile) onTap;
  final void Function(BudgetProfile) onSetMain;

  const _BranchesList({required this.isDark, required this.profiles, required this.budgets, required this.txs, required this.debts, required this.subs, required this.goals, required this.onNew, required this.onTap, required this.onSetMain});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF232321) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header row
      Row(children: [
        Text(
          'BUDGETS',
          style: GoogleFonts.dmMono(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.6),
        ),
        if (profiles.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${profiles.length}', style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.textTertiary)),
          ),
        ],
        const Spacer(),
        GestureDetector(
          onTap: onNew,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, size: 12, color: AppColors.accent),
              const SizedBox(width: 4),
              Text('New', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),

      if (profiles.isEmpty)
        _EmptyBranches(isDark: isDark, onNew: onNew)
      else
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: profiles.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final isLast = i == profiles.length - 1;
              final accentColor = p.colorHex != null
                  ? Color(int.parse(p.colorHex!.replaceFirst('#', '0xFF')))
                  : AppColors.accent;
              final statusColor = switch (p.status) {
                BudgetProfileStatus.active => AppColors.success,
                BudgetProfileStatus.completed => AppColors.info,
                BudgetProfileStatus.archived => AppColors.textTertiary,
              };

              final profileBudgets = budgets.where((b) => b.budgetProfileId == p.id && b.status == BudgetStatus.active).toList();
              final spent = BudgetMonthFilter.buildSpentByCategory(txs);
              double sumSpent(bool income) => profileBudgets
                  .where((b) => (b.budgetType == BudgetType.income) == income)
                  .fold(0.0, (s, b) => s + b.categories.fold(0.0, (cs, c) => cs + (spent[c.financeCategoryId] ?? 0.0)));
              double sumPlanned(bool income) => profileBudgets
                  .where((b) => (b.budgetType == BudgetType.income) == income)
                  .fold(0.0, (s, b) => s + b.budgetTarget);

              final actualIncome = sumSpent(true);
              final plannedIncome = sumPlanned(true);
              final actualExpenses = sumSpent(false);
              final plannedExpenses = sumPlanned(false);

              return TweenAnimationBuilder<double>(
                key: ValueKey(p.id),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Interval(
                  (i * 0.08).clamp(0.0, 0.6),
                  ((i * 0.08) + 0.4).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                ),
                builder: (_, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child),
                ),
                child: GestureDetector(
                onTap: () => onTap(p),
                behavior: HitTestBehavior.opaque,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        // Color pip
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        // Name + subtitle
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              p.name,
                              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_subtitle(p).isNotEmpty)
                              Text(
                                _subtitle(p),
                                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ]),
                        ),
                        const SizedBox(width: 10),
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.profileType.displayName,
                            style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status dot
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showProfileActions(context, p, isDark),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.more_horiz_rounded, size: 17, color: AppColors.textTertiary),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
                      ]),
                      if (profileBudgets.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _MiniProgressRow(label: 'Inflow', actual: actualIncome, planned: plannedIncome, color: AppColors.success),
                        const SizedBox(height: 5),
                        _MiniProgressRow(label: 'Outflow', actual: actualExpenses, planned: plannedExpenses, color: AppColors.error),
                      ],
                      _CountPillRow(
                        isDark: isDark,
                        subsCount: subs.where((s) => s.budgetProfileId == p.id).length,
                        debtsCount: debts.where((d) => d.status == DebtStatus.active && d.budgetProfileId == p.id).length,
                        goalsCount: goals.where((g) => g.status == GoalStatus.active && g.budgetProfileId == p.id).length,
                        compact: true,
                      ),
                    ]),
                  ),
                  if (!isLast)
                    Divider(height: 1, thickness: 0.5, color: borderColor, indent: 14, endIndent: 14),
                ]),
              ),
              );
            }).toList(),
          ),
        ),
    ]);
  }

  String _subtitle(BudgetProfile p) {
    if (p.profileType == BudgetProfileType.monthly) {
      return p.description ?? '';
    }
    final fmt = DateFormat('MMM d, yyyy');
    if (p.startDate != null && p.endDate != null) {
      return '${fmt.format(p.startDate!)} → ${fmt.format(p.endDate!)}';
    }
    if (p.startDate != null) return 'From ${fmt.format(p.startDate!)}';
    if (p.endDate != null) return 'Until ${fmt.format(p.endDate!)}';
    return p.description ?? '';
  }
}

void _showProfileActions(BuildContext context, BudgetProfile profile, bool isDark) {
  final bg = isDark ? AppColors.cardDark : AppColors.card;
  final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
  final accentColor = profile.colorHex != null
      ? Color(int.parse(profile.colorHex!.replaceFirst('#', '0xFF')))
      : AppColors.accent;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        // Profile identity
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(profile.name, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: fg))),
        ]),
        const SizedBox(height: 20),
        // Set as Main action
        InkWell(
          onTap: () {
            Navigator.pop(context);
            locator.get<BudgetProfileController>().setAsMain(profile.id!);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Container(width: 34, height: 34,
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.push_pin_rounded, size: 16, color: AppColors.accent)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Set as Main', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent)),
                Text('Pin this budget to the top as your primary', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
              ])),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.accent),
            ]),
          ),
        ),
      ]),
    ),
  );
}


class _EmptyBranches extends StatelessWidget {
  final bool isDark;
  final VoidCallback onNew;
  const _EmptyBranches({required this.isDark, required this.onNew});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: onNew,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1, style: BorderStyle.solid),
        ),
        child: Column(children: [
          Text(
            'No budgets yet',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 3),
          Text(
            'Tap to create a separate budget',
            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary),
          ),
        ]),
      ),
    );
  }
}


class _CountPillRow extends StatelessWidget {
  final bool isDark;
  final int subsCount;
  final int debtsCount;
  final int goalsCount;
  final bool compact;

  const _CountPillRow({
    required this.isDark,
    required this.subsCount,
    required this.debtsCount,
    required this.goalsCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      if (subsCount > 0) (label: 'Subs', count: subsCount, color: AppColors.info),
      if (debtsCount > 0) (label: 'Debts', count: debtsCount, color: AppColors.error),
      if (goalsCount > 0) (label: 'Goals', count: goalsCount, color: AppColors.accent),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: compact ? 8 : 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: items.map((item) => Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 2 : 3,
          ),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${item.label} (${item.count})',
            style: GoogleFonts.dmSans(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: item.color,
            ),
          ),
        )).toList(),
      ),
    );
  }
}
