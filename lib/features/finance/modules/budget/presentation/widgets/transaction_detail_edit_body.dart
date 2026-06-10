import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import '../sheets/entity_link_picker_sheet.dart';
import '../sheets/sheet_helpers.dart';
import 'transaction_detail_attachments.dart';

class TransactionDetailEditBody extends StatelessWidget {
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final bool isTransfer;
  final TextEditingController descController;
  final DateTime editDate;
  final VoidCallback onPickDate;
  final FinanceCategory? editCategory;
  final VoidCallback onCategoryTap;
  final String? editProfileId;
  final String? editProfileName;
  final VoidCallback onProfileTap;
  final String? editEntityType;
  final String? editEntityLabel;
  final VoidCallback onEntityTap;
  final String? editWalletId;
  final String? editToWalletId;
  final List<String> editImagePaths;
  final String transactionId;
  final VoidCallback onAttachmentsChanged;
  final bool loading;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const TransactionDetailEditBody({
    super.key,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.isTransfer,
    required this.descController,
    required this.editDate,
    required this.onPickDate,
    required this.editCategory,
    required this.onCategoryTap,
    required this.editProfileId,
    required this.editProfileName,
    required this.onProfileTap,
    required this.editEntityType,
    required this.editEntityLabel,
    required this.onEntityTap,
    required this.editWalletId,
    required this.editToWalletId,
    required this.editImagePaths,
    required this.transactionId,
    required this.onAttachmentsChanged,
    required this.loading,
    required this.onSave,
    required this.onCancel,
  });

  Widget _buildTransferWalletRow(Color chipBg, Color chipBorder) {
    final wallets = locator.get<WalletController>().data ?? [];
    final fromWallet = wallets.where((w) => w.id == editWalletId).firstOrNull;
    final toWallet = wallets.where((w) => w.id == editToWalletId).firstOrNull;

    Widget walletChip(Wallet? wallet, String fallback) {
      final wColor = wallet?.colorHex != null
          ? Color(int.parse(wallet!.colorHex!.replaceFirst('#', '0xff')))
          : AppColors.info;
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: wallet != null ? AppColors.info.withValues(alpha: 0.4) : chipBorder, width: 0.5),
          ),
          child: Row(children: [
            Icon(
              wallet?.type == WalletType.creditCard ? Icons.credit_card_outlined : Icons.account_balance_wallet_outlined,
              size: 14, color: wallet != null ? wColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(
              wallet?.name ?? fallback,
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500,
                  color: wallet != null ? textPrimary : AppColors.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          walletChip(fromWallet, 'From wallet'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.info)),
          ),
          walletChip(toWallet, 'To wallet'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chipBg = isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.background;
    final chipBorder = isDark ? AppColors.border.withValues(alpha: 0.25) : AppColors.border.withValues(alpha: 0.6);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Description
      TextField(
        controller: descController,
        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 12),

      // Date
      GestureDetector(
        onTap: onPickDate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(4)),
          child: Row(children: [
            Expanded(child: Text(DateFormat('MMMM d, yyyy').format(editDate),
                style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary))),
            Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
          ]),
        ),
      ),
      const SizedBox(height: 12),

      if (isTransfer) ...[
        // Transfer: show from/to wallets (read-only)
        _buildTransferWalletRow(chipBg, chipBorder),
        const SizedBox(height: 8),
      ] else ...[
        // Category picker
        GestureDetector(
          onTap: onCategoryTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: editCategory != null ? AppColors.accent.withValues(alpha: 0.4) : chipBorder, width: 0.5),
            ),
            child: Row(children: [
              Icon(Icons.category_outlined, size: 16,
                  color: editCategory != null ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(child: Text(
                editCategory?.name ?? 'Select Category',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500,
                    color: editCategory != null ? textPrimary : AppColors.textSecondary),
              )),
              Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
            ]),
          ),
        ),
        const SizedBox(height: 8),

        // Budget profile picker
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: editProfileId != null ? AppColors.accent.withValues(alpha: 0.4) : chipBorder, width: 0.5),
            ),
            child: Row(children: [
              Icon(Icons.account_balance_wallet_outlined, size: 16,
                  color: editProfileId != null ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(child: Text(
                editProfileName ?? 'No Budget Profile',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500,
                    color: editProfileId != null ? textPrimary : AppColors.textSecondary),
              )),
              Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
            ]),
          ),
        ),
        const SizedBox(height: 8),

        // Entity link picker
        GestureDetector(
          onTap: onEntityTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: editEntityLabel != null ? AppColors.success.withValues(alpha: 0.4) : chipBorder, width: 0.5),
            ),
            child: Row(children: [
              Icon(editEntityType != null ? EntityLinkPickerSheet.entityIcon(editEntityType!) : Icons.link_rounded,
                  size: 16, color: editEntityLabel != null ? AppColors.success : AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(child: Text(
                editEntityLabel ?? 'Link Entity (optional)',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500,
                    color: editEntityLabel != null ? textPrimary : AppColors.textSecondary),
              )),
              Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
            ]),
          ),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 12),
      TransactionDetailAttachmentEditor(
        imagePaths: editImagePaths,
        transactionId: transactionId,
        onChanged: onAttachmentsChanged,
      ),
      const SizedBox(height: 12),
      SheetActionButton(label: 'Save Changes', icon: Icons.check_rounded, color: AppColors.accent, loading: loading, onTap: onSave),
      const SizedBox(height: 8),
      SheetActionButton(label: 'Cancel', icon: Icons.close_rounded, color: AppColors.textSecondary,
          outlined: true, isDark: isDark, onTap: onCancel),
    ]);
  }
}
