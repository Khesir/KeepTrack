import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

double plannedAmountForCategory(BudgetController controller, String? categoryId) {
  if (categoryId == null) return 0;
  final state = controller.state;
  if (state is! AsyncData<List<Budget>>) return 0;
  final now = DateTime.now();
  final mk = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  for (final b in state.data) {
    if (b.month != mk || b.status != BudgetStatus.active) continue;
    for (final cat in b.categories) {
      if (cat.financeCategoryId == categoryId) return cat.targetAmount;
    }
  }
  return 0;
}

double alreadySpentForCategory(
  TransactionController controller,
  String? categoryId,
) {
  if (categoryId == null) return 0;
  final state = controller.state;
  if (state is! AsyncData<List<Transaction>>) return 0;
  final now = DateTime.now();
  return state.data
      .where(
        (t) =>
            t.financeCategoryId == categoryId &&
            t.date.year == now.year &&
            t.date.month == now.month,
      )
      .fold(0.0, (s, t) => s + t.amount);
}

Set<String>? allowedCategoryIdsForProfile(
  BudgetController controller,
  String? profileId,
  String? planMonth,
) {
  if (profileId == null) return null;
  final s = controller.state;
  if (s is! AsyncData<List<Budget>>) return null;
  final ids = s.data
      .where((b) {
        if (b.budgetProfileId != profileId) return false;
        if (planMonth != null) {
          return b.month == planMonth && b.status == BudgetStatus.active;
        }
        return b.status == BudgetStatus.active;
      })
      .expand((b) => b.categories.map((c) => c.financeCategoryId))
      .toSet();
  return ids.isEmpty ? null : ids;
}
