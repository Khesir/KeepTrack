import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account_enums.dart';

class AccountManagementDialog extends StatefulWidget {
  final Account? account;
  final String userId;
  final Future<void> Function(Account) onSave;
  final Future<void> Function()? onDelete;

  const AccountManagementDialog({
    this.account,
    required this.userId,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<AccountManagementDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _bankController;

  AccountType _selectedType = AccountType.cash;
  bool _isActive = true;
  bool _isArchived = false;
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = IconHelper.defaultIcon;
  bool _isSaving = false;

  // Get icon options from IconHelper to ensure tree-shakeable icons
  List<IconData> get _iconOptions =>
      IconHelper.getAvailableIcons().map((e) => e.$1).toList();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.account?.balance.toString() ?? '0',
    );
    _bankController = TextEditingController(
      text: widget.account?.bankAccountNumber ?? '',
    );
    _selectedType = widget.account?.accountType ?? AccountType.cash;
    _isActive = widget.account?.isActive ?? true;
    _isArchived = widget.account?.isArchived ?? false;
    _selectedColor = widget.account?.colorHex != null
        ? Color(int.parse(widget.account!.colorHex!.replaceFirst('#', '0xff')))
        : Colors.blue;
    _selectedIcon = IconHelper.fromString(widget.account?.iconCodePoint);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.account != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Account' : 'Add Account'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter account name' : null,
                ),
                const SizedBox(height: 12),

                // Account Type
                DropdownButtonFormField<AccountType>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: AccountType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedType = v);
                  },
                ),
                const SizedBox(height: 12),

                // Balance
                TextFormField(
                  controller: _balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Initial Balance',
                    prefixText: '₱ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter balance';
                    if (double.tryParse(v) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Bank Account Number
                TextFormField(
                  controller: _bankController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Account Number (Optional)',
                  ),
                ),
                const SizedBox(height: 16),

                // Color Picker
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

                // Icon Picker
                const Text('Icon:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: _iconOptions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
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
                const SizedBox(height: 16),

                // Active / Archived
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Archived'),
                  value: _isArchived,
                  onChanged: (v) => setState(() => _isArchived = v),
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
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Are you sure you want to delete this account?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
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
    if (_isSaving) return; // Prevent double-submit
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final account = Account(
        id: widget.account?.id,
        name: _nameController.text.trim(),
        accountType: _selectedType,
        balance: double.tryParse(_balanceController.text) ?? 0,
        bankAccountNumber: _bankController.text.trim().isEmpty
            ? null
            : _bankController.text.trim(),
        colorHex: '#${_selectedColor.value.toRadixString(16).padLeft(8, '0')}',
        iconCodePoint: _selectedIcon.codePoint.toString(),
        isActive: _isActive,
        isArchived: _isArchived,
        userId: widget.userId,
      );

      await widget.onSave(account);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
