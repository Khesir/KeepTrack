import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/helpers/category_budget_lookup.dart';
import 'package:keep_track/features/finance/presentation/helpers/create_transaction_entity_meta.dart';
import 'package:keep_track/features/finance/presentation/helpers/create_transaction_submit.dart';
import 'package:keep_track/features/finance/presentation/helpers/split_entry.dart';
import 'package:keep_track/features/finance/presentation/helpers/split_entry_category_picker.dart';
import 'package:keep_track/features/finance/presentation/helpers/transaction_image_picker.dart';
import 'package:keep_track/features/finance/presentation/sections/create_transaction_ai_banner.dart';
import 'package:keep_track/features/finance/presentation/sections/create_transaction_amount_field.dart';
import 'package:keep_track/features/finance/presentation/sections/create_transaction_chips_row.dart';
import 'package:keep_track/features/finance/presentation/sections/create_transaction_description_field.dart';
import 'package:keep_track/features/finance/presentation/sections/create_transaction_entity_meta_banner.dart';
import 'package:keep_track/features/finance/presentation/sections/create_transaction_split_panel.dart';
import 'package:keep_track/features/finance/presentation/sections/create_transaction_submit_button.dart';
import 'package:keep_track/features/finance/presentation/sections/create_transaction_type_row.dart';
import 'package:keep_track/features/finance/presentation/sheets/split_entry_attachments_sheet.dart';
import 'package:keep_track/features/finance/presentation/sheets/transaction_create_date_picker_sheet.dart';
import 'package:keep_track/features/finance/presentation/sheets/transaction_create_entity_link_sheet.dart';
import 'package:keep_track/features/finance/presentation/sheets/transaction_create_profile_picker_sheet.dart';
import 'package:keep_track/features/finance/presentation/sheets/transaction_create_wallet_picker_sheet.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import 'package:keep_track/features/finance/presentation/widgets/create_transaction_chips.dart';
import 'package:keep_track/features/finance/presentation/widgets/transaction_category_picker.dart';
import 'package:keep_track/features/finance/presentation/widgets/transaction_create_attachments.dart';
import 'package:uuid/uuid.dart';
import 'scan_expenses_sheet.dart';

part 'create_transaction_sheet_entity_link.dart';
part 'create_transaction_sheet_split.dart';
part 'create_transaction_sheet_pickers.dart';

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

abstract class _CreateTransactionSheetBase
    extends State<CreateTransactionSheet> {
  late final FinanceCategoryController _catController;
  late final BudgetController _budgetController;
  late final BudgetProfileController _profileController;
  late final MonthPlanController _monthPlanController;
  late final WalletController _walletController;

  TransactionType _type = TransactionType.expense;
  final TextEditingController _amountCtrl = TextEditingController();
  FinanceCategory? _category;
  Wallet? _selectedWallet;
  DateTime _date = DateTime.now();
  bool _isPlan = false;
  bool _categoryError = false;
  bool _walletError = false;
  String? _selectedProfileId;
  String? _selectedProfileName;
  String? _selectedPlanMonth;

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;
}

