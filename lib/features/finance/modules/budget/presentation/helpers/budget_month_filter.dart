import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';

class BudgetMonthFilter {
  BudgetMonthFilter._();

  static List<Transaction> filterTransactions(
    List<Transaction> all,
    DateTime month,
  ) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return all
        .where((t) => !t.date.isBefore(start) && t.date.isBefore(end))
        .toList();
  }

  static Map<String, double> buildSpentByCategory(
    List<Transaction> transactions,
  ) {
    final map = <String, double>{};
    for (final t in transactions) {
      if (t.financeCategoryId != null) {
        map[t.financeCategoryId!] =
            (map[t.financeCategoryId!] ?? 0.0) + t.amount;
      }
    }
    return map;
  }

  /// Spend for a linked Budget Category, computed by matching transactions
  /// against the category's own linked entity id (subscriptionId/debtId/
  /// goalId) rather than the category-wide `financeCategoryId` match that
  /// [buildSpentByCategory] uses for plain categories. Returns 0 for an
  /// unlinked category. See CONTEXT.md ("Linked spend").
  static double buildLinkedSpend(
    BudgetCategory category,
    List<Transaction> transactions,
  ) {
    if (!category.isLinked) return 0.0;
    double total = 0.0;
    for (final t in transactions) {
      final matches = (category.subscriptionId != null &&
              t.subscriptionId == category.subscriptionId) ||
          (category.debtId != null && t.debtId == category.debtId) ||
          (category.goalId != null && t.goalId == category.goalId);
      if (matches) total += t.amount;
    }
    return total;
  }

  /// The set of Subscription/Debt/Goal ids currently linked to any Budget
  /// Category in the given list (a single month's/budget snapshot's
  /// categories). Single source of truth used both to exclude already-linked
  /// entities from the link picker and to show the reverse "Linked" badge on
  /// the entity's own tab. See CONTEXT.md ("Link uniqueness", "Linked badge").
  static Set<String> linkedEntityIds(List<BudgetCategory> categories) {
    final ids = <String>{};
    for (final c in categories) {
      if (c.subscriptionId != null) ids.add(c.subscriptionId!);
      if (c.debtId != null) ids.add(c.debtId!);
      if (c.goalId != null) ids.add(c.goalId!);
    }
    return ids;
  }

  static bool debtVisibleInMonth(
    Debt d,
    DateTime monthStart,
    DateTime monthEnd,
  ) {
    if (d.startDate.isAfter(monthEnd)) return false;
    if (d.status == DebtStatus.active) return true;
    if (d.settledAt == null) return true;
    return !d.settledAt!.isBefore(monthStart);
  }

  static List<Budget> filterBudgets(
    List<Budget> budgets,
    MonthPlan? monthPlan,
  ) {
    final hasMonthPlan = monthPlan != null;
    final allowedIds = monthPlan?.budgetIds.toSet() ?? {};
    return hasMonthPlan
        ? (budgets
              .where((b) => b.id != null && allowedIds.contains(b.id))
              .toList()
            ..sort((a, b) {
              if (a.budgetType == b.budgetType) return 0;
              return a.budgetType == BudgetType.income ? -1 : 1;
            }))
        : <Budget>[];
  }
}
