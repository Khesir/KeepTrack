import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/settings/presentation/settings_controller.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';

import '../../../../../modules/planned_payment/domain/entities/payment_enums.dart';

class PlannedPaymentManagementDialog extends StatefulWidget {
  final PlannedPayment? payment;
  final String userId;
  final Function(PlannedPayment) onSave;

  const PlannedPaymentManagementDialog({
    this.payment,
    required this.userId,
    required this.onSave,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _PlannedPaymentManagementDialogState();
}

class _PlannedPaymentManagementDialogState
    extends State<PlannedPaymentManagementDialog> {
  late final TextEditingController nameController;
  late final TextEditingController payeeController;
  late final TextEditingController amountController;
  late final TextEditingController notesController;

  late DateTime selectedNextPaymentDate;
  DateTime? selectedEndDate;
  late PaymentCategory selectedCategory;
  late PaymentFrequency selectedFrequency;
  late PaymentStatus selectedStatus;

  bool _isSaving = false;
  bool get isEdit => widget.payment != null;

  @override
  void initState() {
    super.initState();
    final p = widget.payment;
    nameController = TextEditingController(text: p?.name ?? '');
    payeeController = TextEditingController(text: p?.payee ?? '');
    amountController = TextEditingController(text: p?.amount.toString() ?? '');
    notesController = TextEditingController(text: p?.notes ?? '');

    selectedNextPaymentDate = p?.nextPaymentDate ?? DateTime.now();
    selectedEndDate = p?.endDate;
    selectedCategory = p?.category ?? PaymentCategory.bills;
    selectedFrequency = p?.frequency ?? PaymentFrequency.monthly;
    selectedStatus = p?.status ?? PaymentStatus.active;
  }

  @override
  void dispose() {
    nameController.dispose();
    payeeController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    if (_isSaving) return; // Prevent double-submit

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a payment name')),
      );
      return;
    }
    if (payeeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a payee')));
      return;
    }
    if (amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.tryParse(amountController.text) ?? 0;

      final paymentEntity = PlannedPayment(
        id: widget.payment?.id,
        name: nameController.text.trim(),
        payee: payeeController.text.trim(),
        amount: amount,
        category: selectedCategory,
        frequency: selectedFrequency,
        nextPaymentDate: selectedNextPaymentDate,
        endDate: selectedEndDate,
        status: selectedStatus,
        notes: notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null,
        userId: widget.userId,
      );

      widget.onSave(paymentEntity);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get currency symbol from settings
    final settingsController = locator.get<SettingsController>();
    final currencySymbol = settingsController.data?.currency.symbol ?? '₱';

    return AlertDialog(
      title: Text(isEdit ? 'Edit Planned Payment' : 'Create Planned Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Payment Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Payee
            TextField(
              controller: payeeController,
              decoration: const InputDecoration(
                labelText: 'Payee',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Amount
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: const OutlineInputBorder(),
                prefixText: '$currencySymbol ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            // Category
            DropdownButtonFormField<PaymentCategory>(
              value: selectedCategory,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: PaymentCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.label), // use extension helper
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Frequency
            DropdownButtonFormField<PaymentFrequency>(
              value: selectedFrequency,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: PaymentFrequency.values.map((frequency) {
                return DropdownMenuItem(
                  value: frequency,
                  child: Text(frequency.name), // use extension helper
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedFrequency = value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Next payment date - make whole tile clickable
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedNextPaymentDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) {
                  setState(() => selectedNextPaymentDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Next Payment Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${selectedNextPaymentDate.year}-${selectedNextPaymentDate.month.toString().padLeft(2, '0')}-${selectedNextPaymentDate.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            // End date (optional)
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedEndDate ?? selectedNextPaymentDate.add(const Duration(days: 365)),
                  firstDate: selectedNextPaymentDate,
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) {
                  setState(() => selectedEndDate = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'End Date (Optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: selectedEndDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => selectedEndDate = null);
                          },
                        )
                      : const Icon(Icons.calendar_today),
                ),
                child: Text(
                  selectedEndDate != null
                      ? '${selectedEndDate!.year}-${selectedEndDate!.month.toString().padLeft(2, '0')}-${selectedEndDate!.day.toString().padLeft(2, '0')}'
                      : 'No end date - continues indefinitely',
                  style: TextStyle(
                    color: selectedEndDate != null
                        ? null
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Status
            SegmentedButton<PaymentStatus>(
              segments: const [
                ButtonSegment(
                  value: PaymentStatus.active,
                  label: Text('Active'),
                ),
                ButtonSegment(
                  value: PaymentStatus.paused,
                  label: Text('Paused'),
                ),
                ButtonSegment(
                  value: PaymentStatus.cancelled,
                  label: Text('Cancelled'),
                ),
              ],
              selected: {selectedStatus},
              onSelectionChanged: (newSelection) {
                setState(() => selectedStatus = newSelection.first);
              },
            ),
            const SizedBox(height: 16),
            // Notes
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _savePayment,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
