import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/domain/entities/transaction_plan.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import 'scan_expenses_sheet.dart';

class CreateTransactionSheet extends StatefulWidget {
  final VoidCallback? onCreated;
  final String? initialProfileId;
  final String? initialMonthKey;

  const CreateTransactionSheet({super.key, this.onCreated, this.initialProfileId, this.initialMonthKey});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onCreated,
    String? initialProfileId,
    String? initialMonthKey,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => CreateTransactionSheet(
        onCreated: onCreated,
        initialProfileId: initialProfileId,
        initialMonthKey: initialMonthKey,
      ),
    );
  }

  @override
  State<CreateTransactionSheet> createState() => _CreateTransactionSheetState();
}

class _CreateTransactionSheetState extends State<CreateTransactionSheet> {
  late final TransactionController _txController;
  late final TransactionPlanController _planController;
  late final FinanceCategoryController _catController;
  late final BudgetController _budgetController;
  late final BudgetProfileController _profileController;
  late final MonthPlanController _monthPlanController;
  late final AuthController _authController;
  late final WalletController _walletController;

  TransactionType _type = TransactionType.expense;
  String _amountStr = '0';
  FinanceCategory? _category;
  Wallet? _selectedWallet;
  DateTime _date = DateTime.now();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  bool _showDesc = false;
  bool _isPlan = false;
  bool _categoryError = false;
  bool _profileError = false;
  bool _walletError = false;
  String? _selectedProfileId;
  String? _selectedProfileName;
  String? _selectedPlanMonth;

  @override
  void initState() {
    super.initState();
    _txController = locator.get<TransactionController>();
    _planController = locator.get<TransactionPlanController>();
    _catController = locator.get<FinanceCategoryController>();
    _budgetController = locator.get<BudgetController>();
    _profileController = locator.get<BudgetProfileController>();
    _monthPlanController = locator.get<MonthPlanController>();
    _authController = locator.get<AuthController>();
    _walletController = locator.get<WalletController>();
    _catController.loadCategories();

    // Pre-select profile if provided
    if (widget.initialProfileId != null) {
      final profiles = _profileController.data ?? [];
      final match = profiles.cast<BudgetProfile?>().firstWhere(
        (p) => p?.id == widget.initialProfileId,
        orElse: () => null,
      );
      if (match != null) {
        _selectedProfileId = match.id;
        if (match.isMonthly && widget.initialMonthKey != null) {
          final plans = _monthPlanController.data ?? [];
          final plan = plans.cast<dynamic>().firstWhere(
            (p) => p.budgetProfileId == match.id && p.month == widget.initialMonthKey,
            orElse: () => null,
          );
          if (plan != null) {
            _selectedPlanMonth = plan.month as String;
            final monthDt = DateTime.tryParse('${plan.month}-01');
            final label = monthDt != null ? DateFormat('MMM yyyy').format(monthDt) : plan.month as String;
            _selectedProfileName = '${match.name} – $label';
          } else {
            _selectedProfileName = match.name;
            _selectedPlanMonth = null;
          }
        } else {
          _selectedProfileName = match.name;
          _selectedPlanMonth = null;
        }
      }
    }
  }

  @override
  void dispose() { _descCtrl.dispose(); super.dispose(); }

  double get _amount => double.tryParse(_amountStr) ?? 0;

  String get _displayAmount {
    if (_amountStr == '0') return '0';
    final parts = _amountStr.split('.');
    final intFmt = NumberFormat('#,##0').format(int.tryParse(parts[0]) ?? 0);
    return parts.length == 1 ? intFmt : '$intFmt.${parts[1]}';
  }

  void _numTap(String key) => setState(() {
    switch (key) {
      case '⌫':
        _amountStr = _amountStr.length > 1 ? _amountStr.substring(0, _amountStr.length - 1) : '0';
      case '.':
        if (!_amountStr.contains('.')) _amountStr += '.';
      case '00':
        if (_amountStr != '0') _amountStr += '00';
      default:
        final next = _amountStr == '0' ? key : _amountStr + key;
        final parts = next.split('.');
        if (parts.length == 2 && parts[1].length > 2) return;
        _amountStr = next;
    }
  });

  Color get _typeColor => _type == TransactionType.income ? AppColors.success : AppColors.error;

  // Find the planned amount for the selected category in the current month
  double get _plannedAmount {
    if (_category?.id == null) return 0;
    final state = _budgetController.state;
    if (state is! AsyncData<List<Budget>>) return 0;
    final now = DateTime.now();
    final mk = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    for (final b in state.data) {
      if (b.month != mk || b.status != BudgetStatus.active) continue;
      for (final cat in b.categories) {
        if (cat.financeCategoryId == _category!.id) return cat.targetAmount;
      }
    }
    return 0;
  }

