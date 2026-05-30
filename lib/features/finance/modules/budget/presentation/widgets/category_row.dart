import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../domain/entities/budget_category.dart';
import '../helpers/currency_formatter.dart';

class CategoryRow extends StatefulWidget {
  final BudgetCategory category;
  final double spentAmount;
  final bool isIncomeGroup;
  final Color accentColor;
  final VoidCallback onDetailTap;
  final VoidCallback onEditTap;
  final Future<void> Function(double) onUpdateAmount;
  final Future<void> Function(double)? onPay;

  const CategoryRow({
    super.key,
    required this.category,
    required this.spentAmount,
    required this.isIncomeGroup,
    required this.accentColor,
    required this.onDetailTap,
    required this.onEditTap,
    required this.onUpdateAmount,
    this.onPay,
  });

  @override
  State<CategoryRow> createState() => CategoryRowState();
}

class CategoryRowState extends State<CategoryRow> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _amountCtrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.category.targetAmount.toStringAsFixed(2),
    );
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(CategoryRow old) {
    super.didUpdateWidget(old);
    // Sync display when the stream updates the category (but not while editing)
    if (!_editing &&
        old.category.targetAmount != widget.category.targetAmount) {
      _amountCtrl.text = widget.category.targetAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      _commitEdit();
    }
  }

  void _startEdit() => setState(() {
    _editing = true;
    _amountCtrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _amountCtrl.text.length,
    );
  });

  Future<void> _showPayDialog() async {
    final ctrl = TextEditingController();
    final name = widget.category.financeCategory?.name ?? 'Category';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay — $name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '${formatCurrency(0).substring(0, 1)} ',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text);
              if (amount == null || amount <= 0) return;
              Navigator.pop(ctx);
              await widget.onPay!(amount);
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _commitEdit() async {
    final amount = double.tryParse(_amountCtrl.text);
    // Revert if invalid or unchanged
    if (amount == null ||
        amount < 0 ||
        amount == widget.category.targetAmount) {
      _amountCtrl.text = widget.category.targetAmount.toStringAsFixed(2);
      if (mounted) setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onUpdateAmount(amount);
    } finally {
      if (mounted) {
        setState(() {
          _editing = false;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final planned = widget.category.targetAmount;
    final actual = widget.spentAmount;
    final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0;
    final isOver = actual > planned;
    final isIncome = widget.isIncomeGroup;
    final overColor = isIncome ? AppColors.success : AppColors.error;
    final progressColor = isOver
        ? overColor
        : progress > 0.85 && !isIncome
        ? AppColors.warning
        : widget.accentColor;

    return InkWell(
      onTap: widget.onDetailTap,
      onLongPress: widget.onEditTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category name
                Expanded(
                  child: Text(
                    widget.category.financeCategory?.name ?? '—',
                    style: AppTextStyles.bodySmall.copyWith(color: textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Planned amount — tap to edit inline
                GestureDetector(
                  onTap: _editing ? null : _startEdit,
                  child: SizedBox(
                    width: 80,
                    child: _editing
                        ? TextField(
                            controller: _amountCtrl,
                            focusNode: _focusNode,
                            autofocus: true,
                            textAlign: TextAlign.right,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: widget.accentColor,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: widget.accentColor,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: _saving
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _commitEdit(),
                          )
                        : Text(
                            formatCurrency(planned),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.dmMono(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.dotted,
                              decorationColor: AppColors.textTertiary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 8),

                // Actual amount (read-only)
                SizedBox(
                  width: 72,
                  child: Text(
                    formatCurrency(actual),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isOver
                          ? overColor
                          : actual > 0
                          ? textPrimary
                          : AppColors.textTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),

                // Fixed right spacer — same width as group header's edit+drag area
                // so Planned/Spent columns stay aligned across header and all rows.
                if (widget.onPay != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _showPayDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.accentColor.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Text(
                        'Pay',
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: widget.accentColor),
                      ),
                    ),
                  ),
                ] else
                  const SizedBox(width: 52),
              ],
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 3,
                  backgroundColor: AppColors.textTertiary.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
