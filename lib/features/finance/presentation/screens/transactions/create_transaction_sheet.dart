import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/finance/modules/wallet/data/models/wallet_model.dart';
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
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/finance_category.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/add_debts_sheet.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/add_subscription_sheet.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/presentation/screens/configuration/goals/widgets/goals_management_dialog.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';
import 'package:uuid/uuid.dart';
import 'scan_expenses_sheet.dart';

class CreateTransactionSheet extends StatefulWidget {
  final VoidCallback? onCreated;
  final String? initialProfileId;
  final String? initialMonthKey;

  const CreateTransactionSheet({
    super.key,
    this.onCreated,
    this.initialProfileId,
    this.initialMonthKey,
  });

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

class _SplitEntry {
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();
  TransactionType type;
  FinanceCategory? category;
  DateTime date = DateTime.now();
  String? profileId;
  String? profileName;
  String? walletId;
  String? walletName;
  String? entityType; // "debt_payment" | "lending" | "goal" | "subscription"
  String? entityLabel;
  String? debtId;
  String? goalId;
  String? subscriptionId;

  bool isPlan = false;
  List<String> imagePaths = [];
  final String id = const Uuid().v4();

  _SplitEntry({required this.type});

  double get amount => double.tryParse(amountCtrl.text) ?? 0;
  bool get isValid =>
      amount > 0 && (isPlan || category != null || entityType != null);

  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
  }
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
  final TextEditingController _amountCtrl = TextEditingController();
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

  bool _splitMode = false;
  final List<_SplitEntry> _splitEntries = [];

  // Image attachments
  late String _pendingTxId;
  final List<String> _imagePaths = [];
  bool _created = false;

  // Entity linking (non-split mode)
  late final DebtController _debtController;
  late final GoalController _goalController;
  late final SubscriptionController _subController;
  String? _entityType;
  String? _entityLabel;
  String? _debtId;
  String? _goalId;
  String? _subscriptionId;

  @override
  void initState() {
    super.initState();
    _pendingTxId = const Uuid().v4();
    _txController = locator.get<TransactionController>();
    _planController = locator.get<TransactionPlanController>();
    _catController = locator.get<FinanceCategoryController>();
    _budgetController = locator.get<BudgetController>();
    _profileController = locator.get<BudgetProfileController>();
    _monthPlanController = locator.get<MonthPlanController>();
    _authController = locator.get<AuthController>();
    _walletController = locator.get<WalletController>();
    _debtController = locator.get<DebtController>();
    _goalController = locator.get<GoalController>();
    _subController = locator.get<SubscriptionController>();
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
            (p) =>
                p.budgetProfileId == match.id &&
                p.month == widget.initialMonthKey,
            orElse: () => null,
          );
          if (plan != null) {
            _selectedPlanMonth = plan.month as String;
            final monthDt = DateTime.tryParse('${plan.month}-01');
            final label = monthDt != null
                ? DateFormat('MMM yyyy').format(monthDt)
                : plan.month as String;
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
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    if (!_created) {
      TransactionImageService.deleteAll(_pendingTxId).ignore();
      for (final e in _splitEntries) {
        TransactionImageService.deleteAll(e.id).ignore();
      }
    }
    for (final e in _splitEntries) e.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;

  double get _splitTotal => _splitEntries.fold(0.0, (s, e) => s + e.amount);

  bool get _splitBalanced =>
      _splitEntries.isNotEmpty &&
      (_splitTotal - _amount).abs() < 0.01 &&
      _splitEntries.every((e) => e.isValid);

  void _toggleSplit() {
    setState(() {
      _splitMode = !_splitMode;
      if (_splitMode) {
        for (final e in _splitEntries) {
          TransactionImageService.deleteAll(e.id).ignore();
          e.dispose();
        }
        _splitEntries.clear();
        _splitEntries.add(
          _SplitEntry(type: _type)..amountCtrl.text = _amountCtrl.text,
        );
      } else {
        for (final e in _splitEntries) {
          TransactionImageService.deleteAll(e.id).ignore();
          e.dispose();
        }
        _splitEntries.clear();
      }
    });
  }

  void _addSplitEntry() {
    setState(() => _splitEntries.add(_SplitEntry(type: _type)));
  }

  void _removeSplitEntry(int index) {
    final entry = _splitEntries[index];
    TransactionImageService.deleteAll(entry.id).ignore();
    setState(() {
      entry.dispose();
      _splitEntries.removeAt(index);
    });
  }

  Future<void> _pickSplitCategory(int index) async {
    final entry = _splitEntries[index];
    final monthKey =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final allCats = _catController.data ?? [];
    final groups = buildGroupedCategories(
      allCategories: allCats,
      allBudgets: _budgetController.data ?? [],
      targetType: entry.type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense,
      monthKey: monthKey,
    );
    final picked = await showGroupedCategoryDialog(
      context,
      groups: groups,
      selectedId: entry.category?.id,
    );
    if (picked != null) setState(() => entry.category = picked);
  }

  Color get _typeColor =>
      _type == TransactionType.income ? AppColors.success : AppColors.error;

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
        .where(
          (t) =>
              t.financeCategoryId == _category!.id &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (s, t) => s + t.amount);
  }

