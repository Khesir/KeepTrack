import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';

class SavingsManagementDialog extends StatefulWidget {
  final SavingsBucket? bucket;
  final String userId;
  final Future<void> Function(SavingsBucket) onSave;
  final Future<void> Function()? onDelete;

  const SavingsManagementDialog({
    super.key,
    this.bucket,
    required this.userId,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<SavingsManagementDialog> createState() => _SavingsManagementDialogState();
}

class _SavingsManagementDialogState extends State<SavingsManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = IconHelper.defaultIcon;
  bool _isSaving = false;

  List<IconData> get _iconOptions =>
      IconHelper.getAvailableIcons().map((e) => e.$1).toList();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bucket?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.bucket?.balance.toString() ?? '0',
    );
    _selectedColor = widget.bucket?.colorHex != null
        ? Color(int.parse(widget.bucket!.colorHex!.replaceFirst('#', '0xff')))
        : Colors.blue;
    _selectedIcon = IconHelper.fromString(widget.bucket?.iconCodePoint);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.bucket != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Savings Bucket' : 'Add Savings Bucket'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Balance',
                    prefixText: '₱ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter balance';
                    if (double.tryParse(v) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Color:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _pickColor,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Icon:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: _iconOptions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final icon = _iconOptions[index];
                      final isSelected = icon == _selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor.withOpacity(0.1)
                                : null,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (isEdit && widget.onDelete != null)
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Savings Bucket'),
                  content: const Text('Are you sure you want to delete this savings bucket?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await widget.onDelete?.call();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
            showLabel: true,
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final bucket = SavingsBucket(
        id: widget.bucket?.id,
        userId: widget.userId,
        name: _nameController.text.trim(),
        balance: double.tryParse(_balanceController.text) ?? 0,
        colorHex: '#${_selectedColor.value.toRadixString(16).padLeft(8, '0')}',
        iconCodePoint: _selectedIcon.codePoint.toString(),
      );

      await widget.onSave(bucket);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
