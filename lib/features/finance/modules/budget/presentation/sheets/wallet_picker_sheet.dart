import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';

class WalletPickerSheet extends StatelessWidget {
  final bool isDark;
  final List<Wallet> wallets;
  final String? selectedWalletId;
  final ValueChanged<Wallet> onSelect;

  const WalletPickerSheet({
    super.key,
    required this.isDark,
    required this.wallets,
    required this.selectedWalletId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
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
              child: Text('Select Wallet',
                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: wallets.length,
                itemBuilder: (_, i) {
                  final w = wallets[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.account_balance_wallet_outlined,
                        size: 18, color: AppColors.textSecondary),
                    title: Text(w.name,
                        style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary)),
                    subtitle: Text(currencyFormatter.format(w.balance),
                        style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: selectedWalletId == w.id
                        ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent)
                        : null,
                    onTap: () {
                      onSelect(w);
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
