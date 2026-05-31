import 'package:flutter/material.dart';
import 'package:keep_track/core/ui/app_toast.dart';

import '../../domain/entities/budget_category.dart';

class _EditAmountDialog extends StatefulWidget {
  final BudgetCategory category;
  final Future<void> Function(double) onSave;

  const _EditAmountDialog({required this.category, required this.onSave});

  @override
  State<_EditAmountDialog> createState() => _EditAmountDialogState();
}

class _EditAmountDialogState extends State<_EditAmountDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.category.targetAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit ${widget.category.financeCategory?.name ?? 'Category'}',
      ),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Planned Amount',
          border: OutlineInputBorder(),
          prefixText: '₱ ',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_controller.text);
    if (amount == null || amount <= 0) {
      AppToast.error(context, 'Enter a valid amount');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(amount);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: $e');
        setState(() => _saving = false);
      }
    }
  }
}
