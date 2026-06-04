import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'sheet_helpers.dart';

class AddDebtSheet extends StatefulWidget {
  final bool isReceivable;
  final Future<void> Function(Debt debt) onSave;
  final Debt? initialDebt;

  const AddDebtSheet({
    super.key,
    required this.isReceivable,
    required this.onSave,
    this.initialDebt,
  });

  @override
  State<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<AddDebtSheet> {
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();
  late final DebtType _type;
  DateTime? _dueDate;
  bool _saving = false;

  bool get _isEditing => widget.initialDebt != null;

  @override
  void initState() {
    super.initState();
    _type = widget.isReceivable ? DebtType.lending : DebtType.borrowing;
    if (_isEditing) {
      final d = widget.initialDebt!;
      _personCtrl.text = d.personName;
      _descCtrl.text = d.description;
      _monthlyCtrl.text = d.monthlyPaymentAmount > 0 ? d.monthlyPaymentAmount.toStringAsFixed(2) : '';
      _dueDate = d.dueDate;
    }
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  bool get _isReceivable => _type == DebtType.lending;
  Color get _typeColor => _isReceivable ? AppColors.success : AppColors.error;
  bool get _canSave {
    if (_isEditing) return _personCtrl.text.trim().isNotEmpty;
    return _personCtrl.text.trim().isNotEmpty &&
        (double.tryParse(_amountCtrl.text) ?? 0) > 0;
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    try {
      final Debt debt;
      if (_isEditing) {
        final d = widget.initialDebt!;
        debt = Debt(
          id: d.id,
          type: d.type,
          personName: _personCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          originalAmount: d.originalAmount,
          remainingAmount: d.remainingAmount,
          startDate: d.startDate,
          dueDate: _dueDate,
          status: d.status,
          notes: d.notes,
          createdAt: d.createdAt,
          updatedAt: DateTime.now(),
          settledAt: d.settledAt,
          userId: d.userId,
          transactionId: d.transactionId,
          monthlyPaymentAmount: double.tryParse(_monthlyCtrl.text) ?? 0,
          feeAmount: d.feeAmount,
          nextPaymentDate: d.nextPaymentDate,
          paymentFrequency: d.paymentFrequency,
          budgetProfileId: d.budgetProfileId,
        );
      } else {
        debt = Debt(
          type: _type,
          personName: _personCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          originalAmount: double.parse(_amountCtrl.text),
          remainingAmount: double.parse(_amountCtrl.text),
          startDate: DateTime.now(),
          dueDate: _dueDate,
          monthlyPaymentAmount: double.tryParse(_monthlyCtrl.text) ?? 0,
        );
      }
      await widget.onSave(debt);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pickDate(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SheetCalendar(
        isDark: isDark,
        selected: _dueDate,
        onSelect: (d) {
          setState(() => _dueDate = d);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final textPrimary =
        isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, ctrl) => Column(children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.account_balance_outlined,
                      size: 18, color: _typeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEditing
                        ? (_isReceivable ? 'Edit Receivable' : 'Edit Debt')
                        : (_isReceivable ? 'New Receivable' : 'New Debt'),
                    style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ]),
            ),
            Divider(height: 20, color: border),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  SheetLabel(_isReceivable ? 'Borrower Name *' : 'Lender / Person *'),
                  SheetField(
                    ctrl: _personCtrl,
                    hint: 'Full name',
                    isDark: isDark,
                    autofocus: true,
                    capitalize: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing) ...[
                    SheetLabel('Amount *'),
                    SheetField(
                      ctrl: _amountCtrl,
                      hint: '0.00',
                      prefix: '${currencyFormatter.currencySymbol} ',
                      isDark: isDark,
                      numeric: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SheetLabel('Monthly Payment (optional)'),
                  SheetField(
                    ctrl: _monthlyCtrl,
                    hint: '0.00 – pre-fills payment drawer',
                    prefix: '${currencyFormatter.currencySymbol} ',
                    isDark: isDark,
                    numeric: true,
                  ),
                  const SizedBox(height: 16),
                  SheetLabel('Due Date (optional)'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickDate(isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: border, width: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dueDate != null
                                ? DateFormat('MMMM d, yyyy').format(_dueDate!)
                                : 'No due date',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: _dueDate != null
                                  ? textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (_dueDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _dueDate = null),
                            child: Icon(Icons.close_rounded,
                                size: 14, color: AppColors.textTertiary),
                          )
                        else
                          Icon(Icons.chevron_right_rounded,
                              size: 16, color: AppColors.textTertiary),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SheetLabel('Notes (optional)'),
                  SheetField(
                      ctrl: _descCtrl,
                      hint: 'Add a note…',
                      isDark: isDark,
                      maxLines: 2),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canSave && !_saving ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canSave ? _typeColor : AppColors.textTertiary,
                        foregroundColor: AppColors.textPrimaryDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isEditing
                                  ? 'Save Changes'
                                  : (_isReceivable ? 'Add Receivable' : 'Add Debt'),
                              style: GoogleFonts.dmSans(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
