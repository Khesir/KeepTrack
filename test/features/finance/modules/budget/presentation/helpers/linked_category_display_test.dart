import 'package:flutter_test/flutter_test.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/linked_category_display.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/debt/domain/repositories/debt_repository.dart';
import 'package:keep_track/features/finance/modules/goal/data/datasources/local/goal_datasource_local.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/goal/domain/repositories/goal_repository.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';

/// Minimal fake repositories that resolve canned data. `dueDate`/
/// `nextBillingDate` are deliberately kept null/in-the-past on the fakes so
/// the controllers' constructor-triggered load never reaches into
/// NotificationScheduler (not registered in these tests).
class _FakeDebtRepository implements DebtRepository {
  final List<Debt> debts;
  _FakeDebtRepository(this.debts);

  @override
  Future<Result<List<Debt>>> getDebts({String? budgetProfileId}) async => Result.success(debts);

  @override
  Future<Result<Debt>> getDebtById(String id) => throw UnimplementedError();
  @override
  Future<Result<Debt>> createDebt(Debt debt) => throw UnimplementedError();
  @override
  Future<Result<Debt>> updateDebt(Debt debt) => throw UnimplementedError();
  @override
  Future<Result<void>> deleteDebt(String id) => throw UnimplementedError();
  @override
  Future<Result<List<Debt>>> getDebtsByType(DebtType type) => throw UnimplementedError();
  @override
  Future<Result<List<Debt>>> getDebtsByStatus(DebtStatus status) => throw UnimplementedError();
  @override
  Future<Result<Debt>> updateDebtPayment(String id, double newRemainingAmount) => throw UnimplementedError();
  @override
  Future<Result<Debt>> settleDebt(String id) => throw UnimplementedError();
  @override
  Future<Result<Debt>> payDebt(String id, {required double amount, double? fee}) => throw UnimplementedError();
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  final List<Subscription> subscriptions;
  _FakeSubscriptionRepository(this.subscriptions);

  @override
  Future<Result<List<Subscription>>> getSubscriptions({String? budgetProfileId}) async => Result.success(subscriptions);

  @override
  Future<Result<Subscription>> createSubscription(Subscription subscription) => throw UnimplementedError();
  @override
  Future<Result<Subscription>> updateSubscription(Subscription subscription) => throw UnimplementedError();
  @override
  Future<Result<void>> deleteSubscription(String id) => throw UnimplementedError();
  @override
  Future<Result<Subscription>> pay(String id, {String? budgetId}) => throw UnimplementedError();
}

class _FakeGoalRepository implements GoalRepository {
  final List<Goal> goals;
  _FakeGoalRepository(this.goals);

  @override
  Future<Result<List<Goal>>> getGoals({String? budgetProfileId}) async => Result.success(goals);

  @override
  Future<Result<Goal>> getGoalById(String id) => throw UnimplementedError();
  @override
  Future<Result<Goal>> createGoal(Goal goal) => throw UnimplementedError();
  @override
  Future<Result<Goal>> updateGoal(Goal goal) => throw UnimplementedError();
  @override
  Future<Result<void>> deleteGoal(String id) => throw UnimplementedError();
  @override
  Future<Result<List<Goal>>> getGoalsByStatus(GoalStatus status) => throw UnimplementedError();
  @override
  Future<Result<Goal>> updateGoalProgress(String id, double newAmount) => throw UnimplementedError();
}

class _FakeLocalCache implements LocalCache {
  @override
  Future<void> clear(String box) => throw UnimplementedError();
  @override
  Future<void> clearAll() => throw UnimplementedError();
  @override
  Future<void> delete(String box, String key) => throw UnimplementedError();
  @override
  Future<void> dispose() => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> get(String box, String key) => throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getAll(String box) async => [];
  @override
  Future<void> init() async {}
  @override
  Future<void> put(String box, String key, Map<String, dynamic> data) => throw UnimplementedError();
  @override
  Future<void> putAll(String box, Map<String, Map<String, dynamic>> entries) => throw UnimplementedError();
}

BudgetCategory _linkedCategory({String? subscriptionId, String? debtId, String? goalId}) {
  return BudgetCategory(
    budgetId: 'budget-1',
    financeCategoryId: 'fc-1',
    targetAmount: 100,
    subscriptionId: subscriptionId,
    debtId: debtId,
    goalId: goalId,
  );
}

Subscription _subscription({required String id, SubscriptionStatus status = SubscriptionStatus.active}) {
  return Subscription(
    id: id,
    userId: 'user-1',
    name: 'Netflix',
    amount: 15.99,
    billingCycle: BillingCycle.monthly,
    status: status,
    // Kept in the past so the controller's notification scheduling
    // short-circuits before touching NotificationScheduler.
    nextBillingDate: DateTime(2020, 1, 1),
  );
}

