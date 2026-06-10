import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class CreateTransactionAmountField extends StatelessWidget {
  final TextEditingController controller;
  final double amount;
  final Color typeColor;
  final VoidCallback onChanged;

  const CreateTransactionAmountField({
    super.key,
    required this.controller,
    required this.amount,
    required this.typeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            currencyFormatter.currencySymbol,
            style: GoogleFonts.dmMono(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              onChanged: (_) => onChanged(),
              style: GoogleFonts.dmMono(
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: amount > 0 ? typeColor : AppColors.textTertiary,
                letterSpacing: -1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: GoogleFonts.dmMono(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: -1,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: typeColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