  // Compute already-spent for selected category this month from loaded transactions
  double get _alreadySpent {
    if (_category?.id == null) return 0;
    final state = _txController.state;
    if (state is! AsyncData<List<Transaction>>) return 0;
    final now = DateTime.now();
    return state.data
        .where((t) => t.financeCategoryId == _category!.id && t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  Future<void> _submit() async {
    if (_selectedProfileId == null) {
      setState(() => _profileError = true);
      return;
    }
    if (_category == null) {
      setState(() => _categoryError = true);
      return;
    }
    if (_selectedWallet == null) {
      setState(() => _walletError = true);
      return;
    }
    if (_amount <= 0) return;
    if (_isPlan && _descCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      if (_isPlan) {
        await _planController.createPlan(TransactionPlan(
          userId: _authController.currentUser?.id ?? '',
          description: _descCtrl.text.trim(),
          amount: _amount,
          type: _type,
          plannedDate: _date,
          financeCategoryId: _category!.id,
        ));
      } else {
        final desc = _descCtrl.text.trim();
        final autoDesc = _type == TransactionType.income
            ? 'Earns ${_category!.name}'
            : 'Pays ${_category!.name}';
        await _txController.createTransaction(Transaction(
          amount: _amount,
          type: _type,
          financeCategoryId: _category!.id,
          date: _date,
          description: desc.isEmpty ? autoDesc : desc,
          budgetProfileId: _selectedProfileId,
          walletId: _selectedWallet!.id,
        ));
      }
      widget.onCreated?.call();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Set<String>? get _allowedCategoryIds {
    if (_selectedProfileId == null) return null;
    final s = _budgetController.state;
    if (s is! AsyncData<List<Budget>>) return null;
    final ids = s.data.where((b) {
      if (b.budgetProfileId != _selectedProfileId) return false;
      if (_selectedPlanMonth != null) return b.month == _selectedPlanMonth && b.status == BudgetStatus.active;
      return b.status == BudgetStatus.active;
    }).expand((b) => b.categories.map((c) => c.financeCategoryId)).toSet();
    return ids.isEmpty ? null : ids;
  }

  void _pickBudgetProfile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profiles = _profileController.data ?? <BudgetProfile>[];
    final plans = _monthPlanController.data ?? [];
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    // Build picker items: monthly profiles → one entry per open plan; custom → one entry per profile
    final items = <({String label, String profileId, String? planMonth})>[];
    for (final p in profiles) {
      if (!p.isActive) continue;
      if (p.isMonthly) {
        final profilePlans = plans
            .where((pl) => pl.budgetProfileId == p.id && !pl.isClosed && pl.month != null)
            .toList()
          ..sort((a, b) => (b.month ?? '').compareTo(a.month ?? ''));
        if (profilePlans.isEmpty) {
          items.add((label: p.name, profileId: p.id!, planMonth: null));
        } else {
          for (final pl in profilePlans) {
            final monthDt = DateTime.tryParse('${pl.month!}-01');
            final monthLabel = monthDt != null ? DateFormat('MMM yyyy').format(monthDt) : pl.month!;
            items.add((label: '${p.name} – $monthLabel', profileId: p.id!, planMonth: pl.month));
          }
        }
      } else {
        items.add((label: p.name, profileId: p.id!, planMonth: null));
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text('Select Budget', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: fg))),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final sel = _selectedProfileId == item.profileId && _selectedPlanMonth == item.planMonth;
                return ListTile(
                  title: Text(item.label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: fg)),
                  trailing: sel ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
                  onTap: () {
                    setState(() {
                      _selectedProfileId = item.profileId;
                      _selectedProfileName = item.label;
                      _selectedPlanMonth = item.planMonth;
                      _category = null;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  void _pickCategory() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionCategoryPicker(
        type: _type,
        selectedId: _category?.id,
        controller: _catController,
        allowedIds: _allowedCategoryIds,
        isDark: isDark,
        onSelect: (cat) {
          setState(() { _category = cat; _categoryError = false; });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _pickWallet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallets = _walletController.data ?? [];
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text('Select Wallet', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: fg))),
          if (wallets.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Text('No wallets yet. Create one in the Wallet tab.', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: wallets.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: borderColor, indent: 16, endIndent: 16),
                itemBuilder: (_, i) {
                  final w = wallets[i];
                  final sel = _selectedWallet?.id == w.id;
                  final wColor = w.colorHex != null
                      ? Color(int.parse(w.colorHex!.replaceFirst('#', '0xff')))
                      : AppColors.accent;
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: wColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                      alignment: Alignment.center,
                      child: Icon(
                        w.type == WalletType.creditCard ? Icons.credit_card_outlined : Icons.account_balance_wallet_outlined,
                        size: 16, color: wColor,
                      ),
                    ),
                    title: Text(w.name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: fg)),
                    subtitle: Text(
                      '${currencyFormatter.format(w.balance, decimalDigits: 2)} • ${w.type.displayName}',
                      style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    trailing: sel ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
                    onTap: () {
                      setState(() { _selectedWallet = w; _walletError = false; });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  void _pickDate() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DatePickerSheet(
        selected: _date,
        isDark: isDark,
        allowFuture: _isPlan,
        onSelect: (d) { setState(() => _date = d); Navigator.pop(context); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_date, now);
    final isYesterday = DateUtils.isSameDay(_date, now.subtract(const Duration(days: 1)));
    final dateLabel = isToday ? 'Today' : isYesterday ? 'Yesterday' : DateFormat('MMM d').format(_date);
    final addLabel = _isPlan
        ? (_amount > 0 ? 'Plan  ₱$_displayAmount' : 'Plan Transaction')
        : (_amount > 0 ? 'Add  ₱$_displayAmount' : 'Add Transaction');
    final planned = _plannedAmount;
    final spent = _alreadySpent;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
        ),
        // Type selector + Plan toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            _TypePill(label: 'Expense', color: AppColors.error, selected: _type == TransactionType.expense, onTap: () => setState(() { _type = TransactionType.expense; _category = null; _categoryError = false; })),
            const SizedBox(width: 8),
            _TypePill(label: 'Income', color: AppColors.success, selected: _type == TransactionType.income, onTap: () => setState(() { _type = TransactionType.income; _category = null; _categoryError = false; })),
            const Spacer(),
            _PlanTogglePill(
              active: _isPlan,
              onTap: () => setState(() {
                _isPlan = !_isPlan;
                if (_isPlan) {
                  _showDesc = true;
                  _date = DateTime.now().add(const Duration(days: 1));
                } else {
                  _showDesc = false;
                  _date = DateTime.now();
                }
              }),
            ),
          ]),
        ),
        // Amount display
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₱', style: GoogleFonts.dmMono(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            Expanded(child: Text(_displayAmount,
                style: GoogleFonts.dmMono(fontSize: 44, fontWeight: FontWeight.w700,
                    color: _amount > 0 ? _typeColor : AppColors.textTertiary,
                    letterSpacing: -1, fontFeatures: const [FontFeature.tabularFigures()]),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
        // Budget + Category + Date + Note chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            _Chip(
              icon: Icons.account_balance_wallet_outlined,
              label: _selectedProfileName ?? 'Budget *',
              color: _profileError ? AppColors.error : (_selectedProfileId != null ? AppColors.accent : AppColors.textSecondary),
              isDark: isDark,
              highlighted: _profileError,
              onTap: () { setState(() => _profileError = false); _pickBudgetProfile(); },
            ),
            const SizedBox(width: 8),
            _Chip(
              icon: _category == null ? Icons.grid_view_rounded : null,
              label: _category?.name ?? 'Category *',
              color: _selectedProfileId == null
                  ? AppColors.textDisabled
                  : (_categoryError ? AppColors.error : (_category != null ? _typeColor : AppColors.textSecondary)),
              isDark: isDark,
              highlighted: _categoryError,
              onTap: _selectedProfileId == null ? null : _pickCategory,
            ),
            const SizedBox(width: 8),
            _Chip(
              icon: _selectedWallet == null
                  ? Icons.account_balance_wallet_outlined
                  : (_selectedWallet!.type == WalletType.creditCard ? Icons.credit_card_outlined : Icons.account_balance_wallet_outlined),
              label: _selectedWallet?.name ?? 'Wallet *',
              color: _walletError ? AppColors.error : (_selectedWallet != null ? AppColors.accent : AppColors.textSecondary),
              isDark: isDark,
              highlighted: _walletError,
              onTap: () { setState(() => _walletError = false); _pickWallet(); },
            ),
            const SizedBox(width: 8),
            _Chip(icon: Icons.calendar_today_outlined, label: dateLabel, color: isToday ? AppColors.textSecondary : AppColors.accent, isDark: isDark, onTap: _pickDate),
            if (!_isPlan) ...[
              const SizedBox(width: 8),
              _Chip(icon: _showDesc ? Icons.edit_off_outlined : Icons.edit_outlined, label: 'Note', color: AppColors.textSecondary, isDark: isDark, onTap: () => setState(() => _showDesc = !_showDesc)),
            ],
          ]),
        ),
        // Planned indicator (item 6)
        if (_category != null && planned > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _PlannedIndicator(spent: spent, planned: planned, color: _typeColor, isDark: isDark),
          ),
        // Description
        if (_showDesc || _isPlan)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _descCtrl, autofocus: _isPlan, maxLines: 1,
              style: GoogleFonts.dmSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: _isPlan ? 'Name *' : 'Add a note…',
                hintStyle: GoogleFonts.dmSans(color: AppColors.textTertiary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
            ),
          ),
        // Scan from image banner
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScanExpensesSheet.show(context, onConfirmed: widget.onCreated);
            });
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: isDark ? 0.12 : 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.25), width: 0.5),
            ),
            child: Row(children: [
              Icon(Icons.document_scanner_outlined, size: 18, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Scan expenses from image',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.accent.withValues(alpha: 0.6)),
            ]),
          ),
        ),
        Divider(height: 20, color: borderColor),
        // Numpad
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _Numpad(onTap: _numTap)),
        // Add button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _amount > 0 && _category != null && (_isPlan || _selectedWallet != null)
                    ? (_isPlan ? AppColors.accent : _typeColor)
                    : AppColors.textTertiary,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(addLabel, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        SafeArea(top: false, child: const SizedBox.shrink()),
      ]),
    );
  }
}

