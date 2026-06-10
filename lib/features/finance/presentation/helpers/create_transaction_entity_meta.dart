import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';

String? buildEntityMeta({
  required String? entityType,
  required String? debtId,
  required String? goalId,
  required String? subscriptionId,
  required DebtController debtController,
  required GoalController goalController,
  required SubscriptionController subController,
}) {
  if (entityType == null) return null;
  if (debtId != null) {
    final debt = debtController.data?.where((d) => d.id == debtId).firstOrNull;
    if (debt == null) return null;
    return entityType == 'debt_payment'
        ? 'Still owe ${currencyFormatter.format(debt.remainingAmount)} to ${debt.personName}'
        : 'Expecting ${currencyFormatter.format(debt.remainingAmount)} from ${debt.personName}';
  }
  if (goalId != null) {
    final goal = goalController.data?.where((g) => g.id == goalId).firstOrNull;
    if (goal == null) return null;
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(
      0.0,
      double.infinity,
    );
    return '${currencyFormatter.format(goal.currentAmount)} of ${currencyFormatter.format(goal.targetAmount)} saved · ${currencyFormatter.format(remaining)} to go';
  }
  if (subscriptionId != null) {
    final sub = subController.data
        ?.where((s) => s.id == subscriptionId)
        .firstOrNull;
    if (sub == null) return null;
    return '${currencyFormatter.format(sub.amount)} recurring';
  }
  return null;
}