Debt _debt({required String id, required DebtType type, DebtStatus status = DebtStatus.active}) {
  return Debt(
    id: id,
    type: type,
    personName: 'Alex',
    description: 'Car loan',
    originalAmount: 1000,
    remainingAmount: 500,
    startDate: DateTime(2025, 1, 1),
    status: status,
    // No dueDate -> notification scheduling short-circuits immediately.
  );
}

Goal _goal({required String id, GoalStatus status = GoalStatus.active}) {
  return Goal(
    id: id,
    name: 'Emergency Fund',
    description: 'Rainy day',
    targetAmount: 5000,
    status: status,
  );
}

Future<DebtController> _debtControllerWith(List<Debt> debts) async {
  final controller = DebtController(_FakeDebtRepository(debts));
  await controller.loadDebts();
  return controller;
}

Future<SubscriptionController> _subscriptionControllerWith(List<Subscription> subs) async {
  final controller = SubscriptionController(_FakeSubscriptionRepository(subs));
  await controller.loadSubscriptions();
  return controller;
}

Future<GoalController> _goalControllerWith(List<Goal> goals) async {
  final controller = GoalController(_FakeGoalRepository(goals), GoalDataSourceLocal(_FakeLocalCache()));
  await controller.loadGoals();
  return controller;
}

void main() {
  setUp(() {
    locator.reset();
  });

  tearDown(() {
    locator.reset();
  });

  group('resolveLinkedCategoryDisplay', () {
    test('unlinked category has no type label', () {
      final category = _linkedCategory();

      final display = resolveLinkedCategoryDisplay(category);

      expect(display.typeLabel, isNull);
      expect(display.statusLabel, isNull);
      expect(display.statusColor, isNull);
    });

    test('subscription link, entity found, active status -> Subscription badge, no status pill', () async {
      locator.registerSingleton<SubscriptionController>(
          await _subscriptionControllerWith([_subscription(id: 'sub-1')]));
      final category = _linkedCategory(subscriptionId: 'sub-1');

      final display = resolveLinkedCategoryDisplay(category);

      expect(display.typeLabel, 'Subscription');
      expect(display.name, 'Netflix');
      expect(display.statusLabel, isNull);
      expect(display.statusColor, isNull);
    });

    test('subscription link, entity found, non-active status -> Subscription badge, status pill present', () async {
      locator.registerSingleton<SubscriptionController>(await _subscriptionControllerWith(
          [_subscription(id: 'sub-1', status: SubscriptionStatus.paused)]));
      final category = _linkedCategory(subscriptionId: 'sub-1');

      final display = resolveLinkedCategoryDisplay(category);

      expect(display.typeLabel, 'Subscription');
      expect(display.statusLabel, 'Paused');
      expect(display.statusColor, AppColors.warning);
    });

    test('subscription link, entity hard-deleted -> Subscription badge still shown, no status pill', () async {
      locator.registerSingleton<SubscriptionController>(await _subscriptionControllerWith([]));
      final category = _linkedCategory(subscriptionId: 'sub-missing');

      final display = resolveLinkedCategoryDisplay(category);

      expect(display.typeLabel, 'Subscription');
      expect(display.statusLabel, isNull);
    });

    test('goal link, entity found -> Goal badge', () async {
      locator.registerSingleton<GoalController>(await _goalControllerWith([_goal(id: 'goal-1')]));
      final category = _linkedCategory(goalId: 'goal-1');

      final display = resolveLinkedCategoryDisplay(category);

      expect(display.typeLabel, 'Goal');
      expect(display.name, 'Emergency Fund');
    });

    test('goal link, entity hard-deleted -> Goal badge still shown', () async {
      locator.registerSingleton<GoalController>(await _goalControllerWith([]));
      final category = _linkedCategory(goalId: 'goal-missing');

      final display = resolveLinkedCategoryDisplay(category);

      expect(display.typeLabel, 'Goal');
    });

    test('debt link, entity found, borrowing -> Debt badge', () async {
      locator.registerSingleton<DebtController>(
          await _debtControllerWith([_debt(id: 'debt-1', type: DebtType.borrowing)]));
      final category = _linkedCategory(debtId: 'debt-1');

      final display = resolveLinkedCategoryDisplay(category);

      expect(display.typeLabel, 'Debt');
    });

    test('debt link, entity found, lending -> Receivable badge', () async {
      locator.registerSingleton<DebtController>(
          await _debtControllerWith([_debt(id: 'debt-1', type: DebtType.lending)]));
      final category = _linkedCategory(debtId: 'debt-1');

      final display = resolveLinkedCategoryDisplay(category);

      expect(display.typeLabel, 'Receivable');
    });

    test('debt link, entity hard-deleted -> generic Debt badge fallback', () async {
      locator.registerSingleton<DebtController>(await _debtControllerWith([]));
      final category = _linkedCategory(debtId: 'debt-missing');

      final display = resolveLinkedCategoryDisplay(category);

      expect(display.typeLabel, 'Debt');
    });
  });
}
