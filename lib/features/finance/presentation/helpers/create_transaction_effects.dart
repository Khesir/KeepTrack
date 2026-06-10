import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';

Future<void> applyCreateTransactionEntityEffect({
  required DebtController debtController,
  required GoalController goalController,
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
    final updated = await debtController.payDebt(debtId!, amount: amount);
    if (updated.remainingAmount <= 0 &&
        updated.status != DebtStatus.settled) {
      await debtController.settleDebt(debtId);
    }
  }

  if (goalId != null && entityType == 'goal') {
    await goalController.contributeToGoal(goalId, amount);
  }
}
