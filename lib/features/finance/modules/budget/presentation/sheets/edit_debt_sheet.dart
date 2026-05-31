import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_toast.dart';

import '../../../debt/domain/entities/debt.dart';

class EditDebtSheet extends StatefulWidget {
  final Debt debt;
  final Future<void> Function(Debt updated) onSave;

  const EditDebtSheet({super.key, required this.debt, required this.onSave});

  @override
  State<EditDebtSheet> createState() => _EditDebtSheetState();
}

class _EditDebtSheetState extends State<EditDebtSheet> {
  late final TextEditingController _personCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _monthlyCtrl;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _personCtrl = TextEditingController(text: d.personName);
    _descCtrl = TextEditingController(text: d.description);
    _monthlyCtrl = TextEditingController(
      text: d.monthlyPaymentAmount > 0
          ? d.monthlyPaymentAmount.toStringAsFixed(2)
          : '',
    );
    _dueDate = d.dueDate;
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _descCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _personCtrl.text.trim();
    if (name.isEmpty) {
      AppToast.error(context, 'Enter a person name');
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = widget.debt.copyWith(
        personName: name,
        description: _descCtrl.text.trim(),
        monthlyPaymentAmount:
            double.tryParse(_monthlyCtrl.text) ??
            widget.debt.monthlyPaymentAmount,
        dueDate: _dueDate,
      );
      await widget.onSave(updated);
      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, widget.debt.type == DebtType.lending ? 'Receivable updated!' : 'Debt updated!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: $e');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceivable = widget.debt.type == DebtType.lending;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isReceivable ? 'Edit Receivable' : 'Edit Debt',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 20),

              // Person name
              TextField(
                controller: _personCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: isReceivable ? 'Borrower Name' : 'Lender Name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Monthly payment
              TextField(
                controller: _monthlyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: isReceivable
                      ? 'Expected Monthly (optional)'
                      : 'Monthly Payment (optional)',
                  border: const OutlineInputBorder(),
                  prefixText: '₱ ',
                  helperText: 'Fixed amount expected each month',
                ),
              ),
              const SizedBox(height: 12),

              // Due date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date (optional)'),
                subtitle: Text(
                  _dueDate != null
                      ? DateFormat('MMM d, yyyy').format(_dueDate!)
                      : 'Not set',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _dueDate = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (d != null) setState(() => _dueDate = d);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isReceivable ? 'Save Receivable' : 'Save Debt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
