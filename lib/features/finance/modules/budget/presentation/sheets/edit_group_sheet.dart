import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../domain/entities/budget.dart';
import '../controllers/budget_controller.dart';

class EditGroupSheet extends StatefulWidget {
  final Budget group;
  final BudgetController budgetController;
  final VoidCallback? onDelete;

  const EditGroupSheet({
    super.key,
    required this.group,
    required this.budgetController,
    this.onDelete,
  });

  @override
  State<EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<EditGroupSheet> {
  late final TextEditingController _titleCtrl;
  late BudgetType _budgetType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.group.title ?? '');
    _budgetType = widget.group.budgetType;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.budgetController.updateBudget(
        widget.group.copyWith(title: title, budgetType: _budgetType),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text('Edit Budget Group', style: AppTextStyles.h4),
            const SizedBox(height: 20),

            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),

            Center(
              child: SegmentedButton<BudgetType>(
                segments: const [
                  ButtonSegment(
                    value: BudgetType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward, size: 14),
                  ),
                  ButtonSegment(
                    value: BudgetType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward, size: 14),
                  ),
                ],
                selected: {_budgetType},
                onSelectionChanged: (s) =>
                    setState(() => _budgetType = s.first),
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
                    : const Text('Save'),
              ),
            ),
            if (widget.onDelete != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _saving ? null : widget.onDelete,
                  child: const Text(
                    'Delete Group',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
