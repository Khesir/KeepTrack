import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
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

  static Future<void> show(
    BuildContext context, {
    SavingsBucket? bucket,
    required String userId,
    required Future<void> Function(SavingsBucket) onSave,
    Future<void> Function()? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavingsManagementDialog(
        bucket: bucket,
        userId: userId,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<SavingsManagementDialog> createState() => _SavingsManagementDialogState();
}

class _SavingsManagementDialogState extends State<SavingsManagementDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;

  String _colorHex = _kColors.first;
  IconData _selectedIcon = IconHelper.defaultIcon;
  bool _saving = false;

  static const _kColors = [
    '#1D9E75', '#378ADD', '#534AB7', '#EC4899',
    '#EF9F27', '#E24B4A', '#0CA678', '#AE3EC9',
  ];

  List<(IconData, String, String)> get _icons => IconHelper.getAvailableIcons();

  Color get _accentColor =>
      Color(int.parse(_colorHex.replaceFirst('#', '0xFF')));

  @override
  void initState() {
    super.initState();
    final b = widget.bucket;
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: b != null && b.balance > 0 ? b.balance.toStringAsFixed(2) : '',
    );
    _colorHex = b?.colorHex ?? _kColors.first;
    _selectedIcon = IconHelper.fromString(b?.iconCodePoint);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final bucket = SavingsBucket(
        id: widget.bucket?.id,
        userId: widget.userId,
        name: name,
        balance: double.tryParse(_balanceCtrl.text) ?? widget.bucket?.balance ?? 0,
        colorHex: _colorHex,
        iconCodePoint: _selectedIcon.codePoint.toString(),
      );
      await widget.onSave(bucket);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Bucket'),
        content: Text('Delete "${widget.bucket!.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.onDelete?.call();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.void_ : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final isEdit = widget.bucket != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(_selectedIcon, color: _accentColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      isEdit ? 'Edit Bucket' : 'New Savings Bucket',
                      style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    Text(
                      isEdit ? 'Update bucket details' : 'Track a separate savings goal',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ]),
                ]),
                const SizedBox(height: 24),

                // Name
                _Label('Name', required: true),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
                  decoration: _inputDeco(isDark, 'e.g., Emergency Fund, Vacation'),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 14),

                // Initial balance (create only)
                if (!isEdit) ...[
                  _Label('Starting Balance'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _balanceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
                    decoration: _inputDeco(isDark, '0.00', prefix: '₱ '),
                  ),
                  const SizedBox(height: 20),
                ] else
                  const SizedBox(height: 6),

                // Color
                _Label('Color'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _kColors.map((hex) {
                    final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                    final selected = _colorHex == hex;
                    return GestureDetector(
                      onTap: () => setState(() => _colorHex = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: selected ? color : color.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? color : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Icon
                _Label('Icon'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 188,
                  child: GridView.builder(
                    physics: const ClampingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _icons.length,
                    itemBuilder: (_, i) {
                      final icon = _icons[i].$1;
                      final isSelected = icon == _selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _accentColor.withValues(alpha: 0.15)
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.backgroundSecondary),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? _accentColor : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            size: 18,
                            color: isSelected ? _accentColor : AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            isEdit ? 'Save Changes' : 'Create Bucket',
                            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
                ),

                // Delete button (edit only)
                if (isEdit && widget.onDelete != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete Bucket'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(bool isDark, String hint, {String? prefix}) => InputDecoration(
    hintText: hint,
    prefixText: prefix,
    hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: _accentColor, width: 1.5),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  final bool required;
  const _Label(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(text, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    if (required) ...[
      const SizedBox(width: 3),
      Text('*', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error)),
    ],
  ]);
}
