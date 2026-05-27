import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';

class BudgetScreenData {
  final List<MonthPlan> monthPlans;
  final List<Budget> budgets;
  final List<Transaction> transactions;
  final List<Debt> debts;
  final List<PlannedPayment> payments;
  final List<Subscription> subscriptions;
  final List<Goal> goals;

  const BudgetScreenData({
    required this.monthPlans,
    required this.budgets,
    required this.transactions,
    required this.debts,
    required this.payments,
    this.subscriptions = const [],
    this.goals = const [],
  });

  BudgetScreenData copyWith({
    List<MonthPlan>? monthPlans,
    List<Budget>? budgets,
    List<Transaction>? transactions,
    List<Debt>? debts,
    List<PlannedPayment>? payments,
    List<Subscription>? subscriptions,
    List<Goal>? goals,
  }) => BudgetScreenData(
    monthPlans: monthPlans ?? this.monthPlans,
    budgets: budgets ?? this.budgets,
    transactions: transactions ?? this.transactions,
    debts: debts ?? this.debts,
    payments: payments ?? this.payments,
    subscriptions: subscriptions ?? this.subscriptions,
    goals: goals ?? this.goals,
  );

  static BudgetScreenData empty() => const BudgetScreenData(
    monthPlans: [],
    budgets: [],
    transactions: [],
    debts: [],
    payments: [],
    subscriptions: [],
    goals: [],
  );
}
