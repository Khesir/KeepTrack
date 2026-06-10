import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';

class SplitEntryWalletPickerSheet extends StatelessWidget {
  final bool isDark;
  final List<Wallet> wallets;
  final String? selectedWalletId;
  final void Function(Wallet wallet) onSelect;

  const SplitEntryWalletPickerSheet({
    super.key,
    required this.isDark,
    required this.wallets,
    required this.selectedWalletId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),
          Text(
            'Wallet',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...wallets.map(
            (w) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.accent,
                size: 18,
              ),
              title: Text(
                w.name,
                style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary),
              ),
              subtitle: Text(
                currencyFormatter.format(w.balance),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: selectedWalletId == w.id
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.accent,
                    )
                  : null,
              onTap: () {
                onSelect(w);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SplitEntryProfilePickerSheet extends StatelessWidget {
  final bool isDark;
  final List<BudgetProfile> profiles;
  final List<MonthPlan> plans;
  final String? selectedProfileId;
  final void Function(String profileId, String label) onSelect;

  const SplitEntryProfilePickerSheet({
    super.key,
    required this.isDark,
    required this.profiles,
    required this.plans,
    required this.selectedProfileId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    final items = <({String label, String profileId})>[];
    for (final p in profiles) {
      if (!p.isActive) continue;
      if (p.isMonthly) {
        final profilePlans = plans
            .where(
              (pl) =>
                  pl.budgetProfileId == p.id &&
                  !pl.isClosed &&
                  pl.month != null,
            )
            .toList();
        if (profilePlans.isEmpty) {
          items.add((label: p.name, profileId: p.id!));
        } else {
          for (final pl in profilePlans) {
            final dt = DateTime.tryParse('${pl.month!}-01');
            final label = dt != null
                ? '${p.name} – ${DateFormat('MMM yyyy').format(dt)}'
                : p.name;
            items.add((label: label, profileId: p.id!));
          }
        }
      } else {
        items.add((label: p.name, profileId: p.id!));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),
          Text(
            'Budget',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.accent,
                size: 18,
              ),
              title: Text(
                item.label,
                style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary),
              ),
              trailing: selectedProfileId == item.profileId
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.accent,
                    )
                  : null,
              onTap: () {
                onSelect(item.profileId, item.label);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
