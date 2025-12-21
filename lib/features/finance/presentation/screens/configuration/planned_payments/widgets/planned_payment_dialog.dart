import 'package:flutter/material.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';

import '../../../../../modules/planned_payment/domain/entities/payment_enums.dart';

class PlannedPaymentDialog extends StatefulWidget {
  final PlannedPayment? payment;
  final String userId;
  final Function(PlannedPayment) onSave;

  const PlannedPaymentDialog({
    this.payment,
    required this.userId,
    required this.onSave,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _PlannedPaymentDialogState();
}

class _PlannedPaymentDialogState extends State<PlannedPaymentDialog> {
  late final TextEditingController nameController;
  late final TextEditingController payeeController;
  late final TextEditingController amountController;
  late final TextEditingController notesController;

  late DateTime selectedNextPaymentDate;
  late PaymentCategory selectedCategory;
  late PaymentFrequency selectedFrequency;
  late PaymentStatus selectedStatus;

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

  void _savePayment() {
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

    final amount = double.tryParse(amountController.text) ?? 0;

    final paymentEntity = PlannedPayment(
      id: widget.payment?.id,
      name: nameController.text.trim(),
      payee: payeeController.text.trim(),
      amount: amount,
      category: selectedCategory,
      frequency: selectedFrequency,
      nextPaymentDate: selectedNextPaymentDate,
      status: selectedStatus,
      notes: notesController.text.trim().isNotEmpty
          ? notesController.text.trim()
          : null,
      userId: widget.userId,
    );

    widget.onSave(paymentEntity);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
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
            // Next payment date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Next Payment Date'),
              subtitle: Text(
                '${selectedNextPaymentDate.year}-${selectedNextPaymentDate.month.toString().padLeft(2, '0')}-${selectedNextPaymentDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedNextPaymentDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() => selectedNextPaymentDate = date);
                  }
                },
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _savePayment,
          child: Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
