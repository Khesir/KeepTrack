import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/widgets/create_transaction_chips.dart';

class CreateTransactionChipsRow extends StatelessWidget {
  final bool isDark;
  final bool isPlan;
  final bool showDesc;
  final VoidCallback onToggleDesc;
  final String? selectedProfileName;
  final String? selectedProfileId;
  final VoidCallback onPickProfile;
  final FinanceCategory? category;
  final bool categoryError;
  final String? entityType;
  final Color typeColor;
  final VoidCallback onPickCategory;
  final Wallet? selectedWallet;
  final bool walletError;
  final VoidCallback onPickWallet;
  final List<String> imagePaths;
  final VoidCallback onPickImage;
  final String? entityLabel;
  final VoidCallback onPickEntity;
  final String dateLabel;
  final bool isToday;
  final VoidCallback onPickDate;

  const CreateTransactionChipsRow({
    super.key,
    required this.isDark,
    required this.isPlan,
    required this.showDesc,
    required this.onToggleDesc,
    required this.selectedProfileName,
    required this.selectedProfileId,
    required this.onPickProfile,
    required this.category,
    required this.categoryError,
    required this.entityType,
    required this.typeColor,
    required this.onPickCategory,
    required this.selectedWallet,
    required this.walletError,
    required this.onPickWallet,
    required this.imagePaths,
    required this.onPickImage,
    required this.entityLabel,
    required this.onPickEntity,
    required this.dateLabel,
    required this.isToday,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.start,
        children: [
          if (!isPlan)
            TransactionTypeChip(
              icon: showDesc ? Icons.edit_off_outlined : Icons.edit_outlined,
              label: 'Note',
              color: showDesc ? AppColors.accent : AppColors.textSecondary,
              isDark: isDark,
              onTap: onToggleDesc,
            ),
          TransactionTypeChip(
            icon: Icons.account_balance_wallet_outlined,
            label: selectedProfileName ?? 'Budget',
            color: selectedProfileId != null
                ? AppColors.accent
                : AppColors.textSecondary,
            isDark: isDark,
            highlighted: false,
            onTap: onPickProfile,
          ),
          if (entityType == null)
            TransactionTypeChip(
              icon: category == null ? Icons.grid_view_rounded : null,
              label: category?.name ?? 'Category',
              color: categoryError
                  ? AppColors.error
                  : (category != null ? typeColor : AppColors.textSecondary),
              isDark: isDark,
              highlighted: categoryError,
              onTap: onPickCategory,
            ),
          TransactionTypeChip(
            icon: selectedWallet == null
                ? Icons.account_balance_wallet_outlined
                : (selectedWallet!.type == WalletType.creditCard
                      ? Icons.credit_card_outlined
                      : Icons.account_balance_wallet_outlined),
            label: selectedWallet?.name ?? 'Wallet *',
            color: walletError
                ? AppColors.error
                : (selectedWallet != null
                      ? AppColors.accent
                      : AppColors.textSecondary),
            isDark: isDark,
            highlighted: walletError,
            onTap: onPickWallet,
          ),
          if (!isPlan)
            TransactionTypeChip(
              icon: Icons.attach_file_rounded,
              label: imagePaths.isEmpty
                  ? 'Attach'
                  : 'Files (${imagePaths.length})',
              color: imagePaths.isNotEmpty
                  ? AppColors.accent
                  : AppColors.textSecondary,
              isDark: isDark,
              onTap: onPickImage,
            ),
          if (!isPlan)
            TransactionTypeChip(
              icon: entityType != null
                  ? Icons.link_rounded
                  : Icons.link_outlined,
              label: entityLabel ?? 'Link',
              color: entityType != null
                  ? AppColors.success
                  : AppColors.textSecondary,
              isDark: isDark,
              highlighted: entityType != null,
              onTap: onPickEntity,
            ),
          TransactionTypeChip(
            icon: Icons.calendar_today_outlined,
            label: dateLabel,
            color: isToday ? AppColors.textSecondary : AppColors.accent,
            isDark: isDark,
            onTap: onPickDate,
          ),
        ],
      ),
    );
  }
}
