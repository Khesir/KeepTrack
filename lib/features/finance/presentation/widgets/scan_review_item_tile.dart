import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import '../helpers/editable_scan_item.dart';
import 'scan_widgets.dart';

class ScanReviewItemTile extends StatefulWidget {
  final EditableScanItem item;
  final bool isDark;
  final String currencySymbol;
  final VoidCallback onChanged;
  final VoidCallback onPickProfile;
  final VoidCallback onPickCategory;
  final VoidCallback onPickWallet;
  final VoidCallback? onPickEntity;

  const ScanReviewItemTile({
    super.key,
    required this.item,
    required this.isDark,
    required this.currencySymbol,
    required this.onChanged,
    required this.onPickProfile,
    required this.onPickCategory,
    required this.onPickWallet,
    this.onPickEntity,
  });

  @override
  State<ScanReviewItemTile> createState() => _ScanReviewItemTileState();
}

class _ScanReviewItemTileState extends State<ScanReviewItemTile> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;

  IconData _entityIcon(String type) => switch (type) {
    'subscription' => Icons.autorenew_rounded,
    'debt_payment' => Icons.arrow_upward_rounded,
    'lending'      => Icons.arrow_downward_rounded,
    'goal'         => Icons.flag_outlined,
    _              => Icons.link_rounded,
  };

  String _entityPlaceholder(String type, String? hint) {
    final suffix = hint != null ? ' ($hint)' : '';
    return switch (type) {
      'subscription' => 'Link Subscription$suffix',
      'debt_payment' => 'Link Debt$suffix',
      'lending'      => 'Link Receivable$suffix',
      'goal'         => 'Link Goal$suffix',
      _              => 'Link Entity',
    };
  }

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.item.description);
    _amountCtrl = TextEditingController(text: widget.item.amount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.item.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        widget.item.date = picked;
        if (widget.item.isMonthlyProfile && widget.item.profileBaseName != null) {
          widget.item.profileName = '${widget.item.profileBaseName!} · ${DateFormat('MMM yyyy').format(picked)}';
        }
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final item = widget.item;
    final borderColor = item.included
        ? AppColors.accent.withValues(alpha: 0.35)
        : AppColors.border.withValues(alpha: isDark ? 0.15 : 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final typeColor = item.type == TransactionType.income ? AppColors.success : AppColors.error;

    return AnimatedOpacity(
      opacity: item.included ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 160),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.included ? borderColor : AppColors.border.withValues(alpha: isDark ? 0.1 : 0.3),
            width: 0.5,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row: checkbox + description + amount + type toggle
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: item.included,
                onChanged: (v) { setState(() => item.included = v ?? true); widget.onChanged(); },
                activeColor: AppColors.accent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _descCtrl,
                enabled: item.included,
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  border: InputBorder.none,
                  hintText: 'Description',
                  hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary),
                ),
                onChanged: (v) => item.description = v,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _amountCtrl,
                enabled: item.included,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w700, color: typeColor),
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                onChanged: (v) => item.amount = double.tryParse(v) ?? item.amount,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: item.included ? () { setState(() { item.type = item.type == TransactionType.income ? TransactionType.expense : TransactionType.income; }); widget.onChanged(); } : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    item.type == TransactionType.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    size: 11, color: typeColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    item.type == TransactionType.income ? 'In' : 'Out',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: typeColor),
                  ),
                ]),
              ),
            ),
          ]),

          if (item.included) ...[
            const SizedBox(height: 8),
            // Chips row
            Wrap(spacing: 5, runSpacing: 5, children: [
              ScanChipButton(
                icon: Icons.account_balance_wallet_outlined,
                label: item.profileName ?? 'Budget',
                color: item.profileName != null ? AppColors.accent : AppColors.error,
                isDark: isDark,
                onTap: widget.onPickProfile,
              ),
              ScanChipButton(
                icon: Icons.category_outlined,
                label: item.category?.name ?? 'Category',
                color: item.category != null ? AppColors.textSecondary : AppColors.warning,
                isDark: isDark,
                onTap: widget.onPickCategory,
              ),
              ScanChipButton(
                icon: Icons.account_balance_wallet_outlined,
                label: item.walletName ?? 'Wallet',
                color: item.walletId != null ? AppColors.accent : AppColors.warning,
                isDark: isDark,
                onTap: widget.onPickWallet,
              ),
              ScanChipButton(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('MMM d').format(item.date),
                color: AppColors.textSecondary,
                isDark: isDark,
                onTap: _pickDate,
              ),
              ScanChipButton(
                icon: item.entityType != null ? _entityIcon(item.entityType!) : Icons.link_rounded,
                label: item.entityLabel != null
                    ? item.entityLabel!
                    : item.entityType != null
                        ? _entityPlaceholder(item.entityType!, item.entityHint)
                        : 'Link',
                color: item.entityLabel != null ? AppColors.success : item.entityType != null ? AppColors.error : AppColors.textSecondary,
                isDark: isDark,
                onTap: widget.onPickEntity,
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
