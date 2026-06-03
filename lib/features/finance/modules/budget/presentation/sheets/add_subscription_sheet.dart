import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'sheet_helpers.dart';

class AddSubscriptionSheet extends StatefulWidget {
  final Future<void> Function(Subscription) onSave;
  const AddSubscriptionSheet({super.key, required this.onSave});

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _nameCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late final AuthController _authController;

  BillingCycle _cycle = BillingCycle.monthly;
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _authController = locator.get<AuthController>();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _providerCtrl.dispose();
    _amountCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      (double.tryParse(_amountCtrl.text) ?? 0) > 0;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(Subscription(
        userId: _authController.currentUser?.id ?? '',
        name: _nameCtrl.text.trim(),
        provider: _providerCtrl.text.trim().isEmpty ? null : _providerCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text),
        billingCycle: _cycle,
        status: SubscriptionStatus.active,
        nextBillingDate: _nextBillingDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pickDate(bool isDark) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => SheetCalendar(
        isDark: isDark, selected: _nextBillingDate, allowPast: true,
        onSelect: (d) { setState(() => _nextBillingDate = d); Navigator.pop(context); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: DraggableScrollableSheet(
          expand: false, initialChildSize: 0.82, maxChildSize: 0.95, minChildSize: 0.5,
          builder: (_, ctrl) => Column(children: [
            Padding(padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            Padding(padding: const EdgeInsets.fromLTRB(20, 10, 16, 0), child: Row(children: [
              Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.autorenew_rounded, size: 18, color: AppColors.error)),
              const SizedBox(width: 12),
              Expanded(child: Text('New Subscription', style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary))),
              GestureDetector(onTap: () => Navigator.pop(context),
                  child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
            ])),
            Divider(height: 20, color: border),
            Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
              SheetLabel('Name *'),
              SheetField(ctrl: _nameCtrl, hint: 'Netflix, Spotify…', isDark: isDark, autofocus: true, onChanged: (_) => setState(() {}), capitalize: true),
              const SizedBox(height: 16),
              SheetLabel('Provider (optional)'),
              SheetField(ctrl: _providerCtrl, hint: 'e.g. Apple, Google', isDark: isDark, capitalize: true),
              const SizedBox(height: 16),
              SheetLabel('Amount *'),
              SheetField(ctrl: _amountCtrl, hint: '0.00', prefix: '${currencyFormatter.currencySymbol} ', isDark: isDark, numeric: true, onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              SheetLabel('Billing Cycle'),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: BillingCycle.values.map((c) {
                  final sel = c == _cycle;
                  return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                    onTap: () => setState(() => _cycle = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.error : (isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.background),
                        borderRadius: BorderRadius.circular(20),
                        border: sel ? null : Border.all(color: border, width: 0.5),
                      ),
                      child: Text(c.displayName, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? Colors.white : AppColors.textSecondary)),
                    ),
                  ));
                }).toList()),
              ),
              const SizedBox(height: 16),
              SheetLabel('Next Billing Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickDate(isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: border, width: 0.5), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(DateFormat('MMMM d, yyyy').format(_nextBillingDate),
                        style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary))),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              SheetLabel('Notes (optional)'),
              SheetField(ctrl: _notesCtrl, hint: 'Add a note…', isDark: isDark, maxLines: 2),
              const SizedBox(height: 28),
              SizedBox(width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _canSave && !_saving ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave ? AppColors.error : AppColors.textTertiary,
                    foregroundColor: AppColors.textPrimaryDark, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Add Subscription', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ])),
          ]),
        ),
      ),
    );
  }
}