// ─── Planned Indicator ────────────────────────────────────────────────────────

class _PlannedIndicator extends StatelessWidget {
  final double spent, planned;
  final Color color;
  final bool isDark;

  const _PlannedIndicator({required this.spent, required this.planned, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final remaining = (planned - spent).clamp(0.0, double.infinity);
    final isOver = spent > planned;
    final bg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(Icons.bar_chart_rounded, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text('Budget: ${currencyFormatter.format(planned, decimalDigits: 0)}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Text('·', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(width: 8),
        Text(isOver ? 'Over by ${currencyFormatter.format(spent - planned, decimalDigits: 0)}' : '${currencyFormatter.format(remaining, decimalDigits: 0)} left',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: isOver ? AppColors.error : color)),
      ]),
    );
  }
}

// ─── Numpad ───────────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  final void Function(String) onTap;
  const _Numpad({required this.onTap});

  static const _rows = [
    ['7', '8', '9', '⌫'],
    ['4', '5', '6', ''],
    ['1', '2', '3', '.'],
    ['00', '0', '', ''],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: _rows.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: row.asMap().entries.map((e) {
          final k = e.value;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(left: e.key > 0 ? 6 : 0),
            child: k.isEmpty ? const SizedBox.shrink() : _NumKey(label: k, onTap: () => onTap(k), isDark: isDark),
          ));
        }).toList()),
      )).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  const _NumKey({required this.label, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isBack = label == '⌫';
    final bg = isDark ? Colors.white.withValues(alpha: 0.07) : AppColors.background;
    final fg = isBack ? AppColors.error : (isDark ? AppColors.primaryForeground : AppColors.textPrimary);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: isBack
            ? Icon(Icons.backspace_outlined, size: 20, color: fg)
            : Text(label, style: GoogleFonts.dmMono(fontSize: 20, fontWeight: FontWeight.w500, color: fg)),
      ),
    );
  }
}