class _CreateTransactionSheetState extends _CreateTransactionSheetBase
    with
        _CreateTransactionEntityLinkMixin,
        _CreateTransactionSplitMixin,
        _CreateTransactionPickersMixin {
  late final TransactionController _txController;
  late final TransactionPlanController _planController;
  late final AuthController _authController;

  final _descCtrl = TextEditingController();
  bool _loading = false;
  bool _showDesc = false;

  late String _pendingTxId;
  final List<String> _imagePaths = [];
  bool _created = false;

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
    _catController.loadCategories();

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

  Color get _typeColor =>
      _type == TransactionType.income ? AppColors.success : AppColors.error;

  void _selectType(TransactionType type) {
    setState(() {
      _type = type;
      _category = null;
      _categoryError = false;
      _entityType = null;
      _entityLabel = null;
      _debtId = null;
      _goalId = null;
      _subscriptionId = null;
    });
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
        await submitSplitTransactions(
          txController: _txController,
          planController: _planController,
          walletController: _walletController,
          debtController: _debtController,
          goalController: _goalController,
          authController: _authController,
          entries: _splitEntries,
          selectedWallet: _selectedWallet,
          selectedProfileId: _selectedProfileId,
        );
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
      await submitSingleTransaction(
        txController: _txController,
        planController: _planController,
        walletController: _walletController,
        debtController: _debtController,
        goalController: _goalController,
        authController: _authController,
        isPlan: _isPlan,
        pendingTxId: _pendingTxId,
        amount: _amount,
        type: _type,
        date: _date,
        description: _descCtrl.text.trim(),
        category: _category,
        entityType: _entityType,
        entityLabel: _entityLabel,
        selectedProfileId: _selectedProfileId,
        selectedWallet: _selectedWallet!,
        debtId: _debtId,
        goalId: _goalId,
        subscriptionId: _subscriptionId,
        imagePaths: _imagePaths,
      );
      _created = true;
      widget.onCreated?.call();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() => pickTransactionImage(
    context,
    _pendingTxId,
    _imagePaths,
    () => setState(() {}),
  );

  Future<void> _pickSplitImage(int index) => showSplitEntryAttachmentsSheet(
    context,
    _splitEntries[index],
    () => setState(() {}),
  );

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
    final planned = plannedAmountForCategory(_budgetController, _category?.id);
    final spent = alreadySpentForCategory(_txController, _category?.id);

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: CreateTransactionTypeRow(
                type: _type,
                isPlan: _isPlan,
                splitMode: _splitMode,
                isDark: isDark,
                onSelectExpense: () => _selectType(TransactionType.expense),
                onSelectIncome: () => _selectType(TransactionType.income),
                onTogglePlan: () => setState(() {
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
                onToggleSplit: _toggleSplit,
              ),
            ),
            CreateTransactionAmountField(
              controller: _amountCtrl,
              amount: _amount,
              typeColor: _typeColor,
              onChanged: () => setState(() {}),
            ),
            if (!_splitMode)
              CreateTransactionChipsRow(
                isDark: isDark,
                isPlan: _isPlan,
                showDesc: _showDesc,
                onToggleDesc: () => setState(() => _showDesc = !_showDesc),
                selectedProfileName: _selectedProfileName,
                selectedProfileId: _selectedProfileId,
                onPickProfile: _pickBudgetProfile,
                category: _category,
                categoryError: _categoryError,
                entityType: _entityType,
                typeColor: _typeColor,
                onPickCategory: _pickCategory,
                selectedWallet: _selectedWallet,
                walletError: _walletError,
                onPickWallet: () {
                  setState(() => _walletError = false);
                  _pickWallet();
                },
                imagePaths: _imagePaths,
                onPickImage: _pickImage,
                entityLabel: _entityLabel,
                onPickEntity: _pickMainEntity,
                dateLabel: dateLabel,
                isToday: isToday,
                onPickDate: _pickDate,
              ),
            if (!_splitMode && _entityType != null)
              CreateTransactionEntityMetaBanner(
                meta: _buildEntityMeta(),
                typeColor: _typeColor,
                isDark: isDark,
              ),
            if (!_splitMode && _category != null && planned > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: BudgetPlannedIndicator(
                  spent: spent,
                  planned: planned,
                  color: _typeColor,
                  isDark: isDark,
                ),
              ),
            if ((_showDesc || _isPlan) && !_splitMode)
              CreateTransactionDescriptionField(
                controller: _descCtrl,
                isPlan: _isPlan,
              ),
            if (_splitMode)
              CreateTransactionSplitPanel(
                entries: _splitEntries,
                isDark: isDark,
                borderColor: borderColor,
                amount: _amount,
                splitTotal: _splitTotal,
                splitBalanced: _splitBalanced,
                onAddLine: _addSplitEntry,
                onPickCategory: _pickSplitCategory,
                onRemove: _removeSplitEntry,
                onPickImage: _pickSplitImage,
                onChanged: () => setState(() {}),
              ),
            if (!_splitMode && !_isPlan && _imagePaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TransactionCreateAttachmentList(
                  imagePaths: _imagePaths,
                  onRemove: (path) {
                    TransactionImageService.deleteImage(path).ignore();
                    setState(() => _imagePaths.remove(path));
                  },
                  onView: (path) =>
                      TransactionCreateImageViewerDialog.show(context, path),
                ),
              ),
            if (_authController.isEffectivelyPlus)
              CreateTransactionAiBanner(
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScanExpensesSheet.show(
                      context,
                      onConfirmed: widget.onCreated,
                    );
                  });
                },
              ),
            const SizedBox(height: 8),
            CreateTransactionSubmitButton(
              loading: _loading,
              color: _splitMode
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
              label: addLabel,
              onPressed: _submit,
            ),
            SafeArea(top: false, child: const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
