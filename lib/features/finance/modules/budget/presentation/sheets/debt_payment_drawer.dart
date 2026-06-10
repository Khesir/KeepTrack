import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/finance_category.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import 'package:uuid/uuid.dart';
import '../sheets/sheet_helpers.dart';
import '../widgets/detail_sheet_widgets.dart';

class DebtPaymentDrawer extends StatefulWidget {
  final Debt debt;
  final Future<void> Function(double amount, double? fee, PaymentTxConfig config) onConfirm;
  const DebtPaymentDrawer({super.key, required this.debt, required this.onConfirm});
  @override
  State<DebtPaymentDrawer> createState() => _DebtPaymentDrawerState();
}

class _DebtPaymentDrawerState extends State<DebtPaymentDrawer> {
  late final TextEditingController _amtCtrl;
  late final TextEditingController _feeCtrl;
  late final TextEditingController _descCtrl;
  late final WalletController _walletController;
  late final FinanceCategoryController _catController;
  late final BudgetProfileController _profileController;
  late final String _pendingId;

  Wallet? _wallet;
  FinanceCategory? _category;
  String? _profileId, _profileName;
  final List<String> _imagePaths = [];
  DateTime _date = DateTime.now();
  bool _showDesc = false;
  bool _loading = false;
  bool _txSaved = false;

  bool get _isReceivable => widget.debt.type == DebtType.lending;
  Color get _color => _isReceivable ? AppColors.success : AppColors.error;
  CategoryType get _catType => _isReceivable ? CategoryType.income : CategoryType.expense;

  bool get _canConfirm {
    final amt = double.tryParse(_amtCtrl.text) ?? 0;
    return amt > 0 && _wallet != null;
  }

  @override
  void initState() {
    super.initState();
    _pendingId = const Uuid().v4();
    _amtCtrl = TextEditingController(
      text: widget.debt.monthlyPaymentAmount > 0 ? widget.debt.monthlyPaymentAmount.toStringAsFixed(2) : '',
    );
    _feeCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _walletController = locator.get<WalletController>();
    _catController = locator.get<FinanceCategoryController>();
    _profileController = locator.get<BudgetProfileController>();
    _catController.loadCategories();
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    _feeCtrl.dispose();
    _descCtrl.dispose();
    if (!_txSaved) TransactionImageService.deleteAll(_pendingId).ignore();
    super.dispose();
  }

  Future<void> _pickCategory(bool isDark) async {
    final allCats = _catController.data ?? [];
    final groups = buildGroupedCategories(allCategories: allCats, allBudgets: [], targetType: _catType, monthKey: '');
    final picked = await showGroupedCategoryDialog(context, groups: groups, selectedId: _category?.id);
    if (picked != null && mounted) setState(() => _category = picked);
  }