  Future<void> _submit() async {
    if (_selectedWallet == null) {
      setState(() => _walletError = true);
      return;
    }
    if (_amount <= 0) return;

    if (_splitMode) {
      if (!_splitBalanced) return;
      setState(() => _loading = true);
      try {
        final walletDeltas = <String, double>{};
        for (final entry in _splitEntries) {
          final note = entry.noteCtrl.text.trim();
          if (entry.isPlan) {
            await _planController.createPlan(
              TransactionPlan(
                userId: _authController.currentUser?.id ?? '',
                description: note.isNotEmpty
                    ? note
                    : '${entry.type.displayName} plan',
                amount: entry.amount,
                type: entry.type,
                plannedDate: entry.date,
                financeCategoryId: entry.category?.id,
              ),
            );
            continue;
          }
          final wid = entry.walletId ?? _selectedWallet?.id ?? '';
          if (wid.isEmpty) continue;
          final autoDesc = entry.entityLabel != null
              ? (entry.type == TransactionType.income
                    ? 'From ${entry.entityLabel}'
                    : 'To ${entry.entityLabel}')
              : (entry.type == TransactionType.income
                    ? 'Earns ${entry.category?.name ?? ''}'
                    : 'Pays ${entry.category?.name ?? ''}');
          await _txController.createTransaction(
            Transaction(
              id: entry.id,
              amount: entry.amount,
              type: entry.type,
              financeCategoryId: entry.entityType != null
                  ? null
                  : entry.category?.id,
              date: entry.date,
              description: note.isNotEmpty ? note : autoDesc,
              budgetProfileId: entry.profileId ?? _selectedProfileId,
              walletId: wid,
              debtId: entry.debtId,
              goalId: entry.goalId,
              subscriptionId: entry.subscriptionId,
              imagePaths: entry.imagePaths,
            ),
          );
          await _applyEntityEffect(
            entityType: entry.entityType,
            transactionType: entry.type,
            amount: entry.amount,
            debtId: entry.debtId,
            goalId: entry.goalId,
          );
          final allWallets = _walletController.data ?? [];
          final w = allWallets.firstWhere(
            (w) => w.id == wid,
            orElse: () => WalletModel.fromEntity(_selectedWallet!),
          );
          final delta = w.type == WalletType.creditCard
              ? (entry.type == TransactionType.income
                    ? -entry.amount
                    : entry.amount)
              : (entry.type == TransactionType.income
                    ? entry.amount
                    : -entry.amount);
          walletDeltas[wid] = (walletDeltas[wid] ?? 0) + delta;
        }
        final allWallets = _walletController.data ?? [];
        for (final kv in walletDeltas.entries) {
          final w = allWallets.firstWhere(
            (w) => w.id == kv.key,
            orElse: () => WalletModel.fromEntity(_selectedWallet!),
          );
          await _walletController.updateWallet(
            w.copyWith(balance: w.balance + kv.value),
          );
        }
        _created = true;
        widget.onCreated?.call();
        if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    if (_entityType == null && _category == null) {
      setState(() => _categoryError = true);
      return;
    }
    if (_isPlan && _descCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      if (_isPlan) {
        await _planController.createPlan(
          TransactionPlan(
            userId: _authController.currentUser?.id ?? '',
            description: _descCtrl.text.trim(),
            amount: _amount,
            type: _type,
            plannedDate: _date,
            financeCategoryId: _category?.id,
          ),
        );
      } else {
        final desc = _descCtrl.text.trim();
        final autoDesc = _entityLabel != null
            ? (_type == TransactionType.income
                  ? 'From $_entityLabel'
                  : 'To $_entityLabel')
            : (_type == TransactionType.income
                  ? 'Earns ${_category!.name}'
                  : 'Pays ${_category!.name}');
        await _txController.createTransaction(
          Transaction(
            id: _pendingTxId,
            amount: _amount,
            type: _type,
            financeCategoryId: _entityType != null ? null : _category?.id,
            date: _date,
            description: desc.isEmpty ? autoDesc : desc,
            budgetProfileId: _selectedProfileId,
            walletId: _selectedWallet!.id,
            debtId: _debtId,
            goalId: _goalId,
            subscriptionId: _subscriptionId,
            imagePaths: _imagePaths,
          ),
        );
        await _applyEntityEffect(
          entityType: _entityType,
          transactionType: _type,
          amount: _amount,
          debtId: _debtId,
          goalId: _goalId,
        );
        final wallet = _selectedWallet!;
        final delta = wallet.type == WalletType.creditCard
            ? (_type == TransactionType.income ? -_amount : _amount)
            : (_type == TransactionType.income ? _amount : -_amount);
        await _walletController.updateWallet(
          wallet.copyWith(balance: wallet.balance + delta),
        );
      }
      _created = true;
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
    final ids = s.data
        .where((b) {
          if (b.budgetProfileId != _selectedProfileId) return false;
          if (_selectedPlanMonth != null)
            return b.month == _selectedPlanMonth &&
                b.status == BudgetStatus.active;
          return b.status == BudgetStatus.active;
        })
        .expand((b) => b.categories.map((c) => c.financeCategoryId))
        .toSet();
    return ids.isEmpty ? null : ids;
  }

  void _pickBudgetProfile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profiles = _profileController.data ?? <BudgetProfile>[];
    final plans = _monthPlanController.data ?? [];
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    // Build picker items: monthly profiles → one entry per open plan; custom → one entry per profile
    final items = <({String label, String profileId, String? planMonth})>[];
    for (final p in profiles) {
      if (!p.isActive) continue;
      if (p.isMonthly) {
        final profilePlans =
            plans
                .where(
                  (pl) =>
                      pl.budgetProfileId == p.id &&
                      !pl.isClosed &&
                      pl.month != null,
                )
                .toList()
              ..sort((a, b) => (b.month ?? '').compareTo(a.month ?? ''));
        if (profilePlans.isEmpty) {
          items.add((label: p.name, profileId: p.id!, planMonth: null));
        } else {
          for (final pl in profilePlans) {
            final monthDt = DateTime.tryParse('${pl.month!}-01');
            final monthLabel = monthDt != null
                ? DateFormat('MMM yyyy').format(monthDt)
                : pl.month!;
            items.add((
              label: '${p.name} – $monthLabel',
              profileId: p.id!,
              planMonth: pl.month,
            ));
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
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(
                  'Select Budget',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.block_outlined,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      title: Text(
                        'No budget',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: _selectedProfileId == null
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.accent,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedProfileId = null;
                          _selectedProfileName = null;
                          _selectedPlanMonth = null;
                          _category = null;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ...items.map((item) {
                      final sel =
                          _selectedProfileId == item.profileId &&
                          _selectedPlanMonth == item.planMonth;
                      return ListTile(
                        title: Text(
                          item.label,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                            color: fg,
                          ),
                        ),
                        trailing: sel
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.accent,
                              )
                            : null,
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
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
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
          setState(() {
            _category = cat;
            _categoryError = false;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _pickWallet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallets = _walletController.data ?? [];
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
                child: Text(
                  'Select Wallet',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _type == TransactionType.income
                      ? 'The amount will be added to the selected wallet.'
                      : 'The amount will be deducted from the selected wallet.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (wallets.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Text(
                    'No wallets yet. Create one in the Wallet tab.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: wallets.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: borderColor,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (_, i) {
                      final w = wallets[i];
                      final sel = _selectedWallet?.id == w.id;
                      final wColor = w.colorHex != null
                          ? Color(
                              int.parse(w.colorHex!.replaceFirst('#', '0xff')),
                            )
                          : AppColors.accent;
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: wColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            w.type == WalletType.creditCard
                                ? Icons.credit_card_outlined
                                : Icons.account_balance_wallet_outlined,
                            size: 16,
                            color: wColor,
                          ),
                        ),
                        title: Text(
                          w.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                            color: fg,
                          ),
                        ),
                        subtitle: Text(
                          '${currencyFormatter.format(w.balance, decimalDigits: 2)} • ${w.type.displayName}',
                          style: GoogleFonts.dmMono(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: sel
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.accent,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedWallet = w;
                            _walletError = false;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
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
        onSelect: (d) {
          setState(() => _date = d);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _applyEntityEffect({
    required String? entityType,
    required TransactionType transactionType,
    required double amount,
    required String? debtId,
    required String? goalId,
  }) async {
    final shouldPayDebt =
        debtId != null &&
        (entityType == 'debt_payment' ||
            (entityType == 'lending' &&
                transactionType == TransactionType.income));

    if (shouldPayDebt) {
      final updated = await _debtController.payDebt(debtId!, amount: amount);
      if (updated.remainingAmount <= 0 &&
          updated.status != DebtStatus.settled) {
        await _debtController.settleDebt(debtId);
      }
    }

    if (goalId != null && entityType == 'goal') {
      await _goalController.contributeToGoal(goalId, amount);
    }
  }

  Future<void> _pickImageFor(
    String txId,
    List<String> target,
    VoidCallback onUpdate,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('Gallery', style: GoogleFonts.dmSans(fontSize: 14)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text('Camera', style: GoogleFonts.dmSans(fontSize: 14)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final path = await TransactionImageService.pickImage(txId, source: source);
    if (path != null) {
      target.add(path);
      onUpdate();
    }
  }

  Future<void> _pickImage() =>
      _pickImageFor(_pendingTxId, _imagePaths, () => setState(() {}));

  Future<void> _pickSplitImage(int index) async {
    final entry = _splitEntries[index];
    if (entry.imagePaths.isEmpty) {
      return _pickImageFor(entry.id, entry.imagePaths, () => setState(() {}));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSS) => Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _AttachmentList(
                  imagePaths: entry.imagePaths,
                  onRemove: (path) {
                    TransactionImageService.deleteImage(path).ignore();
                    setSS(() => entry.imagePaths.remove(path));
                    setState(() {});
                  },
                  onView: (path) => _ImageViewerDialog.show(ctx, path),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _pickImageFor(
                        entry.id,
                        entry.imagePaths,
                        () => setState(() {}),
                      );
                    },
                    icon: const Icon(Icons.attach_file_rounded, size: 15),
                    label: const Text('Add attachment'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(
                        color: AppColors.textTertiary.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isMainCreateOnly(String type) {
    if (type == 'debt_received') return true;
    if (type == 'lending') return _type == TransactionType.expense;
    return false;
  }

  String _entityDescription(String type) => switch (type) {
    'debt_payment' => 'Pay back an existing debt',
    'lending' =>
      _type == TransactionType.income
          ? 'Select which receivable was collected'
          : 'Record money you lent — creates a new receivable',
    'debt_received' => 'Record a loan you received — creates a new debt',
    'goal' => 'Contribute toward a savings goal',
    'subscription' => 'Log a subscription payment — auto-fills amount',
    _ => '',
  };

  String? _buildEntityMeta() {
    if (_entityType == null) return null;
    if (_debtId != null) {
      final debt = _debtController.data
          ?.where((d) => d.id == _debtId)
          .firstOrNull;
      if (debt == null) return null;
      return _entityType == 'debt_payment'
          ? 'Still owe ${currencyFormatter.format(debt.remainingAmount)} to ${debt.personName}'
          : 'Expecting ${currencyFormatter.format(debt.remainingAmount)} from ${debt.personName}';
    }
    if (_goalId != null) {
      final goal = _goalController.data
          ?.where((g) => g.id == _goalId)
          .firstOrNull;
      if (goal == null) return null;
      final remaining = (goal.targetAmount - goal.currentAmount).clamp(
        0.0,
        double.infinity,
      );
      return '${currencyFormatter.format(goal.currentAmount)} of ${currencyFormatter.format(goal.targetAmount)} saved · ${currencyFormatter.format(remaining)} to go';
    }
    if (_subscriptionId != null) {
      final sub = _subController.data
          ?.where((s) => s.id == _subscriptionId)
          .firstOrNull;
      if (sub == null) return null;
      return '${currencyFormatter.format(sub.amount)} recurring';
    }
    return null;
  }

  void _pickMainEntity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    final isIncome = _type == TransactionType.income;
    final types = isIncome
        ? [
            (
              type: 'lending',
              icon: Icons.arrow_downward_rounded,
              label: 'Receivable Collected',
              color: AppColors.success,
            ),
            (
              type: 'debt_received',
              icon: Icons.arrow_downward_rounded,
              label: 'Loan Received',
              color: AppColors.error,
            ),
          ]
        : [
            (
              type: 'debt_payment',
              icon: Icons.arrow_upward_rounded,
              label: 'Debt Payment',
              color: AppColors.error,
            ),
            (
              type: 'lending',
              icon: Icons.arrow_downward_rounded,
              label: 'New Receivable',
              color: AppColors.success,
            ),
            (
              type: 'goal',
              icon: Icons.flag_outlined,
              label: 'Goal',
              color: AppColors.accent,
            ),
            (
              type: 'subscription',
              icon: Icons.autorenew_rounded,
              label: 'Subscription',
              color: AppColors.info,
            ),
          ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Link To',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.link_off_rounded,
                          color: AppColors.textTertiary,
                          size: 18,
                        ),
                        title: Text(
                          'None',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: textPrimary,
                          ),
                        ),
                        trailing: _entityType == null
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.accent,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _entityType = null;
                            _entityLabel = null;
                            _debtId = null;
                            _goalId = null;
                            _subscriptionId = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ...types.map(
                        (t) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(t.icon, color: t.color, size: 18),
                          title: Text(
                            t.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            _entityDescription(t.type),
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: _entityType == t.type
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: AppColors.accent,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _entityType = t.type;
                              _entityLabel = null;
                              _debtId = null;
                              _goalId = null;
                              _subscriptionId = null;
                              _category = null;
                            });
                            Navigator.pop(context);
                            if (_isMainCreateOnly(t.type)) {
                              _addMainEntityInline(
                                t.type,
                                (id, label) => setState(() {
                                  _entityLabel = label;
                                  _debtId = id;
                                }),
                              );
                            } else {
                              _pickMainEntityItem(t.type);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickMainEntityItem(String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;

    List<({String id, String label, String amount})> items;
    if (type == 'debt_payment' || type == 'debt_received') {
      final debtType = type == 'debt_received'
          ? DebtType.lending
          : DebtType.borrowing;
      items = (_debtController.data ?? [])
          .where((d) => d.type == debtType && d.status != DebtStatus.settled)
          .map(
            (d) => (
              id: d.id!,
              label: d.personName,
              amount: type == 'debt_received'
                  ? 'Expecting ${currencyFormatter.format(d.remainingAmount)}'
                  : 'Still owe ${currencyFormatter.format(d.remainingAmount)}',
            ),
          )
          .toList();
    } else if (type == 'lending') {
      items = (_debtController.data ?? [])
          .where(
            (d) => d.type == DebtType.lending && d.status != DebtStatus.settled,
          )
          .map(
            (d) => (
              id: d.id!,
              label: d.personName,
              amount:
                  'Expecting ${currencyFormatter.format(d.remainingAmount)}',
            ),
          )
          .toList();
    } else if (type == 'goal') {
      items = (_goalController.data ?? [])
          .where((g) => !g.isCompleted)
          .map(
            (g) => (
              id: g.id!,
              label: g.name,
              amount:
                  '${currencyFormatter.format(g.currentAmount)} of ${currencyFormatter.format(g.targetAmount)} saved',
            ),
          )
          .toList();
    } else {
      items = (_subController.data ?? [])
          .map(
            (s) => (
              id: s.id!,
              label: s.name,
              amount: '${currencyFormatter.format(s.amount)} recurring',
            ),
          )
          .toList();
    }

    final canAdd =
        type == 'lending' ||
        type == 'debt_received' ||
        type == 'goal' ||
        type == 'subscription';
    final addLabel = switch (type) {
      'lending' => 'New Receivable',
      'debt_received' => 'New Loan',
      'goal' => 'New Goal',
      'subscription' => 'New Subscription',
      _ => '',
    };

    void selectItem(String id, String label) {
      setState(() {
        _entityLabel = label;
        if (type == 'debt_payment' ||
            type == 'debt_received' ||
            type == 'lending')
          _debtId = id;
        if (type == 'goal') _goalId = id;
        if (type == 'subscription') {
          _subscriptionId = id;
          final sub = _subController.data?.where((s) => s.id == id).firstOrNull;
          if (sub != null) _amountCtrl.text = sub.amount.toStringAsFixed(2);
        }
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    if (canAdd)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _addMainEntityInline(type, selectItem);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 15,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              addLabel,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Text(
                          canAdd
                              ? 'None yet — tap + to create one'
                              : 'No active records to link',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.label,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              item.amount,
                              style: GoogleFonts.dmMono(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing:
                                (_debtId == item.id ||
                                    _goalId == item.id ||
                                    _subscriptionId == item.id)
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: AppColors.accent,
                                  )
                                : null,
                            onTap: () {
                              selectItem(item.id, item.label);
                              Navigator.pop(sheetCtx);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addMainEntityInline(
    String type,
    void Function(String id, String label) onCreated,
  ) {
    if (type == 'lending' || type == 'debt_received') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddDebtSheet(
          isReceivable: type == 'lending',
          onSave: (debt) async {
            await _debtController.createDebt(debt);
            final debtType = type == 'lending'
                ? DebtType.lending
                : DebtType.borrowing;
            final created = _debtController.data
                ?.where((d) => d.type == debtType)
                .lastOrNull;
            if (created?.id != null)
              onCreated(created!.id!, created.personName);
          },
        ),
      );
    } else if (type == 'goal') {
      GoalsManagementDialog.show(
        context,
        onSave: (goal) async {
          await _goalController.createGoal(goal);
          final created = _goalController.data?.lastOrNull;
          if (created?.id != null) onCreated(created!.id!, created.name);
        },
      );
    } else if (type == 'subscription') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddSubscriptionSheet(
          onSave: (sub) async {
            await _subController.createSubscription(sub);
            final created = _subController.data?.lastOrNull;
            if (created?.id != null) onCreated(created!.id!, created.name);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_date, now);
    final isYesterday = DateUtils.isSameDay(
      _date,
      now.subtract(const Duration(days: 1)),
    );
    final dateLabel = isToday
        ? 'Today'
        : isYesterday
        ? 'Yesterday'
        : DateFormat('MMM d').format(_date);
    final amountLabel = _amount > 0 ? currencyFormatter.format(_amount) : null;
    final addLabel = _splitMode
        ? (_splitBalanced && amountLabel != null
              ? 'Split  $amountLabel'
              : 'Split Transaction')
        : _isPlan
        ? (amountLabel != null ? 'Plan  $amountLabel' : 'Plan Transaction')
        : (amountLabel != null ? 'Add  $amountLabel' : 'Add Transaction');
    final planned = _plannedAmount;
    final spent = _alreadySpent;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Type selector + Split + Plan toggles
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _TypePill(
                    label: 'Expense',
                    color: AppColors.error,
                    selected: _type == TransactionType.expense,
                    onTap: () => setState(() {
                      _type = TransactionType.expense;
                      _category = null;
                      _categoryError = false;
                      _entityType = null;
                      _entityLabel = null;
                      _debtId = null;
                      _goalId = null;
                      _subscriptionId = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _TypePill(
                    label: 'Income',
                    color: AppColors.success,
                    selected: _type == TransactionType.income,
                    onTap: () => setState(() {
                      _type = TransactionType.income;
                      _category = null;
                      _categoryError = false;
                      _entityType = null;
                      _entityLabel = null;
                      _debtId = null;
                      _goalId = null;
                      _subscriptionId = null;
                    }),
                  ),
                  const Spacer(),
                  _PlanTogglePill(
                    active: _isPlan,
                    onTap: () => setState(() {
                      _isPlan = !_isPlan;
                      _splitMode = false;
                      if (_isPlan) {
                        _showDesc = true;
                        _date = DateTime.now().add(const Duration(days: 1));
                      } else {
                        _showDesc = false;
                        _date = DateTime.now();
                      }
                    }),
                  ),
                  if (!_isPlan) ...[
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.call_split_rounded,
                      label: 'Split',
                      color: _splitMode
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      isDark: isDark,
                      highlighted: _splitMode,
                      onTap: _toggleSplit,
                    ),
                  ],
                ],
              ),
            ),
            // Amount input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    currencyFormatter.currencySymbol,
                    style: GoogleFonts.dmMono(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.dmMono(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: _amount > 0
                            ? _typeColor
                            : AppColors.textTertiary,
                        letterSpacing: -1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.dmMono(
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                          letterSpacing: -1,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: _typeColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Chips (hidden in split mode — all config lives per-line)
            if (!_splitMode)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.start,
                  children: [
                    if (!_isPlan)
                      _Chip(
                        icon: _showDesc
                            ? Icons.edit_off_outlined
                            : Icons.edit_outlined,
                        label: 'Note',
                        color: _showDesc
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        isDark: isDark,
                        onTap: () => setState(() => _showDesc = !_showDesc),
                      ),
                    _Chip(
                      icon: Icons.account_balance_wallet_outlined,
                      label: _selectedProfileName ?? 'Budget',
                      color: _selectedProfileId != null
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      isDark: isDark,
                      highlighted: false,
                      onTap: _pickBudgetProfile,
                    ),
                    if (_entityType == null)
                      _Chip(
                        icon: _category == null
                            ? Icons.grid_view_rounded
                            : null,
                        label: _category?.name ?? 'Category',
                        color: _categoryError
                            ? AppColors.error
                            : (_category != null
                                  ? _typeColor
                                  : AppColors.textSecondary),
                        isDark: isDark,
                        highlighted: _categoryError,
                        onTap: _pickCategory,
                      ),
                    _Chip(
                      icon: _selectedWallet == null
                          ? Icons.account_balance_wallet_outlined
                          : (_selectedWallet!.type == WalletType.creditCard
                                ? Icons.credit_card_outlined
                                : Icons.account_balance_wallet_outlined),
                      label: _selectedWallet?.name ?? 'Wallet *',
                      color: _walletError
                          ? AppColors.error
                          : (_selectedWallet != null
                                ? AppColors.accent
                                : AppColors.textSecondary),
                      isDark: isDark,
                      highlighted: _walletError,
                      onTap: () {
                        setState(() => _walletError = false);
                        _pickWallet();
                      },
                    ),
                    if (!_isPlan)
                      _Chip(
                        icon: Icons.attach_file_rounded,
                        label: _imagePaths.isEmpty
                            ? 'Attach'
                            : 'Files (${_imagePaths.length})',
                        color: _imagePaths.isNotEmpty
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        isDark: isDark,
                        onTap: _pickImage,
                      ),
                    if (!_isPlan)
                      _Chip(
                        icon: _entityType != null
                            ? Icons.link_rounded
                            : Icons.link_outlined,
                        label: _entityLabel ?? 'Link',
                        color: _entityType != null
                            ? AppColors.success
                            : AppColors.textSecondary,
                        isDark: isDark,
                        highlighted: _entityType != null,
                        onTap: _pickMainEntity,
                      ),
                    _Chip(
                      icon: Icons.calendar_today_outlined,
                      label: dateLabel,
                      color: isToday
                          ? AppColors.textSecondary
                          : AppColors.accent,
                      isDark: isDark,
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
            // Entity metadata
            if (!_splitMode && _entityType != null)
              Builder(
                builder: (_) {
                  final meta = _buildEntityMeta();
                  if (meta == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(
                          alpha: isDark ? 0.1 : 0.06,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _typeColor.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: _typeColor,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              meta,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _typeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            // Planned indicator
            if (!_splitMode && _category != null && planned > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _PlannedIndicator(
                  spent: spent,
                  planned: planned,
                  color: _typeColor,
                  isDark: isDark,
                ),
              ),
            // Description
            if ((_showDesc || _isPlan) && !_splitMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: TextField(
                  controller: _descCtrl,
                  autofocus: _isPlan,
                  maxLines: 1,
                  style: GoogleFonts.dmSans(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _isPlan ? 'Name *' : 'Add a note…',
                    hintStyle: GoogleFonts.dmSans(
                      color: AppColors.textTertiary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            // Split panel
            if (_splitMode) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _splitEntries.length; i++)
                      _SplitEntryRow(
                        key: ObjectKey(_splitEntries[i]),
                        entry: _splitEntries[i],
                        isDark: isDark,
                        borderColor: borderColor,
                        canRemove: _splitEntries.length > 1,
                        onChanged: () => setState(() {}),
                        onPickCategory: () => _pickSplitCategory(i),
                        onRemove: () => _removeSplitEntry(i),
                        onPickImage: () => _pickSplitImage(i),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _addSplitEntry,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                size: 15,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Add line',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${currencyFormatter.format(_splitTotal, decimalDigits: 2)} / ${currencyFormatter.format(_amount, decimalDigits: 2)}',
                          style: GoogleFonts.dmMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _splitBalanced
                                ? AppColors.success
                                : (_splitTotal > _amount
                                      ? AppColors.error
                                      : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _amount > 0
                            ? (_splitTotal / _amount).clamp(0.0, 1.0)
                            : 0,
                        minHeight: 4,
                        backgroundColor: borderColor,
                        valueColor: AlwaysStoppedAnimation(
                          _splitBalanced
                              ? AppColors.success
                              : (_splitTotal > _amount
                                    ? AppColors.error
                                    : AppColors.accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Attachment list (non-split, non-plan)
            if (!_splitMode && !_isPlan && _imagePaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _AttachmentList(
                  imagePaths: _imagePaths,
                  onRemove: (path) {
                    TransactionImageService.deleteImage(path).ignore();
                    setState(() => _imagePaths.remove(path));
                  },
                  onView: (path) => _ImageViewerDialog.show(context, path),
                ),
              ),
            // AI parse banner – Plus only
            if (_authController.isEffectivelyPlus)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScanExpensesSheet.show(
                      context,
                      onConfirmed: widget.onCreated,
                    );
                  });
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(
                      alpha: isDark ? 0.12 : 0.07,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'AI Parse – image or text',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.accent.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // Add button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _splitMode
                        ? (_splitBalanced && _selectedWallet != null
                              ? AppColors.accent
                              : AppColors.textTertiary)
                        : (_amount > 0 &&
                                  (_category != null ||
                                      _entityType != null ||
                                      _isPlan) &&
                                  (_isPlan || _selectedWallet != null)
                              ? (_isPlan ? AppColors.accent : _typeColor)
                              : AppColors.textTertiary),
                    foregroundColor: AppColors.textPrimaryDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          addLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
            SafeArea(top: false, child: const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _SplitEntryRow extends StatefulWidget {
  final _SplitEntry entry;
  final bool isDark;
  final Color borderColor;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onPickCategory;
  final VoidCallback onRemove;
  final VoidCallback onPickImage;

  const _SplitEntryRow({
    super.key,
    required this.entry,
    required this.isDark,
    required this.borderColor,
    required this.canRemove,
    required this.onChanged,
    required this.onPickCategory,
    required this.onRemove,
    required this.onPickImage,
  });

  @override
  State<_SplitEntryRow> createState() => _SplitEntryRowState();
}

class _SplitEntryRowState extends State<_SplitEntryRow> {
  late final WalletController _walletController;
  late final BudgetProfileController _profileController;
  late final MonthPlanController _monthPlanController;
  late final DebtController _debtController;
  late final GoalController _goalController;
  late final SubscriptionController _subController;

  @override
  void initState() {
    super.initState();
    _walletController = locator.get<WalletController>();
    _profileController = locator.get<BudgetProfileController>();
    _monthPlanController = locator.get<MonthPlanController>();
    _debtController = locator.get<DebtController>();
    _goalController = locator.get<GoalController>();
    _subController = locator.get<SubscriptionController>();
  }

  void _pickWallet() {
    final wallets = _walletController.data ?? [];
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Wallet',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...wallets.map(
              (w) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.accent,
                  size: 18,
                ),
                title: Text(
                  w.name,
                  style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary),
                ),
                subtitle: Text(
                  currencyFormatter.format(w.balance),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: widget.entry.walletId == w.id
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.accent,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    widget.entry.walletId = w.id;
                    widget.entry.walletName = w.name;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickProfile() {
    final profiles = _profileController.data ?? [];
    final plans = _monthPlanController.data ?? [];
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    final items = <({String label, String profileId})>[];
    for (final p in profiles) {
      if (!p.isActive) continue;
      if (p.isMonthly) {
        final profilePlans = plans
            .where(
              (pl) =>
                  pl.budgetProfileId == p.id &&
                  !pl.isClosed &&
                  pl.month != null,
            )
            .toList();
        if (profilePlans.isEmpty) {
          items.add((label: p.name, profileId: p.id!));
        } else {
          for (final pl in profilePlans) {
            final dt = DateTime.tryParse('${pl.month!}-01');
            final label = dt != null
                ? '${p.name} – ${DateFormat('MMM yyyy').format(dt)}'
                : p.name;
            items.add((label: label, profileId: p.id!));
          }
        }
      } else {
        items.add((label: p.name, profileId: p.id!));
      }
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Budget',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.accent,
                  size: 18,
                ),
                title: Text(
                  item.label,
                  style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary),
                ),
                trailing: widget.entry.profileId == item.profileId
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.accent,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    widget.entry.profileId = item.profileId;
                    widget.entry.profileName = item.label;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickEntity() {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    final isIncome = widget.entry.type == TransactionType.income;

    // Income: only debt types (collecting receivable or recording loan received)
    // Expense: all types
    final types = isIncome
        ? [
            (
              type: 'lending',
              icon: Icons.arrow_downward_rounded,
              label: 'Receivable Collected',
              color: AppColors.success,
            ),
            (
              type: 'debt_received',
              icon: Icons.arrow_downward_rounded,
              label: 'Loan Received',
              color: AppColors.error,
            ),
          ]
        : [
            (
              type: 'debt_payment',
              icon: Icons.arrow_upward_rounded,
              label: 'Debt Payment',
              color: AppColors.error,
            ),
            (
              type: 'lending',
              icon: Icons.arrow_downward_rounded,
              label: 'New Receivable',
              color: AppColors.success,
            ),
            (
              type: 'goal',
              icon: Icons.flag_outlined,
              label: 'Goal',
              color: AppColors.accent,
            ),
            (
              type: 'subscription',
              icon: Icons.autorenew_rounded,
              label: 'Subscription',
              color: AppColors.info,
            ),
          ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Link To',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.link_off_rounded,
                          color: AppColors.textTertiary,
                          size: 18,
                        ),
                        title: Text(
                          'None',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: textPrimary,
                          ),
                        ),
                        trailing: widget.entry.entityType == null
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.accent,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            widget.entry.entityType = null;
                            widget.entry.entityLabel = null;
                            widget.entry.debtId = null;
                            widget.entry.goalId = null;
                            widget.entry.subscriptionId = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ...types.map(
                        (t) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(t.icon, color: t.color, size: 18),
                          title: Text(
                            t.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            _entityDescription(t.type),
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: widget.entry.entityType == t.type
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: AppColors.accent,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              widget.entry.entityType = t.type;
                              widget.entry.entityLabel = null;
                              widget.entry.debtId = null;
                              widget.entry.goalId = null;
                              widget.entry.subscriptionId = null;
                              widget.entry.category = null;
                            });
                            Navigator.pop(context);
                            if (_isCreateOnly(t.type)) {
                              _addEntityInline(
                                t.type,
                                (id, label) => setState(() {
                                  widget.entry.entityLabel = label;
                                  widget.entry.debtId = id;
                                }),
                              );
                            } else {
                              _pickEntityItem(t.type);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickEntityItem(String type) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;

    List<({String id, String label, String amount})> items;
    if (type == 'debt_payment' || type == 'debt_received') {
      final debtType = type == 'debt_received'
          ? DebtType.lending
          : DebtType.borrowing;
      items = (_debtController.data ?? [])
          .where((d) => d.type == debtType && d.status != DebtStatus.settled)
          .map(
            (d) => (
              id: d.id!,
              label: d.personName,
              amount: type == 'debt_received'
                  ? 'Expecting ${currencyFormatter.format(d.remainingAmount)}'
                  : 'Still owe ${currencyFormatter.format(d.remainingAmount)}',
            ),
          )
          .toList();
    } else if (type == 'lending') {
      items = (_debtController.data ?? [])
          .where(
            (d) => d.type == DebtType.lending && d.status != DebtStatus.settled,
          )
          .map(
            (d) => (
              id: d.id!,
              label: d.personName,
              amount:
                  'Expecting ${currencyFormatter.format(d.remainingAmount)}',
            ),
          )
          .toList();
    } else if (type == 'goal') {
      items = (_goalController.data ?? [])
          .where((g) => !g.isCompleted)
          .map(
            (g) => (
              id: g.id!,
              label: g.name,
              amount:
                  '${currencyFormatter.format(g.currentAmount)} of ${currencyFormatter.format(g.targetAmount)} saved',
            ),
          )
          .toList();
    } else {
      items = (_subController.data ?? [])
          .map(
            (s) => (
              id: s.id!,
              label: s.name,
              amount: '${currencyFormatter.format(s.amount)} recurring',
            ),
          )
          .toList();
    }

    // Types that support inline creation
    final canAdd =
        type == 'lending' ||
        type == 'debt_received' ||
        type == 'goal' ||
        type == 'subscription';
    final addLabel = switch (type) {
      'lending' => 'New Receivable',
      'debt_received' => 'New Loan',
      'goal' => 'New Goal',
      'subscription' => 'New Subscription',
      _ => '',
    };

    void selectItem(String id, String label) {
      setState(() {
        widget.entry.entityLabel = label;
        if (type == 'debt_payment' ||
            type == 'debt_received' ||
            type == 'lending')
          widget.entry.debtId = id;
        if (type == 'goal') widget.entry.goalId = id;
        if (type == 'subscription') {
          widget.entry.subscriptionId = id;
          final sub = _subController.data?.where((s) => s.id == id).firstOrNull;
          if (sub != null)
            widget.entry.amountCtrl.text = sub.amount.toStringAsFixed(2);
          widget.onChanged();
        }
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    if (canAdd)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _addEntityInline(type, selectItem);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 15,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              addLabel,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Text(
                          canAdd
                              ? 'None yet — tap + to create one'
                              : 'No active records to link',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.label,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              item.amount,
                              style: GoogleFonts.dmMono(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing:
                                (widget.entry.debtId == item.id ||
                                    widget.entry.goalId == item.id ||
                                    widget.entry.subscriptionId == item.id)
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: AppColors.accent,
                                  )
                                : null,
                            onTap: () {
                              selectItem(item.id, item.label);
                              Navigator.pop(sheetCtx);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addEntityInline(
    String type,
    void Function(String id, String label) onCreated,
  ) {
    if (type == 'lending' || type == 'debt_received') {
      final isReceivable = type == 'lending';
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddDebtSheet(
          isReceivable: isReceivable,
          onSave: (debt) async {
            await _debtController.createDebt(debt);
            final debtType = isReceivable
                ? DebtType.lending
                : DebtType.borrowing;
            final created = _debtController.data
                ?.where((d) => d.type == debtType)
                .lastOrNull;
            if (created?.id != null)
              onCreated(created!.id!, created.personName);
          },
        ),
      );
    } else if (type == 'goal') {
      GoalsManagementDialog.show(
        context,
        onSave: (goal) async {
          await _goalController.createGoal(goal);
          final created = _goalController.data?.lastOrNull;
          if (created?.id != null) onCreated(created!.id!, created.name);
        },
      );
    } else if (type == 'subscription') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddSubscriptionSheet(
          onSave: (sub) async {
            await _subController.createSubscription(sub);
            final created = _subController.data?.lastOrNull;
            if (created?.id != null) onCreated(created!.id!, created.name);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    final typeColor = widget.entry.type == TransactionType.income
        ? AppColors.success
        : AppColors.error;
    final hasCategory = widget.entry.category != null;
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(widget.entry.date, now);
    final dateLabel = isToday
        ? 'Today'
        : DateFormat('MMM d').format(widget.entry.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Type toggle
              GestureDetector(
                onTap: () => setState(() {
                  widget.entry.type =
                      widget.entry.type == TransactionType.expense
                      ? TransactionType.income
                      : TransactionType.expense;
                  widget.entry.category = null;
                  widget.entry.entityType = null;
                  widget.entry.entityLabel = null;
                  widget.entry.debtId = null;
                  widget.entry.goalId = null;
                  widget.entry.subscriptionId = null;
                  widget.onChanged();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.entry.type == TransactionType.income
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 11,
                        color: typeColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.entry.type == TransactionType.income
                            ? 'In'
                            : 'Out',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Description inline
              Expanded(
                child: TextField(
                  controller: widget.entry.noteCtrl,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                    border: InputBorder.none,
                    hintText: hasCategory
                        ? widget.entry.category!.name
                        : 'Description',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: hasCategory
                          ? textPrimary.withValues(alpha: 0.5)
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              SizedBox(
                width: 80,
                child: TextField(
                  controller: widget.entry.amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => widget.onChanged(),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.dmMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0.00',
                    hintStyle: GoogleFonts.dmMono(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.onPickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      if (widget.entry.imagePaths.isNotEmpty) ...[
                        const SizedBox(width: 3),
                        Text(
                          '${widget.entry.imagePaths.length}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.canRemove)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Chips row
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _SplitChip(
                icon: Icons.calendar_month_outlined,
                label: 'Plan',
                color: widget.entry.isPlan
                    ? AppColors.accent
                    : AppColors.textSecondary,
                isDark: widget.isDark,
                onTap: () => setState(() {
                  widget.entry.isPlan = !widget.entry.isPlan;
                  if (widget.entry.isPlan) widget.entry.category = null;
                  widget.onChanged();
                }),
              ),
              _SplitChip(
                icon: Icons.account_balance_wallet_outlined,
                label: widget.entry.profileName ?? 'Budget',
                color: widget.entry.profileName != null
                    ? AppColors.accent
                    : AppColors.textSecondary,
                isDark: widget.isDark,
                onTap: _pickProfile,
              ),
              if (!widget.entry.isPlan && widget.entry.entityType == null)
                _SplitChip(
                  icon: Icons.category_outlined,
                  label: widget.entry.category?.name ?? 'Category',
                  color: widget.entry.category != null
                      ? AppColors.textSecondary
                      : AppColors.textTertiary,
                  isDark: widget.isDark,
                  onTap: widget.onPickCategory,
                ),
              _SplitChip(
                icon: Icons.account_balance_wallet_outlined,
                label: widget.entry.walletName ?? 'Wallet',
                color: widget.entry.walletName != null
                    ? AppColors.accent
                    : AppColors.textSecondary,
                isDark: widget.isDark,
                onTap: _pickWallet,
              ),
              _SplitChip(
                icon: Icons.calendar_today_outlined,
                label: dateLabel,
                color: isToday ? AppColors.textSecondary : AppColors.accent,
                isDark: widget.isDark,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.entry.date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null)
                    setState(() => widget.entry.date = picked);
                },
              ),
              if (!widget.entry.isPlan)
                _SplitChip(
                  icon: widget.entry.entityType != null
                      ? Icons.link_rounded
                      : Icons.link_off_rounded,
                  label:
                      widget.entry.entityLabel ??
                      (widget.entry.entityType != null
                          ? _entityTypeLabel(widget.entry.entityType!)
                          : 'Link'),
                  color: widget.entry.entityLabel != null
                      ? AppColors.success
                      : AppColors.textSecondary,
                  isDark: widget.isDark,
                  onTap: _pickEntity,
                ),
            ],
          ),
          // Entity metadata banner
          Builder(
            builder: (_) {
              final meta = _buildMeta();
              if (meta == null) return const SizedBox.shrink();
              final typeColor = widget.entry.type == TransactionType.income
                  ? AppColors.success
                  : AppColors.error;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(
                      alpha: widget.isDark ? 0.1 : 0.06,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: typeColor.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: typeColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          meta,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isCreateOnly(String type) {
    if (type == 'debt_received') return true;
    if (type == 'lending') return widget.entry.type == TransactionType.expense;
    return false;
  }

  String _entityDescription(String type) => switch (type) {
    'debt_payment' => 'Pay back an existing debt',
    'lending' =>
      widget.entry.type == TransactionType.income
          ? 'Select which receivable was collected'
          : 'Record money you lent — creates a new receivable',
    'debt_received' => 'Record a loan you received — creates a new debt',
    'goal' => 'Contribute toward a savings goal',
    'subscription' => 'Log a subscription payment — auto-fills amount',
    _ => '',
  };

  String? _buildMeta() {
    final e = widget.entry;
    if (e.entityType == null) return null;
    if (e.debtId != null) {
      final debt = _debtController.data
          ?.where((d) => d.id == e.debtId)
          .firstOrNull;
      if (debt == null) return null;
      return e.entityType == 'debt_payment'
          ? 'Still owe ${currencyFormatter.format(debt.remainingAmount)} to ${debt.personName}'
          : 'Expecting ${currencyFormatter.format(debt.remainingAmount)} from ${debt.personName}';
    }
    if (e.goalId != null) {
      final goal = _goalController.data
          ?.where((g) => g.id == e.goalId)
          .firstOrNull;
      if (goal == null) return null;
      final remaining = (goal.targetAmount - goal.currentAmount).clamp(
        0.0,
        double.infinity,
      );
      return '${currencyFormatter.format(goal.currentAmount)} of ${currencyFormatter.format(goal.targetAmount)} saved · ${currencyFormatter.format(remaining)} to go';
    }
    if (e.subscriptionId != null) {
      final sub = _subController.data
          ?.where((s) => s.id == e.subscriptionId)
          .firstOrNull;
      if (sub == null) return null;
      return '${currencyFormatter.format(sub.amount)} recurring';
    }
    return null;
  }

  String _entityTypeLabel(String type) => switch (type) {
    'debt_payment' => 'Debt…',
    'lending' => 'Receivable…',
    'goal' => 'Goal…',
    'subscription' => 'Sub…',
    _ => 'Link',
  };
}

class _SplitChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _SplitChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlannedIndicator extends StatelessWidget {
  final double spent, planned;
  final Color color;
  final bool isDark;

  const _PlannedIndicator({
    required this.spent,
    required this.planned,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (planned - spent).clamp(0.0, double.infinity);
    final isOver = spent > planned;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.background;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 13,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            'Budget: ${currencyFormatter.format(planned, decimalDigits: 0)}',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '·',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOver
                ? 'Over by ${currencyFormatter.format(spent - planned, decimalDigits: 0)}'
                : '${currencyFormatter.format(remaining, decimalDigits: 0)} left',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOver ? AppColors.error : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerSheet extends StatefulWidget {
  final DateTime selected;
  final bool isDark;
  final bool allowFuture;
  final void Function(DateTime) onSelect;
  const _DatePickerSheet({
    required this.selected,
    required this.isDark,
    this.allowFuture = false,
    required this.onSelect,
  });

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
    if (!next.isAfter(DateTime(now.year, now.month)))
      setState(() => _view = next);
  }

  bool get _canGoNext {
    if (widget.allowFuture) return true;
    final now = DateTime.now();
    return _view.year < now.year ||
        (_view.year == now.year && _view.month < now.month);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    final now = DateTime.now();
    final firstDay = DateTime(_view.year, _view.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_view.year, _view.month);
    final startOffset = firstDay.weekday % 7; // 0=Sun

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Month/year nav
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: _prev,
                    padding: EdgeInsets.zero,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_view),
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _canGoNext
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                    ),
                    onPressed: _canGoNext ? _next : null,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),
            // Day of week headers
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Calendar grid
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: 40,
                ),
                itemCount: startOffset + daysInMonth,
                itemBuilder: (_, i) {
                  if (i < startOffset) return const SizedBox.shrink();
                  final day = i - startOffset + 1;
                  final date = DateTime(_view.year, _view.month, day);
                  final isSelected = DateUtils.isSameDay(date, widget.selected);
                  final isToday = DateUtils.isSameDay(date, now);
                  final isFuture = !widget.allowFuture && date.isAfter(now);
                  Color textColor = isDark
                      ? AppColors.primaryForeground
                      : AppColors.textPrimary;
                  if (isFuture) textColor = AppColors.textTertiary;
                  if (isSelected) textColor = Colors.white;

                  return GestureDetector(
                    onTap: isFuture ? null : () => widget.onSelect(date),
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday && !isSelected
                              ? Border.all(color: AppColors.accent, width: 1.5)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionCategoryPicker extends StatelessWidget {
  final TransactionType type;
  final String? selectedId;
  final FinanceCategoryController controller;
  final Set<String>? allowedIds;
  final bool isDark;
  final void Function(FinanceCategory) onSelect;
  const TransactionCategoryPicker({
    super.key,
    required this.type,
    required this.selectedId,
    required this.controller,
    this.allowedIds,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final divColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    final targetType = type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Text(
                    'Select Category',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: divColor),
            Expanded(
              child: AsyncStreamBuilder<List<FinanceCategory>>(
                state: controller,
                builder: (_, cats) {
                  var filtered =
                      cats
                          .where((c) => c.type == targetType && !c.isArchive)
                          .where(
                            (c) =>
                                allowedIds == null ||
                                (c.id != null && allowedIds!.contains(c.id)),
                          )
                          .toList()
                        ..sort((a, b) => a.name.compareTo(b.name));
                  if (filtered.isEmpty)
                    return Center(
                      child: Text(
                        'No categories found',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  final color = targetType == CategoryType.income
                      ? AppColors.success
                      : AppColors.error;
                  return ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: divColor,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (_, i) {
                      final cat = filtered[i];
                      final isSel = cat.id == selectedId;
                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            targetType == CategoryType.income
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 15,
                            color: color,
                          ),
                        ),
                        title: Text(
                          cat.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: isSel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: textPrimary,
                          ),
                        ),
                        trailing: isSel
                            ? Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppColors.accent,
                              )
                            : null,
                        onTap: () => onSelect(cat),
                      );
                    },
                  );
                },
                loadingBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        color: active
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 12,
            color: active ? AppColors.accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            'Plan',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TypePill extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypePill({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? Colors.white : color,
        ),
      ),
    ),
  );
}

class _AttachmentList extends StatelessWidget {
  final List<String> imagePaths;
  final void Function(String) onRemove;
  final void Function(String) onView;

  const _AttachmentList({
    required this.imagePaths,
    required this.onRemove,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: imagePaths
          .map(
            (path) => _AttachmentItem(
              path: path,
              onRemove: () => onRemove(path),
              onView: () => onView(path),
            ),
          )
          .toList(),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  final VoidCallback onView;

  const _AttachmentItem({
    required this.path,
    required this.onRemove,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final exists = TransactionImageService.fileExists(path);
    final name = TransactionImageService.displayName(path);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: exists ? onView : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: exists
                  ? Image.file(
                      File(path),
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 34,
                      height: 34,
                      color: AppColors.textTertiary.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: exists ? onView : null,
              child: Text(
                name,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageViewerDialog extends StatelessWidget {
  final String path;
  const _ImageViewerDialog({required this.path});

  static void show(BuildContext context, String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => _ImageViewerDialog(path: path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: size.height * 0.1,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              color: const Color(0xFF1A1A1A),
              child: InteractiveViewer(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool highlighted;
  final VoidCallback? onTap;
  const _Chip({
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted
        ? AppColors.error.withValues(alpha: 0.08)
        : (isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.background);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: highlighted
              ? Border.all(color: AppColors.error.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon!, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
