import 'dart:async';

import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/state/budget_screen_data.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/planned_payment_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

class BudgetMonthController extends StreamState<AsyncState<BudgetScreenData>> {
  final BudgetController _budgetController;
  final MonthPlanController _monthPlanController;
  final DebtController _debtController;
  final PlannedPaymentController _plannedPaymentController;
  final TransactionController _transactionController;

  List<StreamSubscription> _subscriptions = [];

  BudgetMonthController({
    required BudgetController budgetController,
    required MonthPlanController monthPlanController,
    required DebtController debtController,
    required PlannedPaymentController plannedPaymentController,
    required TransactionController transactionController,
  }) : _budgetController = budgetController,
       _monthPlanController = monthPlanController,
       _debtController = debtController,
       _plannedPaymentController = plannedPaymentController,
       _transactionController = transactionController,
       super(const AsyncLoading());

  void init() {
    // latest known values -- start as loading
    AsyncState<List<MonthPlan>> plans = const AsyncLoading();
    AsyncState<List<Budget>> budget = const AsyncLoading();
    AsyncState<List<Transaction>> transaction = const AsyncLoading();
    AsyncState<List<Debt>> debts = const AsyncLoading();
    AsyncState<List<PlannedPayment>> payments = const AsyncLoading();

    void combine() {
      emit(
        AsyncData(
          BudgetScreenData(
            monthPlans: _unwrap(plans),
            budgets: _unwrap(budget),
            transactions: _unwrap(transaction),
            debts: _unwrap(debts),
            payments: _unwrap(payments),
          ),
        ),
      );
    }

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
        combine(); // transaction can emit mid-load, always combine
      }),
      _debtController.stream.listen((s) {
        debts = s;
        combine();
      }),
      _plannedPaymentController.stream.listen((s) {
        payments = s;
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
