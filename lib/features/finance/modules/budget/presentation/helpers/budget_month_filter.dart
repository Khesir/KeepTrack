import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
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
