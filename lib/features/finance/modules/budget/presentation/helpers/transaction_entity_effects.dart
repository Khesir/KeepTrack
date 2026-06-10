import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';

Future<void> applyEntitySideEffects({
  required Transaction original,
  required String? newSubscriptionId,
  required String? newDebtId,
  required String? newGoalId,
  required String? entityType,
  required TransactionType txType,
  required double amount,
}) async {
  final origSub  = original.subscriptionId;
  final origDebt = original.debtId;
  final origGoal = original.goalId;

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
    final walletCtrl = locator.get<WalletController>();
    if (walletCtrl.data == null) await walletCtrl.loadWallets();
    final goal = (goalCtrl.data ?? []).where((g) => g.id == newGoalId).firstOrNull;
    if (goal?.savingsBucketId != null) {
      final wallet = (walletCtrl.data ?? []).where((w) => w.id == goal!.savingsBucketId).firstOrNull;
      if (wallet != null) {
        await walletCtrl.updateWallet(wallet.copyWith(balance: wallet.balance + amount));
      }
    }
  }
}
