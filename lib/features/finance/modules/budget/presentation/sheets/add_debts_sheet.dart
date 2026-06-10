import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/finance_category.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/initial_tx_details.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/widgets/transaction_attachment_picker.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import 'package:uuid/uuid.dart';
import 'budget_profile_picker_sheet.dart';
import 'sheet_chip.dart';
import 'sheet_helpers.dart';
import 'wallet_picker_sheet.dart';

class AddDebtSheet extends StatefulWidget {
  final bool isReceivable;
  final Future<void> Function(Debt debt, InitialTxDetails? txDetails) onSave;
  final Debt? initialDebt;

  const AddDebtSheet({
    super.key,
    required this.isReceivable,
    required this.onSave,
    this.initialDebt,
  });

  @override
  State<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<AddDebtSheet> {
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();
  late final DebtType _type;
  late final WalletController _walletController;
  late final FinanceCategoryController _catController;
  late final BudgetProfileController _profileController;
  DateTime? _dueDate;
  bool _saving = false;
  bool _txSaved = false;
  bool _createTx = false;
  Wallet? _selectedWallet;

  // Initial transaction extras
  late final String _pendingTxId;
  final List<String> _txImagePaths = [];
  FinanceCategory? _txCategory;
  String? _txProfileId;
  String? _txProfileName;

  bool get _isEditing => widget.initialDebt != null;

  @override
  void initState() {
    super.initState();
    _pendingTxId = const Uuid().v4();
    _type = widget.isReceivable ? DebtType.lending : DebtType.borrowing;
    _walletController = locator.get<WalletController>();
    _catController = locator.get<FinanceCategoryController>();
    _profileController = locator.get<BudgetProfileController>();
    _catController.loadCategories();
    if (_isEditing) {
      final d = widget.initialDebt!;
      _personCtrl.text = d.personName;
      _descCtrl.text = d.description;
      _monthlyCtrl.text = d.monthlyPaymentAmount > 0 ? d.monthlyPaymentAmount.toStringAsFixed(2) : '';
      _dueDate = d.dueDate;
    }
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    _descCtrl.dispose();
    _monthlyCtrl.dispose();
    if (!_txSaved) {
      TransactionImageService.deleteAll(_pendingTxId).ignore();
    }
    super.dispose();
  }

  bool get _isReceivable => _type == DebtType.lending;
  Color get _typeColor => _isReceivable ? AppColors.success : AppColors.error;

  bool get _canSave {
    if (_isEditing) return _personCtrl.text.trim().isNotEmpty;
    if (_personCtrl.text.trim().isEmpty) return false;
    if ((double.tryParse(_amountCtrl.text) ?? 0) <= 0) return false;
    if (_createTx && _selectedWallet == null) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    try {
      final Debt debt;
      if (_isEditing) {
        final d = widget.initialDebt!;
        debt = Debt(
          id: d.id,
          type: d.type,
          personName: _personCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          originalAmount: d.originalAmount,
          remainingAmount: d.remainingAmount,
          startDate: d.startDate,
          dueDate: _dueDate,
          status: d.status,
          notes: d.notes,
          createdAt: d.createdAt,
          updatedAt: DateTime.now(),
          settledAt: d.settledAt,
          userId: d.userId,
          transactionId: d.transactionId,
          monthlyPaymentAmount: double.tryParse(_monthlyCtrl.text) ?? 0,
          feeAmount: d.feeAmount,
          nextPaymentDate: d.nextPaymentDate,
          paymentFrequency: d.paymentFrequency,
          budgetProfileId: d.budgetProfileId,
        );
      } else {
        final principal = double.parse(_amountCtrl.text);
        final fee = double.tryParse(_feeCtrl.text) ?? 0;
        debt = Debt(
          type: _type,
          personName: _personCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          originalAmount: principal,
          remainingAmount: principal + fee,
          startDate: DateTime.now(),
          dueDate: _dueDate,
          monthlyPaymentAmount: double.tryParse(_monthlyCtrl.text) ?? 0,
          feeAmount: fee,
        );
      }
      await widget.onSave(
        debt,
        _createTx && _selectedWallet != null
            ? InitialTxDetails(
                wallet: _selectedWallet!,
                categoryId: _txCategory?.id,
                budgetProfileId: _txProfileId,
                imagePaths: List.from(_txImagePaths),
              )
            : null,
      );
      _txSaved = true;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pickWallet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => WalletPickerSheet(
        isDark: isDark,
        wallets: _walletController.wallets,
        selectedWalletId: _selectedWallet?.id,
        onSelect: (w) => setState(() => _selectedWallet = w),
      ),
    );
  }

  void _pickDate(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SheetCalendar(
        isDark: isDark,
        selected: _dueDate,
        onSelect: (d) {
          setState(() => _dueDate = d);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _pickTxBudgetProfile(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetProfilePickerSheet(
        isDark: isDark,
        profiles: _profileController.data ?? <BudgetProfile>[],
        selectedProfileId: _txProfileId,
        onSelect: (id, name) => setState(() {
          _txProfileId = id;
          _txProfileName = name;
        }),
      ),
    );
  }

  Future<void> _pickTxCategory(bool isDark) async {
    final allCats = _catController.data ?? <FinanceCategory>[];
    final catType = _isReceivable ? CategoryType.expense : CategoryType.income;
    final groups = buildGroupedCategories(
      allCategories: allCats,
      allBudgets: [],
      targetType: catType,
      monthKey: '',
    );
    final picked = await showGroupedCategoryDialog(
      context,
      groups: groups,
      selectedId: _txCategory?.id,
    );
    if (picked != null && mounted) setState(() => _txCategory = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final textPrimary =
        isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, ctrl) => Column(children: [
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
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.account_balance_outlined,
                      size: 18, color: _typeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEditing
                        ? (_isReceivable ? 'Edit Receivable' : 'Edit Debt')
                        : (_isReceivable ? 'New Receivable' : 'New Debt'),
                    style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ]),
            ),
            Divider(height: 20, color: border),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  SheetLabel(_isReceivable ? 'Borrower Name *' : 'Lender / Person *'),
                  SheetField(
                    ctrl: _personCtrl,
                    hint: 'Full name',
                    isDark: isDark,
                    autofocus: true,
                    capitalize: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing) ...[
                    SheetLabel('Amount *'),
                    SheetField(
                      ctrl: _amountCtrl,
                      hint: '0.00',
                      prefix: '${currencyFormatter.currencySymbol} ',
                      isDark: isDark,
                      numeric: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    SheetLabel('Fee (optional)'),
                    SheetField(
                      ctrl: _feeCtrl,
                      hint: '0.00',
                      prefix: '${currencyFormatter.currencySymbol} ',
                      isDark: isDark,
                      numeric: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                  SheetLabel('Monthly Payment (optional)'),
                  SheetField(
                    ctrl: _monthlyCtrl,
                    hint: '0.00 – pre-fills payment drawer',
                    prefix: '${currencyFormatter.currencySymbol} ',
                    isDark: isDark,
                    numeric: true,
                  ),
                  const SizedBox(height: 16),
                  SheetLabel('Due Date (optional)'),
                  const SizedBox(height: 8),
                  SheetPickerField(
                    icon: Icons.calendar_today_outlined,
                    label: _dueDate != null
                        ? DateFormat('MMMM d, yyyy').format(_dueDate!)
                        : 'No due date',
                    hasValue: _dueDate != null,
                    border: border,
                    textPrimary: textPrimary,
                    onTap: () => _pickDate(isDark),
                    trailing: _dueDate != null
                        ? GestureDetector(
                            onTap: () => setState(() => _dueDate = null),
                            child: Icon(Icons.close_rounded,
                                size: 14, color: AppColors.textTertiary),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SheetLabel('Notes (optional)'),
                  SheetField(
                      ctrl: _descCtrl,
                      hint: 'Add a note…',
                      isDark: isDark,
                      maxLines: 2),
                  if (!_isEditing) ...[
                    const SizedBox(height: 20),
                    SheetToggleRow(
                      title: 'Record initial transaction',
                      subtitle: _isReceivable
                          ? 'Creates an expense for money lent out'
                          : 'Creates an income for money received',
                      value: _createTx,
                      textPrimary: textPrimary,
                      onChanged: (v) => setState(() {
                        _createTx = v;
                        if (!v) {
                          _selectedWallet = null;
                          _txCategory = null;
                          _txProfileId = null;
                          _txProfileName = null;
                        }
                      }),
                    ),
                    if (_createTx) ...[
                      const SizedBox(height: 12),
                      SheetLabel('Wallet *'),
                      const SizedBox(height: 8),
                      SheetPickerField(
                        icon: Icons.account_balance_wallet_outlined,
                        label: _selectedWallet?.name ?? 'Select a wallet',
                        hasValue: _selectedWallet != null,
                        border: border,
                        textPrimary: textPrimary,
                        errorBorderColor: _selectedWallet == null
                            ? AppColors.error.withValues(alpha: 0.5)
                            : null,
                        onTap: () => _pickWallet(isDark),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            SheetChip(
                              icon: Icons.account_balance_wallet_outlined,
                              label: _txProfileName ?? 'Budget',
                              active: _txProfileId != null,
                              isDark: isDark,
                              onTap: () => _pickTxBudgetProfile(isDark),
                            ),
                            SheetChip(
                              icon: Icons.grid_view_rounded,
                              label: _txCategory?.name ?? 'Category',
                              active: _txCategory != null,
                              isDark: isDark,
                              onTap: () => _pickTxCategory(isDark),
                            ),
                            TransactionAttachmentPicker(
                              pendingTxId: _pendingTxId,
                              imagePaths: _txImagePaths,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canSave && !_saving ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canSave ? _typeColor : AppColors.textTertiary,
                        foregroundColor: AppColors.textPrimaryDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isEditing
                                  ? 'Save Changes'
                                  : (_isReceivable ? 'Add Receivable' : 'Add Debt'),
                              style: GoogleFonts.dmSans(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
