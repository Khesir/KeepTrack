import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../debt/domain/entities/debt.dart';
import '../helpers/currency_formatter.dart';

class DebtRow extends StatefulWidget {
  final Debt debt;
  final bool isReceivable;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final Future<void> Function(double) onUpdateMonthlyPayment;

  const DebtRow({
    super.key,
    required this.debt,
    required this.isReceivable,
    required this.isSelected,
    required this.onSelect,
    required this.onPay,
    required this.onEdit,
    required this.onUpdateMonthlyPayment,
  });

  @override
  State<DebtRow> createState() => _DebtRowState();
}

class _DebtRowState extends State<DebtRow> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _amountCtrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.debt.monthlyPaymentAmount.toStringAsFixed(2),
    );
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(DebtRow old) {
    super.didUpdateWidget(old);
    if (!_editing &&
        old.debt.monthlyPaymentAmount != widget.debt.monthlyPaymentAmount) {
      _amountCtrl.text = widget.debt.monthlyPaymentAmount.toStringAsFixed(2);
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
    if (!_focusNode.hasFocus && _editing) _commitEdit();
  }

  void _startEdit() => setState(() {
    _editing = true;
    _amountCtrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _amountCtrl.text.length,
    );
  });

  Future<void> _commitEdit() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount < 0 || amount == widget.debt.monthlyPaymentAmount) {
      _amountCtrl.text = widget.debt.monthlyPaymentAmount.toStringAsFixed(2);
      if (mounted) setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onUpdateMonthlyPayment(amount);
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
    final theme = Theme.of(context);
    final d = widget.debt;

    return Material(
      color: widget.isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.07)
          : Colors.transparent,
      child: InkWell(
        onTap: widget.onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              // Name + overdue
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.personName,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: widget.isSelected
                            ? theme.colorScheme.primary
                            : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (d.isOverdue)
                      Text(
                        'Overdue',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                  ],
                ),
              ),
              // Balance
              SizedBox(
                width: 70,
                child: Text(
                  formatCurrency(d.remainingAmount),
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Planned — tap to edit (absorb tap so row select doesn't fire)
              GestureDetector(
                onTap: _editing ? null : _startEdit,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 70,
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
                              borderSide: const BorderSide(
                                color: AppColors.accent,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: AppColors.accent,
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
                          formatCurrency(d.monthlyPaymentAmount),
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.dotted,
                            decorationColor: AppColors.textTertiary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              // Paid
              SizedBox(
                width: 70,
                child: Text(
                  formatCurrency(d.paidAmount),
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),

              const SizedBox(width: 4),
              // Pay / Collect button
              if (d.status == DebtStatus.active)
                SizedBox(
                  height: 28,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: widget.onPay,
                    child: Text(
                      widget.isReceivable ? 'Collect' : 'Pay',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isReceivable
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 46),
            ],
          ),
        ),
      ),
    );
  }
}
