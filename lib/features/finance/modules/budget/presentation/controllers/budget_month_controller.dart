import 'dart:async';

import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/state/budget_screen_data.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/planned_payment_controller.dart';
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

class BudgetMonthController extends StreamState<AsyncState<BudgetScreenData>> {
  final BudgetController _budgetController;
  final MonthPlanController _monthPlanController;
  final DebtController _debtController;
  final PlannedPaymentController _plannedPaymentController;
  final TransactionController _transactionController;
  final SubscriptionController _subscriptionController;
  final SavingsController _savingsController;

  List<StreamSubscription> _subscriptions = [];

  BudgetMonthController({
    required BudgetController budgetController,
    required MonthPlanController monthPlanController,
    required DebtController debtController,
    required PlannedPaymentController plannedPaymentController,
    required TransactionController transactionController,
    required SubscriptionController subscriptionController,
    required SavingsController savingsController,
  }) : _budgetController = budgetController,
       _monthPlanController = monthPlanController,
       _debtController = debtController,
       _plannedPaymentController = plannedPaymentController,
       _transactionController = transactionController,
       _subscriptionController = subscriptionController,
       _savingsController = savingsController,
       super(const AsyncLoading());

  void init() {
    // Seed from current state so re-subscribing after navigation restores data immediately
    AsyncState<List<MonthPlan>> plans = _monthPlanController.state;
    AsyncState<List<Budget>> budget = _budgetController.state;
    AsyncState<List<Transaction>> transaction = _transactionController.state;
    AsyncState<List<Debt>> debts = _debtController.state;
    AsyncState<List<PlannedPayment>> payments = _plannedPaymentController.state;
    AsyncState<List<Subscription>> subs = _subscriptionController.state;
    AsyncState<List<SavingsBucket>> savings = _savingsController.state;

    void combine() {
      emit(
        AsyncData(
          BudgetScreenData(
            monthPlans: _unwrap(plans),
            budgets: _unwrap(budget),
            transactions: _unwrap(transaction),
            debts: _unwrap(debts),
            payments: _unwrap(payments),
            subscriptions: _unwrap(subs),
            savingsBuckets: _unwrap(savings),
          ),
        ),
      );
    }

    // Emit immediately with current state so screen renders on re-entry
    combine();

    _subscriptions = [
      _monthPlanController.stream.listen((s) {
        plans = s;
        if (s is! AsyncLoading) combine();
      }),
      _budgetController.stream.listen((s) {
        budget = s;
        if (s is! AsyncLoading) combine();
      }),
      _transactionController.stream.listen((s) {
        transaction = s;
        combine();
      }),
      _debtController.stream.listen((s) {
        debts = s;
        combine();
      }),
      _plannedPaymentController.stream.listen((s) {
        payments = s;
        combine();
      }),
      _subscriptionController.stream.listen((s) {
        subs = s;
        combine();
      }),
      _savingsController.stream.listen((s) {
        savings = s;
        combine();
      }),
    ];
  }

  List<T> _unwrap<T>(AsyncState<List<T>> state) =>
      state is AsyncData<List<T>> ? state.data : [];

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}
