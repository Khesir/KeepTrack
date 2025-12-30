import 'package:flutter/material.dart';
import 'package:persona_codex/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:persona_codex/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';

class CategoryManagementDialog extends StatefulWidget {
  final FinanceCategory? financeCategory;
  final String userId;

  final Function(FinanceCategory) onSave;

  const CategoryManagementDialog({
    this.financeCategory,
    required this.userId,
    required this.onSave,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementDialog> {
  late final TextEditingController nameController;
  late CategoryType selectedType;
  bool _isSaving = false;
  bool get isEdit => widget.financeCategory != null;

  @override
  void initState() {
    super.initState();
    final fc = widget.financeCategory;
    nameController = TextEditingController(text: fc?.name ?? '');
    selectedType = fc?.type ?? CategoryType.expense;
  }

  Future<void> _saveCategory() async {
    if (_isSaving) return; // Prevent double-submit

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final category = FinanceCategory(
        name: nameController.text.trim(),
        type: selectedType,
        userId: widget.userId,
      );
      widget.onSave(category);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Category updated' : 'Category created')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(isEdit ? 'Edit Category' : 'Create Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., Groceries, Rent, Salary',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Category Type',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...CategoryType.values.map((type) {
                return RadioListTile<CategoryType>(
                  title: Text(type.displayName),
                  subtitle: Text(type.description),
                  value: type,
                  groupValue: selectedType,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _saveCategory,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
