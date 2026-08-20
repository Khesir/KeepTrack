import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';
import 'package:keep_track/features/finance/presentation/widgets/transaction_category_picker.dart';
import '../helpers/transaction_entity_effects.dart';
import '../widgets/transaction_detail_edit_body.dart';
import '../widgets/transaction_detail_view_body.dart';
import 'entity_link_picker_sheet.dart';
import 'transaction_profile_picker_sheet.dart';

class TransactionDetailSheet extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailSheet({super.key, required this.transaction});

  static Future<void> show(BuildContext context, {required Transaction transaction}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailSheet(transaction: transaction),
    );
  }

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  bool _editMode = false;
  bool _loading = false;
  late final TextEditingController _descCtrl;
  late DateTime _editDate;

  // Edit-mode category & profile state
  FinanceCategory? _editCategory;
  String? _editProfileId;
  String? _editProfileName;
  String? _editProfileBaseName;
  bool _editProfileIsMonthly = false;

  // Edit-mode entity link state
  String? _editEntityType;    // "subscription" | "debt_payment" | "lending" | "goal"
  String? _editSubscriptionId;
  String? _editDebtId;
  String? _editGoalId;
  String? _editEntityLabel;

  // Edit-mode wallet state (for transfers)
  String? _editWalletId;
  String? _editToWalletId;

  // Edit-mode image state
  List<String> _editImagePaths = [];

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.transaction.description ?? '');
    _editDate = widget.transaction.date;

    // Pre-populate category from current controller state
    final cats = locator.get<FinanceCategoryController>().data ?? [];
    _editCategory = cats.where((c) => c.id == widget.transaction.financeCategoryId).firstOrNull;

    // Pre-populate profile
    final profiles = locator.get<BudgetProfileController>().data ?? [];
    final profile = profiles.where((p) => p.id == widget.transaction.budgetProfileId).firstOrNull;
    if (profile != null) {
      _editProfileId = profile.id;
      _editProfileBaseName = profile.name;
      _editProfileIsMonthly = profile.isMonthly;
      _editProfileName = profile.isMonthly
          ? '${profile.name} · ${DateFormat('MMM yyyy').format(_editDate)}'
          : profile.name;
    }

    // Pre-populate wallet ids
    _editWalletId = widget.transaction.walletId;
    _editToWalletId = widget.transaction.toWalletId;

    _editImagePaths = List.of(widget.transaction.imagePaths);

    // Pre-populate entity link
    final t = widget.transaction;
    if (t.subscriptionId != null) {
      _editEntityType = 'subscription';
      _editSubscriptionId = t.subscriptionId;
      final subs = locator.get<SubscriptionController>().data ?? [];
      _editEntityLabel = subs.where((s) => s.id == t.subscriptionId).firstOrNull?.name;
    } else if (t.debtId != null) {
      _editDebtId = t.debtId;
      final debts = locator.get<DebtController>().data ?? [];
      final debt = debts.where((d) => d.id == t.debtId).firstOrNull;
      if (debt != null) {
        _editEntityType = debt.type == DebtType.lending ? 'lending' : 'debt_payment';
        _editEntityLabel = debt.personName;
      }
    } else if (t.goalId != null) {
      _editEntityType = 'goal';
      _editGoalId = t.goalId;
      final goals = locator.get<GoalController>().data ?? [];
      _editEntityLabel = goals.where((g) => g.id == t.goalId).firstOrNull?.name;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  String? _linkedLabel() {
    final t = widget.transaction;
    if (t.type == TransactionType.transfer) {
      final wallets = locator.get<WalletController>().data ?? [];
      final from = wallets.where((w) => w.id == t.walletId).firstOrNull;
      final to = wallets.where((w) => w.id == t.toWalletId).firstOrNull;
      if (from != null || to != null) {
        return '${from?.name ?? '–'} → ${to?.name ?? '–'}';
      }
      return null;
    }
    if (t.goalId != null) {
      final goals = locator.get<GoalController>().data ?? [];
      final goal = goals.where((g) => g.id == t.goalId).firstOrNull;
      return 'Goal: ${goal?.name ?? '–'}';
    }
    if (t.debtId != null) {
      final debts = locator.get<DebtController>().data ?? [];
      final debt = debts.where((d) => d.id == t.debtId).firstOrNull;
      if (debt != null) {
        return '${debt.type == DebtType.lending ? 'Receivable' : 'Debt'}: ${debt.personName}';
      }
      return 'Debt';
    }
    if (t.subscriptionId != null) {
      final subs = locator.get<SubscriptionController>().data ?? [];
      final sub = subs.where((s) => s.id == t.subscriptionId).firstOrNull;
      return 'Subscription: ${sub?.name ?? '–'}';
    }
    if (t.walletId != null) {
      final wallets = locator.get<WalletController>().data ?? [];
      final wallet = wallets.where((w) => w.id == t.walletId).firstOrNull;
      return 'Wallet: ${wallet?.name ?? '–'}';
    }
    return null;
  }

  void _showCategoryPicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionCategoryPicker(
        type: widget.transaction.type,
        selectedId: _editCategory?.id,
        controller: locator.get<FinanceCategoryController>(),
        isDark: isDark,
        onSelect: (cat) {
          setState(() => _editCategory = cat);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showProfilePicker(bool isDark) {
    final profiles = locator.get<BudgetProfileController>().data ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionProfilePickerSheet(
        isDark: isDark,
        profiles: profiles,
        selectedProfileId: _editProfileId,
        selectedDate: _editDate,
        onSelect: (id, baseName, isMonthly, displayName) {
          setState(() {
            _editProfileId = id;
            _editProfileBaseName = baseName;
            _editProfileIsMonthly = isMonthly;
            _editProfileName = displayName;
          });
        },
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final t = widget.transaction;
      await locator.get<TransactionController>().updateTransaction(
        Transaction(
          id: t.id,
          financeCategoryId: _editCategory?.id ?? t.financeCategoryId,
          amount: t.amount,
          type: t.type,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          date: _editDate,
          notes: t.notes,
          fee: t.fee,
          feeDescription: t.feeDescription,
          budgetId: t.budgetId,
          budgetProfileId: _editProfileId,
          subscriptionId: _editSubscriptionId,
          debtId: _editDebtId,
          goalId: _editGoalId,
          plannedPaymentId: t.plannedPaymentId,
          walletId: _editWalletId,
          toWalletId: _editToWalletId,
          userId: t.userId,
          createdAt: t.createdAt,
          imagePaths: _editImagePaths,
        ),
      );
      // Apply entity side-effects for newly linked entities
      await applyEntitySideEffects(
        original: widget.transaction,
        newSubscriptionId: _editSubscriptionId,
        newDebtId: _editDebtId,
        newGoalId: _editGoalId,
        entityType: _editEntityType,
        txType: widget.transaction.type,
        amount: widget.transaction.amount,
      );

      if (mounted) setState(() => _editMode = false);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('Linked effects (goal progress, debt balance, subscription status, savings) will be reversed.'),
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
    if (confirmed != true || !mounted) return;

    final nav = Navigator.of(context);
    setState(() => _loading = true);
    try {
      final t = widget.transaction;

      if (t.goalId != null) {
        final goalCtrl = locator.get<GoalController>();
        await goalCtrl.withdrawFromGoal(t.goalId!, t.amount);
        final updated = (goalCtrl.data ?? []).where((g) => g.id == t.goalId).firstOrNull;
        if (updated != null && updated.status == GoalStatus.completed && updated.currentAmount < updated.targetAmount) {
          await goalCtrl.updateGoal(updated.copyWith(status: GoalStatus.active));
        }
      }
      if (t.debtId != null) {
        final debtCtrl = locator.get<DebtController>();
        final debt = (debtCtrl.data ?? []).where((d) => d.id == t.debtId).firstOrNull;
        if (debt != null) {
          final newRemaining = debt.remainingAmount + t.amount;
          await debtCtrl.updateDebt(debt.copyWith(
            remainingAmount: newRemaining,
            status: newRemaining > 0 ? DebtStatus.active : debt.status,
          ));
        }
      }
      if (t.subscriptionId != null) {
        final subCtrl = locator.get<SubscriptionController>();
        final sub = (subCtrl.data ?? []).where((s) => s.id == t.subscriptionId).firstOrNull;
        if (sub != null) {
          await subCtrl.updateSubscription(Subscription(
            id: sub.id, userId: sub.userId, name: sub.name, provider: sub.provider,
            amount: sub.amount, billingCycle: sub.billingCycle, status: sub.status,
            nextBillingDate: sub.nextBillingDate, lastBilledDate: null,
            notes: sub.notes,
            colorHex: sub.colorHex, iconCodePoint: sub.iconCodePoint,
            budgetProfileId: sub.budgetProfileId,
          ));
        }
      }
      if (t.walletId != null || t.toWalletId != null) {
        final walletCtrl = locator.get<WalletController>();
        final wallets = walletCtrl.data ?? [];
        // Reverse from-wallet: add back the amount that was deducted
        if (t.walletId != null) {
          final fromWallet = wallets.where((w) => w.id == t.walletId).firstOrNull;
          if (fromWallet != null) {
            final delta = t.type == TransactionType.transfer
                ? t.amount
                : (t.type == TransactionType.income
                    ? (fromWallet.type == WalletType.creditCard ? t.amount : -t.amount)
                    : (fromWallet.type == WalletType.creditCard ? -t.amount : t.amount));
            await walletCtrl.updateWallet(fromWallet.copyWith(balance: fromWallet.balance + delta));
          }
        }
        // Reverse to-wallet for transfers: subtract the amount that was added
        if (t.type == TransactionType.transfer && t.toWalletId != null) {
          final toWallet = wallets.where((w) => w.id == t.toWalletId).firstOrNull;
          if (toWallet != null) {
            final delta = toWallet.type == WalletType.creditCard ? t.amount : -t.amount;
            await walletCtrl.updateWallet(toWallet.copyWith(balance: toWallet.balance + delta));
          }
        }
      }

      await locator.get<TransactionController>().deleteTransaction(t.id!);
      TransactionImageService.deleteAll(t.id!).ignore();
      nav.pop();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
        setState(() => _loading = false);
      }
    }
  }

  void _showEntityTypePicker(bool isDark) {
    EntityLinkPickerSheet.showTypePicker(
      context,
      isDark: isDark,
      linkedLabel: _editEntityLabel,
      selectedId: _editSubscriptionId ?? _editDebtId ?? _editGoalId,
      onRemoveLink: () => setState(() {
        _editEntityType = null;
        _editSubscriptionId = null;
        _editDebtId = null;
        _editGoalId = null;
        _editEntityLabel = null;
      }),
      onSelect: (sel) => setState(() {
        _editEntityType = sel.type;
        _editSubscriptionId = sel.subscriptionId;
        _editDebtId = sel.debtId;
        _editGoalId = sel.goalId;
        _editEntityLabel = sel.label;
      }),
    );
  }

  Future<void> _pickDate(bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _editDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _editDate = picked;
        // Update monthly profile label to reflect new month
        if (_editProfileIsMonthly && _editProfileBaseName != null) {
          _editProfileName = '$_editProfileBaseName · ${DateFormat('MMM yyyy').format(picked)}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = widget.transaction;
    final isIncome = t.type == TransactionType.income;
    final isTransfer = t.type == TransactionType.transfer;
    final color = isTransfer ? AppColors.info : (isIncome ? AppColors.success : AppColors.error);
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final linked = _linkedLabel();

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
            child: Row(children: [
              if (_editMode) ...[
                GestureDetector(
                  onTap: () => setState(() => _editMode = false),
                  child: Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppColors.textSecondary)),
                ),
              ],
              Expanded(
                child: Text(
                  _editMode ? 'Edit Transaction' : (t.description ?? '–'),
                  style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!_editMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(isTransfer ? 'Transfer' : (isIncome ? 'Income' : 'Expense'),
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                ),
              ],
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary)),
              ),
            ]),
          ),
          Divider(height: 20, color: borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _editMode
                ? TransactionDetailEditBody(
                    isDark: isDark,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    isTransfer: isTransfer,
                    descController: _descCtrl,
                    editDate: _editDate,
                    onPickDate: () => _pickDate(isDark),
                    editCategory: _editCategory,
                    onCategoryTap: () => _showCategoryPicker(isDark),
                    editProfileId: _editProfileId,
                    editProfileName: _editProfileName,
                    onProfileTap: () => _showProfilePicker(isDark),
                    editEntityType: _editEntityType,
                    editEntityLabel: _editEntityLabel,
                    onEntityTap: () => _showEntityTypePicker(isDark),
                    editWalletId: _editWalletId,
                    editToWalletId: _editToWalletId,
                    editImagePaths: _editImagePaths,
                    transactionId: widget.transaction.id ?? '',
                    onAttachmentsChanged: () => setState(() {}),
                    loading: _loading,
                    onSave: _save,
                    onCancel: () => setState(() => _editMode = false),
                  )
                : TransactionDetailViewBody(
                    transaction: t,
                    isDark: isDark,
                    color: color,
                    textPrimary: textPrimary,
                    linked: linked,
                    isTransfer: isTransfer,
                    loading: _loading,
                    onEdit: () => setState(() => _editMode = true),
                    onDelete: t.id != null ? _delete : null,
                  ),
          ),
        ])),
      ),
    );
  }
}