// ─── Custom Date Picker ───────────────────────────────────────────────────────

class _DatePickerSheet extends StatefulWidget {
  final DateTime selected;
  final bool isDark;
  final bool allowFuture;
  final void Function(DateTime) onSelect;
  const _DatePickerSheet({required this.selected, required this.isDark, this.allowFuture = false, required this.onSelect});

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _view;

  @override
  void initState() {
    super.initState();
    _view = DateTime(widget.selected.year, widget.selected.month);
  }

  void _prev() => setState(() => _view = DateTime(_view.year, _view.month - 1));
  void _next() {
    if (widget.allowFuture) {
      setState(() => _view = DateTime(_view.year, _view.month + 1));
      return;
    }
    final now = DateTime.now();
    final next = DateTime(_view.year, _view.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) setState(() => _view = next);
  }

  bool get _canGoNext {
    if (widget.allowFuture) return true;
    final now = DateTime.now();
    return _view.year < now.year || (_view.year == now.year && _view.month < now.month);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final now = DateTime.now();
    final firstDay = DateTime(_view.year, _view.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_view.year, _view.month);
    final startOffset = firstDay.weekday % 7; // 0=Sun

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
        // Month/year nav
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(icon: Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary), onPressed: _prev, padding: EdgeInsets.zero),
            Text(DateFormat('MMMM yyyy').format(_view),
                style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
            IconButton(icon: Icon(Icons.chevron_right_rounded, color: _canGoNext ? AppColors.textSecondary : AppColors.textTertiary), onPressed: _canGoNext ? _next : null, padding: EdgeInsets.zero),
          ]),
        ),
        Divider(height: 1, color: borderColor),
        // Day of week headers
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Expanded(child: Center(
              child: Text(d, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
          ))).toList()),
        ),
        // Calendar grid
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 40),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startOffset) return const SizedBox.shrink();
              final day = i - startOffset + 1;
              final date = DateTime(_view.year, _view.month, day);
              final isSelected = DateUtils.isSameDay(date, widget.selected);
              final isToday = DateUtils.isSameDay(date, now);
              final isFuture = !widget.allowFuture && date.isAfter(now);
              Color textColor = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
              if (isFuture) textColor = AppColors.textTertiary;
              if (isSelected) textColor = Colors.white;

              return GestureDetector(
                onTap: isFuture ? null : () => widget.onSelect(date),
                child: Center(
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected ? Border.all(color: AppColors.accent, width: 1.5) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text('$day', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400, color: textColor)),
                  ),
                ),
              );
            },
          ),
        ),
      ])),
    );
  }
}

