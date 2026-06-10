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
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import 'package:uuid/uuid.dart';
import '../sheets/sheet_helpers.dart';
import '../widgets/detail_sheet_widgets.dart';

class GoalContributionDrawer extends StatefulWidget {
  final Goal goal;
  final Future<void> Function(double amount, PaymentTxConfig config) onConfirm;
  const GoalContributionDrawer({super.key, required this.goal, required this.onConfirm});
  @override
  State<GoalContributionDrawer> createState() => _GoalContributionDrawerState();
}

class _GoalContributionDrawerState extends State<GoalContributionDrawer> {
  late final TextEditingController _amtCtrl;
  late final TextEditingController _descCtrl;
  late final WalletController _walletController;
  late final FinanceCategoryController _catController;
  late final BudgetProfileController _profileController;
  late final String _pendingId;

  Wallet? _selectedWallet;
  FinanceCategory? _category;
  String? _profileId, _profileName;
  final List<String> _imagePaths = [];
  DateTime _date = DateTime.now();
  bool _showDesc = false;
  bool _loading = false;
  bool _txSaved = false;

  @override
  void initState() {
    super.initState();
    _pendingId = const Uuid().v4();
    _amtCtrl = TextEditingController(
      text: widget.goal.monthlyContribution > 0 ? widget.goal.monthlyContribution.toStringAsFixed(2) : '',
    );
    _descCtrl = TextEditingController();
    _walletController = locator.get<WalletController>();
    _catController = locator.get<FinanceCategoryController>();
    _profileController = locator.get<BudgetProfileController>();
    _catController.loadCategories();
    _walletController.loadWallets();
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    _descCtrl.dispose();
    if (!_txSaved) TransactionImageService.deleteAll(_pendingId).ignore();
    super.dispose();
  }

  Future<void> _pickCategory(bool isDark) async {
    final allCats = _catController.data ?? [];
    final groups = buildGroupedCategories(allCategories: allCats, allBudgets: [], targetType: CategoryType.income, monthKey: '');
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

  void _pickWallet(bool isDark) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final bc = AppColors.border.withValues(alpha: isDark ? 0.2 : 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 16, 10), child: Row(children: [
            Text('Select Wallet', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
            const Spacer(),
            GestureDetector(onTap: () => Navigator.pop(sheetCtx), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
          ])),
          Divider(height: 1, color: bc),
          AsyncStreamBuilder<List<Wallet>>(
            state: locator.get<WalletController>(),
            builder: (_, allWallets) {
              final wallets = allWallets.where((w) => w.id != widget.goal.savingsBucketId).toList();
              if (wallets.isEmpty) {
                return Padding(padding: const EdgeInsets.all(24), child: Column(children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 40, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text('No wallets yet', style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary)),
                ]));
              }
              return Column(mainAxisSize: MainAxisSize.min, children: wallets.map((w) {
                final isSelected = w.id == _selectedWallet?.id;
                final color = w.colorHex != null ? Color(int.parse(w.colorHex!.replaceFirst('#', '0xff'))) : AppColors.success;
                return Column(children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.account_balance_wallet_outlined, size: 20, color: color)),
                    title: Text(w.name, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: textPrimary)),
                    subtitle: Text(currencyFormatter.format(w.balance, decimalDigits: 2), style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.success)),
                    trailing: isSelected ? Icon(Icons.check_rounded, size: 20, color: AppColors.accent) : null,
                    onTap: () { setState(() => _selectedWallet = w); Navigator.pop(sheetCtx); },
                  ),
                  Divider(height: 1, color: bc, indent: 20, endIndent: 20),
                ]);
              }).toList());
            },
            loadingBuilder: (_) => const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
            errorBuilder: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final g = widget.goal;
    final color = g.colorHex != null ? Color(int.parse(g.colorHex!.replaceFirst('#', '0xff'))) : AppColors.accent;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final amt = double.tryParse(_amtCtrl.text);
    final newTotal = amt != null ? (g.currentAmount + amt).clamp(0.0, double.infinity) : null;
    final newProgress = newTotal != null && g.targetAmount > 0 ? (newTotal / g.targetAmount).clamp(0.0, 1.0) : null;
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_date, now);
    final dateLabel = isToday ? 'Today' : DateFormat('MMM d').format(_date);
    final canConfirm = (amt ?? 0) > 0 && _selectedWallet != null;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 16, 0), child: Row(children: [
            Expanded(child: Text('Contribute to ${g.name}', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
          ])),
          if (g.savingsBucketId != null)
            Padding(padding: const EdgeInsets.fromLTRB(20, 6, 20, 0), child: Row(children: [
              Icon(Icons.link_rounded, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('Also updates linked savings bucket', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
            ])),
          Divider(height: 20, color: borderColor),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _amtCtrl, autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Amount', prefixText: '${currencyFormatter.currencySymbol} ', border: const OutlineInputBorder(),
                helperText: g.monthlyContribution > 0 ? 'Planned: ${currencyFormatter.format(g.monthlyContribution, decimalDigits: 2)}/mo' : null,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _pickWallet(isDark),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedWallet != null ? color.withValues(alpha: 0.4) : borderColor, width: _selectedWallet != null ? 1 : 0.5),
                  borderRadius: BorderRadius.circular(10),
                  color: _selectedWallet != null ? color.withValues(alpha: 0.04) : Colors.transparent,
                ),
                child: Row(children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 16, color: _selectedWallet != null ? color : AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_selectedWallet?.name ?? 'Select wallet *', style: GoogleFonts.dmSans(fontSize: 14, color: _selectedWallet != null ? textPrimary : AppColors.textSecondary))),
                  Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
                ]),
              ),
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
            if (newProgress != null) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.trending_up_rounded, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text('Will reach ${(newProgress * 100).round()}% of goal', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
                ])),
            ],
            const SizedBox(height: 20),
            SheetActionButton(
              label: amt != null && amt > 0 ? 'Contribute ${currencyFormatter.format(amt, decimalDigits: 2)}' : 'Contribute',
              icon: Icons.add_circle_outline_rounded,
              color: canConfirm ? color : AppColors.textTertiary,
              loading: _loading,
              onTap: !canConfirm ? null : () async {
                final amount = double.tryParse(_amtCtrl.text);
                if (amount == null || amount <= 0 || _selectedWallet == null) return;
                final nav = Navigator.of(context);
                setState(() => _loading = true);
                try {
                  final config = PaymentTxConfig(
                    wallet: _selectedWallet,
                    categoryId: _category?.id,
                    budgetProfileId: _profileId,
                    imagePaths: List.from(_imagePaths),
                    date: _date,
                    description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
                  );
                  _txSaved = true;
                  await widget.onConfirm(amount, config);
                  nav.pop();
                } catch (e, st) {
                  _txSaved = false;
                  debugPrint('[ContributionDrawer] error: $e\n$st');
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
