import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';

String entityLinkDescription(String type, {required bool isIncome}) =>
    switch (type) {
      'debt_payment' => 'Pay back an existing debt',
      'lending' => isIncome
          ? 'Select which receivable was collected'
          : 'Record money you lent — creates a new receivable',
      'debt_received' => 'Record a loan you received — creates a new debt',
      'goal' => 'Contribute toward a savings goal',
      'subscription' => 'Log a subscription payment — auto-fills amount',
      _ => '',
    };

String entityLinkTypeLabel(String type) => switch (type) {
  'debt_payment' => 'Debt…',
  'lending' => 'Receivable…',
  'goal' => 'Goal…',
  'subscription' => 'Sub…',
  _ => 'Link',
};

class TransactionCreateEntityTypeSheet extends StatelessWidget {
  final bool isIncome;
  final String? currentEntityType;
  final VoidCallback onSelectNone;
  final void Function(String type) onSelectType;

  const TransactionCreateEntityTypeSheet({
    super.key,
    required this.isIncome,
    required this.currentEntityType,
    required this.onSelectNone,
    required this.onSelectType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;

    final types = isIncome
        ? [
            (
              type: 'lending',
              icon: Icons.arrow_downward_rounded,
              label: 'Receivable Collected',
              color: AppColors.success,
            ),
          ]
        : [
            (
              type: 'debt_payment',
              icon: Icons.arrow_upward_rounded,
              label: 'Debt Payment',
              color: AppColors.error,
            ),
            (
              type: 'goal',
              icon: Icons.flag_outlined,
              label: 'Goal',
              color: AppColors.accent,
            ),
            (
              type: 'subscription',
              icon: Icons.autorenew_rounded,
              label: 'Subscription',
              color: AppColors.info,
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Link To',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.link_off_rounded,
                        color: AppColors.textTertiary,
                        size: 18,
                      ),
                      title: Text(
                        'None',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: textPrimary,
                        ),
                      ),
                      trailing: currentEntityType == null
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.accent,
                            )
                          : null,
                      onTap: () {
                        onSelectNone();
                        Navigator.pop(context);
                      },
                    ),
                    ...types.map(
                      (t) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(t.icon, color: t.color, size: 18),
                        title: Text(
                          t.label,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          entityLinkDescription(t.type, isIncome: isIncome),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: currentEntityType == t.type
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.accent,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          onSelectType(t.type);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionCreateEntityItemSheet extends StatelessWidget {
  final String entityType;
  final DebtController debtController;
  final GoalController goalController;
  final SubscriptionController subController;
  final String? currentDebtId;
  final String? currentGoalId;
  final String? currentSubscriptionId;
  final void Function(String id, String label) onSelect;

  const TransactionCreateEntityItemSheet({
    super.key,
    required this.entityType,
    required this.debtController,
    required this.goalController,
    required this.subController,
    required this.currentDebtId,
    required this.currentGoalId,
    required this.currentSubscriptionId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;

    List<({String id, String label, String amount})> items;
    if (entityType == 'debt_payment' || entityType == 'debt_received') {
      final debtType = entityType == 'debt_received'
          ? DebtType.lending
          : DebtType.borrowing;
      items = (debtController.data ?? [])
          .where((d) => d.type == debtType && d.status != DebtStatus.settled)
          .map(
            (d) => (
              id: d.id!,
              label: d.personName,
              amount: entityType == 'debt_received'
                  ? 'Expecting ${currencyFormatter.format(d.remainingAmount)}'
                  : 'Still owe ${currencyFormatter.format(d.remainingAmount)}',
            ),
          )
          .toList();
    } else if (entityType == 'lending') {
      items = (debtController.data ?? [])
          .where(
            (d) => d.type == DebtType.lending && d.status != DebtStatus.settled,
          )
          .map(
            (d) => (
              id: d.id!,
              label: d.personName,
              amount:
                  'Expecting ${currencyFormatter.format(d.remainingAmount)}',
            ),
          )
          .toList();
    } else if (entityType == 'goal') {
      items = (goalController.data ?? [])
          .where((g) => !g.isCompleted)
          .map(
            (g) => (
              id: g.id!,
              label: g.name,
              amount:
                  '${currencyFormatter.format(g.currentAmount)} of ${currencyFormatter.format(g.targetAmount)} saved',
            ),
          )
          .toList();
    } else {
      items = (subController.data ?? [])
          .map(
            (s) => (
              id: s.id!,
              label: s.name,
              amount: '${currencyFormatter.format(s.amount)} recurring',
            ),
          )
          .toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Text(
                        'No active records to link',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            item.amount,
                            style: GoogleFonts.dmMono(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing:
                              (currentDebtId == item.id ||
                                  currentGoalId == item.id ||
                                  currentSubscriptionId == item.id)
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: AppColors.accent,
                                )
                              : null,
                          onTap: () {
                            onSelect(item.id, item.label);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
