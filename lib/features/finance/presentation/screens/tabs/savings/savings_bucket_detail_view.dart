import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/screens/budget_simple_sheets.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

// ─── Detail view (replaces savings list in-place) ─────────────────────────────

class SavingsBucketDetailView extends StatefulWidget {
  final SavingsBucket bucket;
  final TransactionController txController;
  final VoidCallback onBack;
  final VoidCallback onAddEntry;
  final VoidCallback onEdit;
  const SavingsBucketDetailView({
    super.key,
    required this.bucket,
    required this.txController,
    required this.onBack,
    required this.onAddEntry,
    required this.onEdit,
  });

  @override
  State<SavingsBucketDetailView> createState() =>
      _SavingsBucketDetailViewState();
}

class _SavingsBucketDetailViewState extends State<SavingsBucketDetailView> {
  late final GoalController _goalController;
  late final BudgetProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _goalController = locator.get<GoalController>();
    _profileController = locator.get<BudgetProfileController>();
  }

  Map<String, String> get _profileNames {
    final s = _profileController.state;
    if (s is AsyncData<List<BudgetProfile>>) {
      return {for (final p in s.data) if (p.id != null) p.id!: p.name};
    }
    return {};
  }

  void _showContributeSheet(Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalDetailSheet(
        goal: goal,
        goalController: _goalController,
        onContribute: (currentGoal, amount) async {
          final userId = locator.get<AuthController>().currentUser?.id ?? '';
          final categoryId = await locator
              .get<FinanceCategoryController>()
              .findOrCreateSavingsCategory(userId);

          final budgetName = currentGoal.budgetProfileId != null
              ? _profileNames[currentGoal.budgetProfileId]
              : null;
          final description = budgetName != null
              ? 'Contribution to ${currentGoal.name} • $budgetName'
              : 'Contribution to ${currentGoal.name}';

          await widget.txController.createTransaction(Transaction(
            amount: amount,
            type: TransactionType.income,
            date: DateTime.now(),
            goalId: currentGoal.id,
            savingsId: currentGoal.savingsBucketId,
            financeCategoryId: categoryId,
            description: description,
          ));

          await _goalController.contributeToGoal(currentGoal.id!, amount);

          if (currentGoal.savingsBucketId != null) {
            final savingsController = locator.get<SavingsController>();
            final buckets = savingsController.data ?? [];
            final bucket = buckets
                .where((b) => b.id == currentGoal.savingsBucketId)
                .firstOrNull;
            if (bucket != null) {
              await savingsController.updateSavingsBucket(
                bucket.copyWith(balance: bucket.balance + amount),
              );
            }
          }
        },
        onUpdate: (updated) => _goalController.updateGoal(updated),
      ),
    );
  }

  Color get _bucketColor => widget.bucket.colorHex != null
      ? Color(int.parse(widget.bucket.colorHex!.replaceFirst('#', '0xff')))
      : AppColors.accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final icon = IconHelper.fromString(widget.bucket.iconCodePoint);

    return Column(
      children: [
        _TopBar(
          bucket: widget.bucket,
          bucketColor: _bucketColor,
          icon: icon,
          isDark: isDark,
          fg: fg,
          onBack: widget.onBack,
          onEdit: widget.onEdit,
          onAddEntry: widget.onAddEntry,
        ),
        Expanded(
          child: AsyncStreamBuilder<List<Transaction>>(
            state: widget.txController,
            loadingBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __) => const Center(
              child: Text('Could not load transactions'),
            ),
            builder: (context, allTxs) {
              final txs = allTxs
                  .where((t) => t.savingsId == widget.bucket.id)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              return StreamStateBuilder<AsyncState<List<Goal>>>(
                state: _goalController,
                builder: (context, goalState) {
                  final goals = goalState is AsyncData<List<Goal>>
                      ? goalState.data
                          .where((g) => g.savingsBucketId == widget.bucket.id)
                          .toList()
                      : <Goal>[];

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _BalanceSummary(
                          bucket: widget.bucket,
                          txCount: txs.length,
                          bucketColor: _bucketColor,
                          isDark: isDark,
                        ),
                      ),
                      if (goals.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _LinkedGoalsSection(
                            goals: goals,
                            isDark: isDark,
                            onGoalTap: _showContributeSheet,
                            profileNames: _profileNames,
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: _SectionLabel(
                          label: 'HISTORY',
                          trailing: '${txs.length} entries',
                          isDark: isDark,
                        ),
                      ),
                      if (txs.isEmpty)
                        SliverToBoxAdapter(child: _EmptyHistory(isDark: isDark))
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final t = txs[i];
                              final showDate = i == 0 ||
                                  !_sameDay(t.date, txs[i - 1].date);
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
                                    if (showDate) _DateLabel(date: t.date),
                                    _EntryRow(transaction: t, isDark: isDark),
                                  ],
                                ),
                              );
                            },
                            childCount: txs.length,
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final SavingsBucket bucket;
  final Color bucketColor;
  final IconData icon;
  final bool isDark;
  final Color fg;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onAddEntry;

  const _TopBar({
    required this.bucket,
    required this.bucketColor,
    required this.icon,
    required this.isDark,
    required this.fg,
    required this.onBack,
    required this.onEdit,
    required this.onAddEntry,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.15)
        : AppColors.border.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            color: AppColors.textSecondary,
            onPressed: onBack,
            tooltip: 'Back to savings',
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bucketColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: bucketColor, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bucket.name,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            icon: Icons.edit_outlined,
            label: 'Edit',
            onTap: onEdit,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            icon: Icons.add_rounded,
            label: 'Add Entry',
            onTap: onAddEntry,
            isDark: isDark,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isPrimary;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary
        ? AppColors.accent
        : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.border.withValues(alpha: 0.3));
    final fg = isPrimary
        ? Colors.white
        : (isDark ? AppColors.primaryForeground : AppColors.textSecondary);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Balance summary ──────────────────────────────────────────────────────────

class _BalanceSummary extends StatelessWidget {
  final SavingsBucket bucket;
  final int txCount;
  final Color bucketColor;
  final bool isDark;

  const _BalanceSummary({
    required this.bucket,
    required this.txCount,
    required this.bucketColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: child),
      ),
      child: Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bucketColor.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bucketColor.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT BALANCE',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: bucketColor.withValues(alpha: 0.7),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: bucket.balance),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    currencyFormatter.format(v),
                    style: GoogleFonts.dmMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: bucketColor,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$txCount',
                style: GoogleFonts.dmMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
                ),
              ),
              Text(
                'entr${txCount == 1 ? 'y' : 'ies'}',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? trailing;
  final bool isDark;

  const _SectionLabel({required this.label, this.trailing, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            Text(
              trailing!,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Linked goals ─────────────────────────────────────────────────────────────

class _LinkedGoalsSection extends StatelessWidget {
  final List<Goal> goals;
  final bool isDark;
  final ValueChanged<Goal>? onGoalTap;
  final Map<String, String> profileNames;

  const _LinkedGoalsSection({
    required this.goals,
    required this.isDark,
    required this.profileNames,
    this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          label: 'LINKED GOALS',
          trailing: '${goals.length} goal${goals.length == 1 ? '' : 's'}',
          isDark: isDark,
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => TweenAnimationBuilder<double>(
              key: ValueKey(goals[i].id),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 450),
              curve: Interval(
                (i * 0.1).clamp(0.0, 0.6),
                ((i * 0.1) + 0.4).clamp(0.0, 1.0),
                curve: Curves.easeOut,
              ),
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(offset: Offset((1 - v) * 10, 0), child: child),
              ),
              child: _GoalCard(
                goal: goals[i],
                isDark: isDark,
                budgetName: goals[i].budgetProfileId != null
                    ? profileNames[goals[i].budgetProfileId]
                    : null,
                onTap: onGoalTap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final bool isDark;
  final String? budgetName;
  final ValueChanged<Goal>? onTap;

  const _GoalCard({required this.goal, required this.isDark, this.budgetName, this.onTap});

  Color get _goalColor => goal.colorHex != null
      ? Color(int.parse(goal.colorHex!.replaceFirst('#', '0xff')))
      : AppColors.accent;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.12)
        : AppColors.border.withValues(alpha: 0.4);
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final progress = goal.progress;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap != null ? () => onTap!(goal) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _goalColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Icon(
                  IconHelper.fromString(goal.iconCodePoint),
                  color: _goalColor,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (budgetName != null)
                      Text(
                        budgetName!,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: _goalColor.withValues(alpha: isDark ? 0.15 : 0.10),
                valueColor: AlwaysStoppedAnimation(_goalColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${currencyFormatter.format(goal.currentAmount)} of ${currencyFormatter.format(goal.targetAmount)}',
            style: GoogleFonts.dmMono(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

// ─── History ──────────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  final bool isDark;
  const _EmptyHistory({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 36, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No entries yet',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap Add Entry to record your first deposit',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  final DateTime date;
  const _DateLabel({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        DateFormat('MMMM d, yyyy').format(date),
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final Transaction transaction;
  final bool isDark;

  const _EntryRow({required this.transaction, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction.type == TransactionType.income;
    final color = isDeposit ? AppColors.success : AppColors.error;
    final sign = isDeposit ? '+' : '-';
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(
              isDeposit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 15,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ??
                      (isDeposit ? 'Deposit' : 'Withdrawal'),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('h:mm a').format(transaction.date),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${currencyFormatter.format(transaction.amount)}',
            style: GoogleFonts.dmMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
