import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';

class BudgetProfileSheet extends StatefulWidget {
  final BudgetProfileController controller;
  final BudgetProfile? existing;

  const BudgetProfileSheet({super.key, required this.controller, this.existing});

  @override
  State<BudgetProfileSheet> createState() => _BudgetProfileSheetState();
}

class _BudgetProfileSheetState extends State<BudgetProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late BudgetProfileType _profileType;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _colorHex;
  bool _saving = false;

  static const _colors = [
    '#534AB7', '#1D9E75', '#EF9F27',
    '#E24B4A', '#378ADD', '#EC4899',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _profileType = e?.profileType ?? BudgetProfileType.custom;
    _startDate = e?.startDate;
    _endDate = e?.endDate;
    _colorHex = e?.colorHex ?? _colors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final profile = BudgetProfile(
        id: widget.existing?.id,
        name: name,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        startDate: _profileType == BudgetProfileType.monthly ? null : _startDate,
        endDate: _profileType == BudgetProfileType.monthly ? null : _endDate,
        colorHex: _colorHex,
        profileType: _profileType,
        status: widget.existing?.status ?? BudgetProfileStatus.active,
      );
      if (widget.existing == null) {
        await widget.controller.createProfile(profile);
      } else {
        await widget.controller.updateProfile(profile);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final surfaceBg = isDark ? AppColors.void_ : AppColors.surface;
    final fmt = DateFormat('MMM d, yyyy');
    final isEdit = widget.existing != null;
    final accentColor = _colorHex != null
        ? Color(int.parse(_colorHex!.replaceFirst('#', '0xFF')))
        : AppColors.accent;

    return Container(
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
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
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fork_right_rounded, size: 18, color: accentColor),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isEdit ? 'Edit Budget' : 'New Budget',
                style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              Text(
                isEdit ? 'Update budget details' : 'Create a branch for a separate budget',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
              ),
            ]),
          ]),
          const SizedBox(height: 20),

          // Type toggle
          if (!isEdit) ...[
            _Label('Type', required: true),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<BudgetProfileType>(
                segments: const [
                  ButtonSegment(
                    value: BudgetProfileType.monthly,
                    label: Text('Monthly'),
                    icon: Icon(Icons.calendar_month_outlined, size: 14),
                  ),
                  ButtonSegment(
                    value: BudgetProfileType.custom,
                    label: Text('Custom'),
                    icon: Icon(Icons.tune_rounded, size: 14),
                  ),
                ],
                selected: {_profileType},
                onSelectionChanged: (s) => setState(() => _profileType = s.first),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _profileType == BudgetProfileType.monthly
                  ? 'Tracks budget month by month, independent of the main budget.'
                  : 'A standalone budget with an optional date range (project, event, etc.).',
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],

          _Label('Name', required: true),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
            decoration: _inputDecoration(
              _profileType == BudgetProfileType.monthly
                  ? 'e.g., Savings Budget, Partner Budget'
                  : 'e.g., Europe Trip, Q1 Budget',
            ),
          ),
          const SizedBox(height: 14),

          _Label('Description'),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
            decoration: _inputDecoration('Optional notes about this budget'),
          ),
          const SizedBox(height: 16),

          if (_profileType == BudgetProfileType.custom) ...[
            _Label('Date Range'),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _DateChip(
                label: _startDate != null ? fmt.format(_startDate!) : 'Start Date',
                icon: Icons.play_arrow_rounded,
                active: _startDate != null,
                onTap: () => _pickDate(true),
                isDark: isDark,
              )),
              const SizedBox(width: 10),
              Expanded(child: _DateChip(
                label: _endDate != null ? fmt.format(_endDate!) : 'End Date',
                icon: Icons.stop_rounded,
                active: _endDate != null,
                onTap: () => _pickDate(false),
                isDark: isDark,
              )),
            ]),
            const SizedBox(height: 16),
          ],

          _Label('Color'),
          const SizedBox(height: 10),
          Row(children: _colors.map((hex) {
            final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
            final selected = _colorHex == hex;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _colorHex = hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: selected ? color : color.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: color, width: 2.5) : Border.all(color: Colors.transparent),
                    boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))] : null,
                  ),
                  child: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      isEdit ? 'Save Changes' : 'Create Budget',
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
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
      borderSide: BorderSide(color: AppColors.accent, width: 1.5),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  final bool required;
  const _Label(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(text, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      if (required) ...[
        const SizedBox(width: 3),
        Text('*', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error)),
      ],
    ]);
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;

  const _DateChip({required this.label, required this.icon, required this.active, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textTertiary;
    final bg = active
        ? AppColors.accent.withValues(alpha: 0.08)
        : (isDark ? const Color(0xFF2A2A28) : AppColors.backgroundSecondary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: active ? AppColors.accent : AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }
}