  void _pickBudgetProfile(bool isDark) {
    final profiles = _profileController.data ?? <BudgetProfile>[];
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Budget', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary))),
          const SizedBox(height: 4),
          Flexible(child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
            ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.block_outlined, size: 16, color: AppColors.textTertiary),
              title: Text('None', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
              trailing: _profileId == null ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
              onTap: () { setState(() { _profileId = null; _profileName = null; }); Navigator.pop(context); }),
            ...profiles.where((p) => p.isActive).map((p) => ListTile(contentPadding: EdgeInsets.zero,
              title: Text(p.name, style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary)),
              trailing: _profileId == p.id ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
              onTap: () { setState(() { _profileId = p.id; _profileName = p.name; }); Navigator.pop(context); })),
          ])),
        ])),
      ),
    );
  }

  Future<ImageSource?> _showSourcePicker(Color bg) => showModalBottomSheet<ImageSource>(
    context: context, backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 8),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text('Gallery', style: GoogleFonts.dmSans(fontSize: 14)), onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.camera_alt_outlined), title: Text('Camera', style: GoogleFonts.dmSans(fontSize: 14)), onTap: () => Navigator.pop(context, ImageSource.camera)),
        const SizedBox(height: 8),
      ])),
    ),
  );

  Future<void> _pickImage(bool isDark) async {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final source = await _showSourcePicker(bg);
    if (source == null || !mounted) return;
    final path = await TransactionImageService.pickImage(_pendingId, source: source);
    if (path != null && mounted) setState(() => _imagePaths.add(path));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _pickWallet(List<Wallet> wallets, bool isDark) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Select Wallet', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 12),
          ...wallets.map((w) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.account_balance_wallet_outlined, color: _color),
            title: Text(w.name, style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary)),
            subtitle: Text(currencyFormatter.format(w.balance), style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
            trailing: _wallet?.id == w.id ? Icon(Icons.check_rounded, color: _color, size: 18) : null,
            onTap: () { setState(() => _wallet = w); Navigator.pop(context); },
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = widget.debt;
    final isReceivable = d.type == DebtType.lending;
    final color = _color;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final amt = double.tryParse(_amtCtrl.text);
    final confirmLabel = amt != null && amt > 0
        ? '${isReceivable ? 'Collect' : 'Pay'} ${currencyFormatter.format(amt, decimalDigits: 2)}'
        : isReceivable ? 'Collect' : 'Pay';
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_date, now);
    final dateLabel = isToday ? 'Today' : DateFormat('MMM d').format(_date);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 16, 0), child: Row(children: [
            Expanded(child: Text(isReceivable ? 'Collect from ${d.personName}' : 'Pay ${d.personName}',
                style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
          ])),
          Divider(height: 20, color: borderColor),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _amtCtrl, autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Amount *', border: const OutlineInputBorder(),
                helperText: d.monthlyPaymentAmount > 0 ? 'Planned: ${currencyFormatter.format(d.monthlyPaymentAmount, decimalDigits: 2)}/mo' : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Fee (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            AsyncStreamBuilder<List<Wallet>>(
              state: _walletController,
              builder: (_, wallets) => GestureDetector(
                onTap: () => _pickWallet(wallets, isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: _wallet != null ? color.withValues(alpha: 0.4) : borderColor, width: _wallet != null ? 1 : 0.5),
                    borderRadius: BorderRadius.circular(10),
                    color: _wallet != null ? color.withValues(alpha: 0.04) : Colors.transparent,
                  ),
                  child: Row(children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 16, color: _wallet != null ? color : AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_wallet?.name ?? 'Select wallet *', style: GoogleFonts.dmSans(fontSize: 14, color: _wallet != null ? textPrimary : AppColors.textSecondary))),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
                  ]),
                ),
              ),
              loadingBuilder: (_) => const SizedBox.shrink(),
              errorBuilder: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            Padding(padding: const EdgeInsets.only(left: 2), child: Wrap(spacing: 8, runSpacing: 6, children: [
              PayChip(icon: Icons.account_balance_wallet_outlined, label: _profileName ?? 'Budget', active: _profileId != null, isDark: isDark, onTap: () => _pickBudgetProfile(isDark)),
              PayChip(icon: Icons.grid_view_rounded, label: _category?.name ?? 'Category', active: _category != null, isDark: isDark, onTap: () => _pickCategory(isDark)),
              PayChip(icon: Icons.attach_file_rounded, label: _imagePaths.isEmpty ? 'Attach' : 'Files (${_imagePaths.length})', active: _imagePaths.isNotEmpty, isDark: isDark, onTap: () => _pickImage(isDark)),
              PayChip(icon: Icons.calendar_today_outlined, label: dateLabel, active: !isToday, isDark: isDark, onTap: _pickDate),
              PayChip(icon: _showDesc ? Icons.edit_off_outlined : Icons.edit_outlined, label: 'Note', active: _showDesc, isDark: isDark, onTap: () => setState(() => _showDesc = !_showDesc)),
            ])),
            if (_showDesc) ...[
              const SizedBox(height: 10),
              TextField(controller: _descCtrl, maxLines: 1, decoration: const InputDecoration(hintText: 'Add a note…', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10), isDense: true)),
            ],
            const SizedBox(height: 20),
            SheetActionButton(
              label: confirmLabel, icon: Icons.check_circle_outline_rounded,
              color: _canConfirm ? color : AppColors.textTertiary,
              loading: _loading,
              onTap: !_canConfirm ? null : () async {
                final amount = double.tryParse(_amtCtrl.text);
                if (amount == null || amount <= 0) return;
                final fee = double.tryParse(_feeCtrl.text);
                final nav = Navigator.of(context);
                setState(() => _loading = true);
                try {
                  final config = PaymentTxConfig(
                    wallet: _wallet!,
                    categoryId: _category?.id,
                    budgetProfileId: _profileId,
                    imagePaths: List.from(_imagePaths),
                    date: _date,
                    description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
                  );
                  _txSaved = true;
                  await widget.onConfirm(amount, fee, config);
                  nav.pop();
                } catch (e, st) {
                  _txSaved = false;
                  debugPrint('[PaymentDrawer] error: $e\n$st');
                  if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
            ),
            const SizedBox(height: 8),
            SheetActionButton(label: 'Cancel', icon: Icons.close_rounded, color: AppColors.textSecondary, outlined: true, onTap: () => Navigator.pop(context), isDark: isDark),
          ])),
        ])),
      ),
    );
  }
}
