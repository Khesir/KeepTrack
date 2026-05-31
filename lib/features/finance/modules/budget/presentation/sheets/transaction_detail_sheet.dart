import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
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
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/finance/presentation/screens/transactions/create_transaction_sheet.dart'
    show TransactionCategoryPicker;

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
    if (t.goalId != null) {
      final goals = locator.get<GoalController>().data ?? [];
      final goal = goals.where((g) => g.id == t.goalId).firstOrNull;
      return 'Goal: ${goal?.name ?? '—'}';
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
      return 'Subscription: ${sub?.name ?? '—'}';
    }
    if (t.savingsId != null) {
      final buckets = locator.get<SavingsController>().data ?? [];
      final bucket = buckets.where((b) => b.id == t.savingsId).firstOrNull;
      return 'Savings: ${bucket?.name ?? '—'}';
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
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
            child: Row(children: [
              Expanded(child: Text('Select Budget', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary))),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary)),
              ),
            ]),
          ),
          Divider(height: 1, color: divColor),
          // None option
          ListTile(
            title: Text('None', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
            trailing: _editProfileId == null ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
            onTap: () {
              setState(() { _editProfileId = null; _editProfileName = null; _editProfileBaseName = null; _editProfileIsMonthly = false; });
              Navigator.pop(context);
            },
          ),
          Divider(height: 1, color: divColor),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: profiles.length,
              itemBuilder: (_, i) {
                final p = profiles[i];
                final sel = _editProfileId == p.id;
                final displayName = p.isMonthly
                    ? '${p.name} · ${DateFormat('MMM yyyy').format(_editDate)}'
                    : p.name;
                return ListTile(
                  title: Text(displayName, style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: textPrimary)),
                  subtitle: p.isMonthly
                      ? Text('Monthly', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary))
                      : null,
                  trailing: sel ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
                  onTap: () {
                    setState(() {
                      _editProfileId = p.id;
                      _editProfileBaseName = p.name;
                      _editProfileIsMonthly = p.isMonthly;
                      _editProfileName = displayName;
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

  Future<void> _applyEntitySideEffects({
    required String? newSubscriptionId,
    required String? newDebtId,
    required String? newGoalId,
    required String? entityType,
    required TransactionType txType,
    required double amount,
  }) async {
    final origSub  = widget.transaction.subscriptionId;
    final origDebt = widget.transaction.debtId;
    final origGoal = widget.transaction.goalId;

    // Subscription: only if newly linked (not already linked to the same one)
    if (newSubscriptionId != null && newSubscriptionId != origSub) {
      await locator.get<SubscriptionController>().pay(newSubscriptionId);
    }

    // Debt / receivable: only if newly linked
    if (newDebtId != null && newDebtId != origDebt) {
      final isPayment = entityType == 'debt_payment' ||
          (entityType == 'lending' && txType == TransactionType.income);
      if (isPayment) {
        final debtCtrl = locator.get<DebtController>();
        final cached = (debtCtrl.data ?? []).where((d) => d.id == newDebtId).firstOrNull;
        if (cached == null) await debtCtrl.loadDebts();
        final debt = (debtCtrl.data ?? []).where((d) => d.id == newDebtId).firstOrNull;
        if (debt != null) {
          final newRemaining = (debt.remainingAmount - amount).clamp(0.0, double.infinity);
          if (newRemaining <= 0) {
            await debtCtrl.updateDebt(debt.copyWith(remainingAmount: 0, status: DebtStatus.settled));
          } else {
            await debtCtrl.updateDebtPayment(newDebtId, newRemaining);
          }
        }
      }
    }

    // Goal: only if newly linked
    if (newGoalId != null && newGoalId != origGoal) {
      final goalCtrl = locator.get<GoalController>();
      await goalCtrl.contributeToGoal(newGoalId, amount);
      final savingsCtrl = locator.get<SavingsController>();
      if (savingsCtrl.data == null) await savingsCtrl.loadSavings();
      final goal = (goalCtrl.data ?? []).where((g) => g.id == newGoalId).firstOrNull;
      if (goal?.savingsBucketId != null) {
        final bucket = (savingsCtrl.data ?? []).where((b) => b.id == goal!.savingsBucketId).firstOrNull;
        if (bucket != null) {
          await savingsCtrl.updateSavingsBucket(bucket.copyWith(balance: bucket.balance + amount));
        }
      }
    }
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
          savingsId: t.savingsId,
          userId: t.userId,
          createdAt: t.createdAt,
        ),
      );
      // Apply entity side-effects for newly linked entities
      await _applyEntitySideEffects(
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
        await locator.get<GoalController>().withdrawFromGoal(t.goalId!, t.amount);
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
            budgetCategoryId: sub.budgetCategoryId, notes: sub.notes,
            colorHex: sub.colorHex, iconCodePoint: sub.iconCodePoint,
            budgetProfileId: sub.budgetProfileId,
          ));
        }
      }
      if (t.savingsId != null) {
        final savingsCtrl = locator.get<SavingsController>();
        final bucket = (savingsCtrl.data ?? []).where((b) => b.id == t.savingsId).firstOrNull;
        if (bucket != null) {
          await savingsCtrl.updateSavingsBucket(
            bucket.copyWith(balance: (bucket.balance - t.amount).clamp(0.0, double.infinity)),
          );
        }
      }

      await locator.get<TransactionController>().deleteTransaction(t.id!);
      nav.pop();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
        setState(() => _loading = false);
      }
    }
  }

  void _showEntityTypePicker(bool isDark) {
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);

    final types = [
      (icon: Icons.autorenew_rounded, label: 'Subscription', sub: 'Recurring service payment', type: 'subscription', color: AppColors.warning),
      (icon: Icons.arrow_upward_rounded, label: 'Debt', sub: 'Money you owe', type: 'debt_payment', color: AppColors.error),
      (icon: Icons.arrow_downward_rounded, label: 'Receivable', sub: 'Money owed to you', type: 'lending', color: AppColors.success),
      (icon: Icons.flag_outlined, label: 'Goal', sub: 'Savings contribution', type: 'goal', color: AppColors.accent),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
            child: Row(children: [
              Expanded(child: Text('Link to…', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary))),
              GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
            ]),
          ),
          Divider(height: 1, color: divColor),
          if (_editEntityLabel != null) ...[
            ListTile(
              leading: Icon(Icons.link_off_rounded, size: 18, color: AppColors.error),
              title: Text('Remove link', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.error)),
              onTap: () {
                setState(() { _editEntityType = null; _editSubscriptionId = null; _editDebtId = null; _editGoalId = null; _editEntityLabel = null; });
                Navigator.pop(context);
              },
            ),
            Divider(height: 1, color: divColor),
          ],
          ...types.map((t) => ListTile(
            leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: t.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)), child: Icon(t.icon, size: 17, color: t.color)),
            title: Text(t.label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            subtitle: Text(t.sub, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
            onTap: () { Navigator.pop(context); _showEntityPicker(t.type, isDark); },
          )),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  void _showEntityPicker(String entityType, bool isDark) {
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);

    String title;
    Widget listWidget;

    Widget buildList<T>(List<T> items, String Function(T) label, String? Function(T) id, Color dotColor, void Function(T) onSelect) {
      if (items.isEmpty) {
        return Center(child: Padding(padding: const EdgeInsets.all(24),
            child: Text('No items found', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary))));
      }
      return Column(mainAxisSize: MainAxisSize.min, children: items.map((e) {
        final sel = id(e) == (_editSubscriptionId ?? _editDebtId ?? _editGoalId);
        return ListTile(
          leading: Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          title: Text(label(e), style: GoogleFonts.dmSans(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: textPrimary)),
          trailing: sel ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
          onTap: () { onSelect(e); Navigator.pop(context); },
        );
      }).toList());
    }

    switch (entityType) {
      case 'subscription':
        title = 'Select Subscription';
        final subs = (locator.get<SubscriptionController>().data ?? []).where((s) => s.status == SubscriptionStatus.active).toList()..sort((a, b) => a.name.compareTo(b.name));
        listWidget = buildList<Subscription>(subs, (s) => s.name, (s) => s.id, AppColors.warning,
            (s) => setState(() { _editEntityType = 'subscription'; _editSubscriptionId = s.id; _editDebtId = null; _editGoalId = null; _editEntityLabel = s.name; }));
      case 'debt_payment':
        title = 'Select Debt';
        final debts = (locator.get<DebtController>().data ?? []).where((d) => d.type == DebtType.borrowing && d.status == DebtStatus.active).toList()..sort((a, b) => a.personName.compareTo(b.personName));
        listWidget = buildList<Debt>(debts, (d) => d.personName, (d) => d.id, AppColors.error,
            (d) => setState(() { _editEntityType = 'debt_payment'; _editDebtId = d.id; _editSubscriptionId = null; _editGoalId = null; _editEntityLabel = d.personName; }));
      case 'lending':
        title = 'Select Receivable';
        final recv = (locator.get<DebtController>().data ?? []).where((d) => d.type == DebtType.lending && d.status == DebtStatus.active).toList()..sort((a, b) => a.personName.compareTo(b.personName));
        listWidget = buildList<Debt>(recv, (d) => d.personName, (d) => d.id, AppColors.success,
            (d) => setState(() { _editEntityType = 'lending'; _editDebtId = d.id; _editSubscriptionId = null; _editGoalId = null; _editEntityLabel = d.personName; }));
      case 'goal':
        title = 'Select Goal';
        final goals = (locator.get<GoalController>().data ?? []).where((g) => g.status == GoalStatus.active).toList()..sort((a, b) => a.name.compareTo(b.name));
        listWidget = buildList<Goal>(goals, (g) => g.name, (g) => g.id, AppColors.accent,
            (g) => setState(() { _editEntityType = 'goal'; _editGoalId = g.id; _editSubscriptionId = null; _editDebtId = null; _editEntityLabel = g.name; }));
      default:
        return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
            child: Row(children: [
              Expanded(child: Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary))),
              GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
            ]),
          ),
          Divider(height: 1, color: divColor),
          ConstrainedBox(constraints: const BoxConstraints(maxHeight: 320), child: SingleChildScrollView(child: listWidget)),
          const SizedBox(height: 8),
        ])),
      ),
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
    final color = isIncome ? AppColors.success : AppColors.error;
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
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
                  _editMode ? 'Edit Transaction' : (t.description ?? '—'),
                  style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!_editMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(isIncome ? 'Income' : 'Expense',
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
                ? _buildEditBody(isDark, borderColor, textPrimary)
                : _buildViewBody(isDark, color, textPrimary, linked),
          ),
        ])),
      ),
    );
  }

  Widget _buildViewBody(bool isDark, Color color, Color textPrimary, String? linked) {
    final t = widget.transaction;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Amount', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
            Text(
              '${isIncome(t) ? '+' : '-'}${currencyFormatter.format(t.amount, decimalDigits: 2)}',
              style: GoogleFonts.dmMono(fontSize: 22, fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ])),
          if (t.hasFee)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Fee', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              Text('+${currencyFormatter.format(t.fee, decimalDigits: 2)}',
                  style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
        ]),
      ),
      const SizedBox(height: 14),
      _InfoRow(isDark: isDark, label: 'Date', value: DateFormat('MMMM d, yyyy').format(t.date), textPrimary: textPrimary),
      if (linked != null) _InfoRow(isDark: isDark, label: 'Linked to', value: linked, textPrimary: AppColors.accent),
      if (t.notes != null && t.notes!.isNotEmpty) _InfoRow(isDark: isDark, label: 'Notes', value: t.notes!, textPrimary: textPrimary),
      const SizedBox(height: 20),
      _Button(label: 'Edit Transaction', icon: Icons.edit_outlined,
          color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
          outlined: true, isDark: isDark, onTap: () => setState(() => _editMode = true)),
      const SizedBox(height: 8),
      _Button(label: 'Delete Transaction', icon: Icons.delete_outline_rounded,
          color: AppColors.error, loading: _loading, onTap: t.id != null ? _delete : null),
    ]);
  }

  bool isIncome(Transaction t) => t.type == TransactionType.income;

  Widget _buildEditBody(bool isDark, Color borderColor, Color textPrimary) {
    final chipBg = isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.background;
    final chipBorder = isDark ? AppColors.border.withValues(alpha: 0.25) : AppColors.border.withValues(alpha: 0.6);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Description
      TextField(
        controller: _descCtrl,
        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 12),

      // Date
      GestureDetector(
        onTap: () => _pickDate(isDark),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(4)),
          child: Row(children: [
            Expanded(child: Text(DateFormat('MMMM d, yyyy').format(_editDate),
                style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary))),
            Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
          ]),
        ),
      ),
      const SizedBox(height: 12),

      // Category picker
      GestureDetector(
        onTap: () => _showCategoryPicker(isDark),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _editCategory != null ? AppColors.accent.withValues(alpha: 0.4) : chipBorder, width: 0.5),
          ),
          child: Row(children: [
            Icon(Icons.category_outlined, size: 16,
                color: _editCategory != null ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(child: Text(
              _editCategory?.name ?? 'Select Category',
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500,
                  color: _editCategory != null ? textPrimary : AppColors.textSecondary),
            )),
            Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
          ]),
        ),
      ),
      const SizedBox(height: 8),

      // Budget profile picker
      GestureDetector(
        onTap: () => _showProfilePicker(isDark),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _editProfileId != null ? AppColors.accent.withValues(alpha: 0.4) : chipBorder, width: 0.5),
          ),
          child: Row(children: [
            Icon(Icons.account_balance_wallet_outlined, size: 16,
                color: _editProfileId != null ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(child: Text(
              _editProfileName ?? 'No Budget Profile',
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500,
                  color: _editProfileId != null ? textPrimary : AppColors.textSecondary),
            )),
            Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
          ]),
        ),
      ),
      const SizedBox(height: 8),

      // Entity link picker
      GestureDetector(
        onTap: () => _showEntityTypePicker(isDark),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _editEntityLabel != null ? AppColors.success.withValues(alpha: 0.4) : chipBorder, width: 0.5),
          ),
          child: Row(children: [
            Icon(_editEntityType != null ? _entityIcon(_editEntityType!) : Icons.link_rounded,
                size: 16, color: _editEntityLabel != null ? AppColors.success : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(child: Text(
              _editEntityLabel ?? 'Link Entity (optional)',
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500,
                  color: _editEntityLabel != null ? textPrimary : AppColors.textSecondary),
            )),
            Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
          ]),
        ),
      ),
      const SizedBox(height: 20),

      _Button(label: 'Save Changes', icon: Icons.check_rounded, color: AppColors.accent, loading: _loading, onTap: _save),
      const SizedBox(height: 8),
      _Button(label: 'Cancel', icon: Icons.close_rounded, color: AppColors.textSecondary,
          outlined: true, isDark: isDark, onTap: () => setState(() => _editMode = false)),
    ]);
  }

  IconData _entityIcon(String type) => switch (type) {
    'subscription' => Icons.autorenew_rounded,
    'debt_payment' => Icons.arrow_upward_rounded,
    'lending'      => Icons.arrow_downward_rounded,
    'goal'         => Icons.flag_outlined,
    _              => Icons.link_rounded,
  };
}

class _InfoRow extends StatelessWidget {
  final bool isDark;
  final String label, value;
  final Color? textPrimary;
  const _InfoRow({required this.isDark, required this.label, required this.value, this.textPrimary});

  @override
  Widget build(BuildContext context) {
    final def = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary ?? def))),
      ]),
    );
  }
}

class _Button extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading, outlined;
  final bool? isDark;
  final VoidCallback? onTap;
  const _Button({required this.label, required this.icon, required this.color, this.loading = false, this.outlined = false, this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(width: double.infinity, height: 46,
        child: OutlinedButton.icon(
          onPressed: onTap, icon: Icon(icon, size: 15), label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color, side: BorderSide(color: color.withValues(alpha: 0.4)),
            textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }
    return SizedBox(width: double.infinity, height: 46,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 15),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: onTap == null ? AppColors.textTertiary : color,
          foregroundColor: Colors.white, elevation: 0,
          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
