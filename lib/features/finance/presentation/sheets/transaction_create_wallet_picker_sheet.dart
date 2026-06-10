import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';

class TransactionCreateWalletPickerSheet extends StatelessWidget {
  final bool isDark;
  final List<Wallet> wallets;
  final TransactionType type;
  final String? selectedWalletId;
  final void Function(Wallet wallet) onSelect;

  const TransactionCreateWalletPickerSheet({
    super.key,
    required this.isDark,
    required this.wallets,
    required this.type,
    required this.selectedWalletId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
              child: Text(
                'Select Wallet',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                type == TransactionType.income
                    ? 'The amount will be added to the selected wallet.'
                    : 'The amount will be deducted from the selected wallet.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (wallets.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Text(
                  'No wallets yet. Create one in the Wallet tab.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: wallets.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: borderColor,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (_, i) {
                    final w = wallets[i];
                    final sel = selectedWalletId == w.id;
                    final wColor = w.colorHex != null
                        ? Color(
                            int.parse(w.colorHex!.replaceFirst('#', '0xff')),
                          )
                        : AppColors.accent;
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: wColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          w.type == WalletType.creditCard
                              ? Icons.credit_card_outlined
                              : Icons.account_balance_wallet_outlined,
                          size: 16,
                          color: wColor,
                        ),
                      ),
                      title: Text(
                        w.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: fg,
                        ),
                      ),
                      subtitle: Text(
                        '${currencyFormatter.format(w.balance, decimalDigits: 2)} • ${w.type.displayName}',
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: sel
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
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