// ─── Category Picker ──────────────────────────────────────────────────────────

class TransactionCategoryPicker extends StatelessWidget {
  final TransactionType type;
  final String? selectedId;
  final FinanceCategoryController controller;
  final Set<String>? allowedIds;
  final bool isDark;
  final void Function(FinanceCategory) onSelect;
  const TransactionCategoryPicker({super.key, required this.type, required this.selectedId, required this.controller, this.allowedIds, required this.isDark, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final targetType = type == TransactionType.income ? CategoryType.income : CategoryType.expense;

    return DraggableScrollableSheet(
      expand: false, initialChildSize: 0.55, maxChildSize: 0.85,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 10), child: Row(children: [
            Text('Select Category', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
            const Spacer(),
            GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
          ])),
          Divider(height: 1, color: divColor),
          Expanded(
            child: AsyncStreamBuilder<List<FinanceCategory>>(
              state: controller,
              builder: (_, cats) {
                var filtered = cats
                    .where((c) => c.type == targetType && !c.isArchive)
                    .where((c) => allowedIds == null || (c.id != null && allowedIds!.contains(c.id)))
                    .toList()..sort((a, b) => a.name.compareTo(b.name));
                if (filtered.isEmpty) return Center(child: Text('No categories found', style: GoogleFonts.dmSans(color: AppColors.textSecondary)));
                final color = targetType == CategoryType.income ? AppColors.success : AppColors.error;
                return ListView.separated(
                  controller: ctrl, padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: divColor, indent: 16, endIndent: 16),
                  itemBuilder: (_, i) {
                    final cat = filtered[i];
                    final isSel = cat.id == selectedId;
                    return ListTile(
                      dense: true,
                      leading: Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(targetType == CategoryType.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 15, color: color)),
                      title: Text(cat.name, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400, color: textPrimary)),
                      trailing: isSel ? Icon(Icons.check_rounded, size: 18, color: AppColors.accent) : null,
                      onTap: () => onSelect(cat),
                    );
                  },
                );
              },
              loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _PlanTogglePill extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _PlanTogglePill({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.event_note_outlined, size: 12, color: active ? AppColors.accent : AppColors.textSecondary),
        const SizedBox(width: 5),
        Text('Plan', style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          color: active ? AppColors.accent : AppColors.textSecondary,
        )),
      ]),
    ),
  );
}

class _TypePill extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypePill({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(color: selected ? color : color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? Colors.white : color)),
    ),
  );
}

class _Chip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool highlighted;
  final VoidCallback? onTap;
  const _Chip({required this.label, required this.color, required this.isDark, required this.onTap, this.icon, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final bg = highlighted
        ? AppColors.error.withValues(alpha: 0.08)
        : (isDark ? Colors.white.withValues(alpha: 0.07) : AppColors.background);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: highlighted ? Border.all(color: AppColors.error.withValues(alpha: 0.4)) : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon!, size: 13, color: color), const SizedBox(width: 4)],
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}
