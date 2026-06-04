import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';

class WalletManagementDialog extends StatefulWidget {
  final Wallet? wallet;
  final String userId;
  final Future<void> Function(Wallet) onSave;
  final Future<void> Function()? onDelete;

  const WalletManagementDialog({
    super.key,
    this.wallet,
    required this.userId,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    Wallet? wallet,
    required String userId,
    required Future<void> Function(Wallet) onSave,
    Future<void> Function()? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WalletManagementDialog(
        wallet: wallet,
        userId: userId,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<WalletManagementDialog> createState() => _WalletManagementDialogState();
}

class _WalletManagementDialogState extends State<WalletManagementDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _labelInputCtrl;

  String _colorHex = _kColors.first;
  IconData _selectedIcon = IconHelper.defaultIcon;
  WalletType _walletType = WalletType.standard;
  List<String> _labels = [];
  bool _saving = false;

  static const _kColors = [
    '#1D9E75', '#378ADD', '#534AB7', '#EC4899',
    '#EF9F27', '#E24B4A', '#0CA678', '#AE3EC9',
  ];

  static const _kSuggestedLabels = [
    'Daily', 'Emergency', 'Business', 'Savings',
    'Travel', 'Food', 'Bills', 'Personal',
  ];

  List<(IconData, String, String)> get _icons => IconHelper.getAvailableIcons();

  Color get _accentColor =>
      Color(int.parse(_colorHex.replaceFirst('#', '0xFF')));

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    _nameCtrl = TextEditingController(text: w?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: w != null && w.balance > 0 ? w.balance.toStringAsFixed(2) : '',
    );
    _notesCtrl = TextEditingController(text: w?.notes ?? '');
    _labelInputCtrl = TextEditingController();
    _colorHex = w?.colorHex ?? _kColors.first;
    _selectedIcon = IconHelper.fromString(w?.iconCodePoint);
    _walletType = w?.type ?? WalletType.standard;
    _labels = List<String>.from(w?.labels ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _notesCtrl.dispose();
    _labelInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final pendingLabel = _labelInputCtrl.text.trim();
    if (pendingLabel.isNotEmpty && !_labels.contains(pendingLabel)) {
      setState(() => _labels.add(pendingLabel));
    }
    _labelInputCtrl.clear();
    setState(() => _saving = true);
    try {
      final notes = _notesCtrl.text.trim();
      final wallet = Wallet(
        id: widget.wallet?.id,
        userId: widget.userId,
        name: name,
        balance: double.tryParse(_balanceCtrl.text) ?? widget.wallet?.balance ?? 0,
        type: _walletType,
        colorHex: _colorHex,
        iconCodePoint: _selectedIcon.codePoint.toString(),
        notes: notes.isEmpty ? null : notes,
        labels: _labels,
      );
      await widget.onSave(wallet);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: Text('Delete "${widget.wallet!.name}"? This cannot be undone.'),
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
    final isEdit = widget.wallet != null;

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
                      isEdit ? 'Edit Wallet' : 'New Wallet',
                      style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    Text(
                      isEdit ? 'Update wallet details' : 'Track your money in one place',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ]),
                ]),
                const SizedBox(height: 24),

                // Wallet type
                _Label('Type', required: true),
                const SizedBox(height: 8),
                Row(
                  children: WalletType.values.map((t) {
                    final selected = _walletType == t;
                    final icon = t == WalletType.standard
                        ? Icons.account_balance_wallet_outlined
                        : Icons.credit_card_outlined;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: t == WalletType.values.last ? 0 : 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _walletType = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _accentColor.withValues(alpha: 0.12)
                                  : (isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.backgroundSecondary),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? _accentColor.withValues(alpha: 0.5) : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(icon, size: 18, color: selected ? _accentColor : AppColors.textSecondary),
                                const SizedBox(height: 4),
                                Text(
                                  t.displayName,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                    color: selected ? _accentColor : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Name
                _Label('Name', required: true),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
                  decoration: _inputDeco(isDark, _walletType == WalletType.creditCard ? 'e.g., Visa, Mastercard' : 'e.g., Cash, BDO, GCash'),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 14),

                // Notes
                const SizedBox(height: 14),
                _Label('Notes'),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
                  decoration: _inputDeco(isDark, 'e.g., Daily expenses, emergency fund…'),
                ),

                // Labels
                const SizedBox(height: 14),
                _Label('Labels'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ..._labels.map((label) => _LabelChip(
                      label: label,
                      accentColor: _accentColor,
                      isDark: isDark,
                      onRemove: () => setState(() => _labels.remove(label)),
                    )),
                    SizedBox(
                      width: 120,
                      height: 30,
                      child: TextField(
                        controller: _labelInputCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.dmSans(fontSize: 12, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Add label…',
                          hintStyle: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: _accentColor, width: 1.5),
                          ),
                        ),
                        onSubmitted: (value) {
                          final trimmed = value.trim();
                          if (trimmed.isNotEmpty && !_labels.contains(trimmed)) {
                            setState(() => _labels.add(trimmed));
                          }
                          _labelInputCtrl.clear();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _kSuggestedLabels.where((s) => !_labels.contains(s)).map((s) {
                    return GestureDetector(
                      onTap: () => setState(() => _labels.add(s)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 11, color: AppColors.textTertiary),
                            const SizedBox(width: 3),
                            Text(s, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Starting balance (create only)
                if (!isEdit) ...[
                  _Label(_walletType == WalletType.creditCard ? 'Current Balance Owed' : 'Starting Balance'),
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
                            isEdit ? 'Save Changes' : 'Create Wallet',
                            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
                ),

                if (isEdit && widget.onDelete != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete Wallet'),
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

class _LabelChip extends StatelessWidget {
  final String label;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onRemove;

  const _LabelChip({
    required this.label,
    required this.accentColor,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: accentColor),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: accentColor.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
