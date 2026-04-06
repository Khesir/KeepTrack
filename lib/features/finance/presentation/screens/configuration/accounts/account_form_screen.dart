import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account_enums.dart';

class AccountFormScreen extends StatefulWidget {
  final Account? account; // null = create, non-null = edit
  final String userId;
  final Future<void> Function(Account) onSave;
  final Future<void> Function()? onDelete;

  const AccountFormScreen({
    super.key,
    this.account,
    required this.userId,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
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

  // Image state
  Uint8List? _imageBytes; // raw bytes of newly picked image
  String? _imageUrl; // existing URL from account (edit mode)

  static const List<Color> _presetColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(
      text: account?.balance.toString() ?? '0',
    );
    _bankController = TextEditingController(
      text: account?.bankAccountNumber ?? '',
    );
    _selectedType = account?.accountType ?? AccountType.cash;
    _isActive = account?.isActive ?? true;
    _isArchived = account?.isArchived ?? false;
    _selectedColor = account?.colorHex != null
        ? Color(int.parse(account!.colorHex!.replaceFirst('#', '0xff')))
        : Colors.blue;
    _selectedIcon = IconHelper.fromString(account?.iconCodePoint);
    _imageUrl = account?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  // ── Avatar helper ──────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    const double radius = 80;

    ImageProvider? imageProvider;
    if (_imageBytes != null) {
      imageProvider = MemoryImage(_imageBytes!);
    } else if (_imageUrl != null) {
      if (_imageUrl!.startsWith('data:')) {
        // base64 data URI
        final base64Str = _imageUrl!.split(',').last;
        imageProvider = MemoryImage(base64Decode(base64Str));
      } else {
        imageProvider = NetworkImage(_imageUrl!);
      }
    }

    final Widget avatar = imageProvider != null
        ? CircleAvatar(
            radius: radius,
            backgroundImage: imageProvider,
            backgroundColor: _selectedColor,
          )
        : CircleAvatar(
            radius: radius,
            backgroundColor: _selectedColor,
            child: Icon(_selectedIcon, size: 56, color: Colors.white),
          );

    return GestureDetector(
      onTap: _showAvatarSheet,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatar,
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: const Icon(Icons.edit, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showAvatarSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Image'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('Browse Icons'),
              onTap: () {
                Navigator.pop(ctx);
                _showIconPicker();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageUrl = null; // clear existing URL when new image picked
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => _IconPickerSheet(
          selectedIcon: _selectedIcon,
          scrollController: scrollController,
          onIconSelected: (icon) {
            setState(() {
              _selectedIcon = icon;
              _imageBytes = null;
              _imageUrl = null;
            });
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  // ── Color section ──────────────────────────────────────────────────────────

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._presetColors.map((color) => _ColorDot(
                  color: color,
                  isSelected: _selectedColor.value == color.value,
                  onTap: () => setState(() => _selectedColor = color),
                )),
            // Custom color button
            GestureDetector(
              onTap: _showColorPicker,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 2,
                  ),
                  gradient: const SweepGradient(colors: [
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.purple,
                    Colors.red,
                  ]),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showColorPicker() {
    Color tempColor = _selectedColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (color) => tempColor = color,
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _selectedColor = tempColor);
              Navigator.pop(ctx);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  // ── Type chips ─────────────────────────────────────────────────────────────

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wallet Type', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AccountType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(type.name),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedType = type),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Determine imageUrl to save
      String? finalImageUrl;
      if (_imageBytes != null) {
        finalImageUrl =
            'data:image/jpeg;base64,${base64Encode(_imageBytes!)}';
      } else {
        finalImageUrl = _imageUrl;
      }

      final account = Account(
        id: widget.account?.id,
        name: _nameController.text.trim(),
        accountType: _selectedType,
        balance: widget.account != null
            ? widget.account!.balance
            : double.tryParse(_balanceController.text) ?? 0,
        bankAccountNumber: _bankController.text.trim().isEmpty
            ? null
            : _bankController.text.trim(),
        colorHex:
            '#${_selectedColor.value.toRadixString(16).padLeft(8, '0')}',
        iconCodePoint: _selectedIcon.codePoint.toString(),
        imageUrl: finalImageUrl,
        isActive: _isActive,
        isArchived: _isArchived,
        userId: widget.userId,
        createdAt: widget.account?.createdAt,
        updatedAt: widget.account?.updatedAt,
      );

      await widget.onSave(account);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: const Text(
          'Are you sure you want to delete this wallet? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.onDelete?.call();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.account != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Wallet' : 'Add Wallet'),
        actions: [
          if (isEdit && widget.onDelete != null)
            IconButton(
              onPressed: _isSaving ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Avatar section ────────────────────────────────────────────
            Center(child: _buildAvatar()),
            const SizedBox(height: 28),

            // ── Wallet type ───────────────────────────────────────────────
            _buildTypeSection(),
            const SizedBox(height: 20),

            // ── Wallet name ───────────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Wallet Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter wallet name' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            // ── Color section ─────────────────────────────────────────────
            _buildColorSection(),
            const SizedBox(height: 20),

            // ── Initial balance (create only) ─────────────────────────────
            if (!isEdit) ...[
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 20),
            ],

            // ── Bank account number ───────────────────────────────────────
            TextFormField(
              controller: _bankController,
              decoration: const InputDecoration(
                labelText: 'Account Number (optional)',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),

            // ── Active / Archived (edit only) ─────────────────────────────
            if (isEdit) ...[
              const Divider(),
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
              const SizedBox(height: 8),
            ],

            // ── Save button ───────────────────────────────────────────────
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Wallet', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Color dot widget ─────────────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

// ── Icon Picker Sheet ─────────────────────────────────────────────────────────

class _IconPickerSheet extends StatefulWidget {
  final IconData selectedIcon;
  final ScrollController scrollController;
  final ValueChanged<IconData> onIconSelected;

  const _IconPickerSheet({
    required this.selectedIcon,
    required this.scrollController,
    required this.onIconSelected,
  });

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  late final List<(IconData, String, String)> _allIcons;
  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    _allIcons = IconHelper.getAvailableIcons();
    final cats = <String>{};
    for (final icon in _allIcons) {
      cats.add(icon.$3);
    }
    _categories = cats.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<(IconData, String, String)> get _filtered {
    return _allIcons.where((icon) {
      final matchesQuery = _query.isEmpty ||
          icon.$2.toLowerCase().contains(_query.toLowerCase()) ||
          icon.$3.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory =
          _selectedCategory == null || icon.$3 == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      children: [
        // Handle bar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Browse Icons',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search icons...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),

        // Category filter chips
        SizedBox(
          height: 40,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = null),
                ),
              ),
              ..._categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Icon grid
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No icons found'))
              : GridView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final icon = filtered[index];
                    final isSelected =
                        icon.$1.codePoint == widget.selectedIcon.codePoint;

                    return GestureDetector(
                      onTap: () => widget.onIconSelected(icon.$1),
                      child: Tooltip(
                        message: icon.$2,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            icon.$1,
                            size: 26,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
