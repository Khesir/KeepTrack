import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/domain/entities/transaction_plan.dart';
import 'package:keep_track/features/finance/modules/wallet/data/models/wallet_model.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/helpers/create_transaction_effects.dart';
import 'package:keep_track/features/finance/presentation/helpers/split_entry.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';

Future<void> submitSplitTransactions({
  required TransactionController txController,
  required TransactionPlanController planController,
  required WalletController walletController,
  required DebtController debtController,
  required GoalController goalController,
  required AuthController authController,
  required List<SplitEntry> entries,
  required Wallet? selectedWallet,
  required String? selectedProfileId,
}) async {
  final walletDeltas = <String, double>{};
  for (final entry in entries) {
    final note = entry.noteCtrl.text.trim();
    if (entry.isPlan) {
      await planController.createPlan(
        TransactionPlan(
          userId: authController.currentUser?.id ?? '',
          description: note.isNotEmpty ? note : '${entry.type.displayName} plan',
          amount: entry.amount,
          type: entry.type,
          plannedDate: entry.date,
          financeCategoryId: entry.category?.id,
        ),
      );
      continue;
    }
    final wid = entry.walletId ?? selectedWallet?.id ?? '';
    if (wid.isEmpty) continue;
    final autoDesc = entry.entityLabel != null
        ? (entry.type == TransactionType.income
              ? 'From ${entry.entityLabel}'
              : 'To ${entry.entityLabel}')
        : (entry.type == TransactionType.income
              ? 'Earns ${entry.category?.name ?? ''}'
              : 'Pays ${entry.category?.name ?? ''}');
    await txController.createTransaction(
      Transaction(
        id: entry.id,
        amount: entry.amount,
        type: entry.type,
        financeCategoryId: entry.entityType != null ? null : entry.category?.id,
        date: entry.date,
        description: note.isNotEmpty ? note : autoDesc,
        budgetProfileId: entry.profileId ?? selectedProfileId,
        walletId: wid,
        debtId: entry.debtId,
        goalId: entry.goalId,
        subscriptionId: entry.subscriptionId,
        imagePaths: entry.imagePaths,
      ),
    );
    await applyCreateTransactionEntityEffect(
      debtController: debtController,
      goalController: goalController,
      entityType: entry.entityType,
      transactionType: entry.type,
      amount: entry.amount,
      debtId: entry.debtId,
      goalId: entry.goalId,
    );
    final allWallets = walletController.data ?? [];
    final w = allWallets.firstWhere(
      (w) => w.id == wid,
      orElse: () => WalletModel.fromEntity(selectedWallet!),
    );
    final delta = w.type == WalletType.creditCard
        ? (entry.type == TransactionType.income ? -entry.amount : entry.amount)
        : (entry.type == TransactionType.income ? entry.amount : -entry.amount);
    walletDeltas[wid] = (walletDeltas[wid] ?? 0) + delta;
  }
  final allWallets = walletController.data ?? [];
  for (final kv in walletDeltas.entries) {
    final w = allWallets.firstWhere(
      (w) => w.id == kv.key,
      orElse: () => WalletModel.fromEntity(selectedWallet!),
    );
    await walletController.updateWallet(w.copyWith(balance: w.balance + kv.value));
  }
}

Future<void> submitSingleTransaction({
  required TransactionController txController,
  required TransactionPlanController planController,
  required WalletController walletController,
  required DebtController debtController,
  required GoalController goalController,
  required AuthController authController,
  required bool isPlan,
  required String pendingTxId,
  required double amount,
  required TransactionType type,
  required DateTime date,
  required String description,
  required FinanceCategory? category,
  required String? entityType,
  required String? entityLabel,
  required String? selectedProfileId,
  required Wallet selectedWallet,
  required String? debtId,
  required String? goalId,
  required String? subscriptionId,
  required List<String> imagePaths,
}) async {
  if (isPlan) {
    await planController.createPlan(
      TransactionPlan(
        userId: authController.currentUser?.id ?? '',
        description: description,
        amount: amount,
        type: type,
        plannedDate: date,
        financeCategoryId: category?.id,
      ),
    );
    return;
  }
  final autoDesc = entityLabel != null
      ? (type == TransactionType.income ? 'From $entityLabel' : 'To $entityLabel')
      : (type == TransactionType.income
            ? 'Earns ${category!.name}'
            : 'Pays ${category!.name}');
  await txController.createTransaction(
    Transaction(
      id: pendingTxId,
      amount: amount,
      type: type,
      financeCategoryId: entityType != null ? null : category?.id,
      date: date,
      description: description.isEmpty ? autoDesc : description,
      budgetProfileId: selectedProfileId,
      walletId: selectedWallet.id,
      debtId: debtId,
      goalId: goalId,
      subscriptionId: subscriptionId,
      imagePaths: imagePaths,
    ),
  );
  await applyCreateTransactionEntityEffect(
    debtController: debtController,
    goalController: goalController,
    entityType: entityType,
    transactionType: type,
    amount: amount,
    debtId: debtId,
    goalId: goalId,
  );
  final delta = selectedWallet.type == WalletType.creditCard
      ? (type == TransactionType.income ? -amount : amount)
      : (type == TransactionType.income ? amount : -amount);
  await walletController.updateWallet(
    selectedWallet.copyWith(balance: selectedWallet.balance + delta),
  );
}
