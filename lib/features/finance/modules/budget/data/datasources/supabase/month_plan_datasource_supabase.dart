import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/month_plan_model.dart';
import '../../models/budget_model.dart';
import '../../models/budget_category_model.dart';
import '../month_plan_datasource.dart';
import '../budget_datasource.dart';
import '../budget_category_datasource.dart';

/// Supabase implementation of MonthPlanDataSource
class MonthPlanDataSourceSupabase implements MonthPlanDataSource {
  final SupabaseService supabaseService;
  final BudgetDataSource budgetDataSource;
  final BudgetCategoryDataSource categoryDataSource;

  static const String tableName = 'month_plans';

  MonthPlanDataSourceSupabase(
    this.supabaseService,
    this.budgetDataSource,
    this.categoryDataSource,
  );

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Attach the budgets for [plan.month] to [plan]
  Future<MonthPlanModel> _hydratePlan(MonthPlanModel plan) async {
    final budgets = await budgetDataSource.getBudgetsByMonth(plan.month);
    return plan.withBudgets(budgets);
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  @override
  Future<List<MonthPlanModel>> getMonthPlans() async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('user_id', supabaseService.userId!)
          .order('month', ascending: false);

      final plans = (response as List)
          .map((doc) => MonthPlanModel.fromJson(Map<String, dynamic>.from(doc)))
          .toList();

      return Future.wait(plans.map(_hydratePlan));
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch month plans',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<MonthPlanModel?> getMonthPlanByMonth(String month) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('month', month)
          .eq('user_id', supabaseService.userId!)
          .maybeSingle();

      if (response == null) return null;

      final plan = MonthPlanModel.fromJson(Map<String, dynamic>.from(response));
      return _hydratePlan(plan);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch month plan for $month',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  @override
  Future<MonthPlanModel> createMonthPlan(MonthPlanModel plan) async {
    try {
      final data = {
        'month': plan.month,
        'user_id': supabaseService.userId!,
        if (plan.accountId != null) 'account_id': plan.accountId,
        if (plan.notes != null) 'notes': plan.notes,
      };

      final response = await supabaseService.client
          .from(tableName)
          .insert(data)
          .select()
          .single();

      final created =
          MonthPlanModel.fromJson(Map<String, dynamic>.from(response));
      return _hydratePlan(created);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to create month plan',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<MonthPlanModel> updateMonthPlan(MonthPlanModel plan) async {
    try {
      if (plan.id == null) throw Exception('Cannot update MonthPlan without id');

      final data = {
        if (plan.notes != null) 'notes': plan.notes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabaseService.client
          .from(tableName)
          .update(data)
          .eq('id', plan.id!)
          .eq('user_id', supabaseService.userId!);

      final updated = await getMonthPlanByMonth(plan.month);
      if (updated == null) throw Exception('MonthPlan not found after update');
      return updated;
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to update month plan',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteMonthPlan(String id) async {
    try {
      await supabaseService.client
          .from(tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to delete month plan',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  @override
  Future<void> deleteMonthPlanWithBudgets(String id, String month) async {
    try {
      // Delete all budgets for the month — budget_categories cascade via FK
      await supabaseService.client
          .from('budgets')
          .delete()
          .eq('month', month)
          .eq('user_id', supabaseService.userId!);

      // Delete the month plan row
      await supabaseService.client
          .from(tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to delete month plan with budgets',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<MonthPlanModel> copyMonthPlan(
    String sourceMonth,
    String targetMonth,
  ) async {
    try {
      // 1. Load all source budgets (with categories)
      final sourceBudgets =
          await budgetDataSource.getBudgetsByMonth(sourceMonth);

      if (sourceBudgets.isEmpty) {
        throw Exception('No budgets found for source month: $sourceMonth');
      }

      // 2. Get or create the target MonthPlan
      MonthPlanModel targetPlan;
      final existing = await getMonthPlanByMonth(targetMonth);
      if (existing != null) {
        targetPlan = existing;
      } else {
        targetPlan = await createMonthPlan(
          MonthPlanModel(month: targetMonth, userId: supabaseService.userId),
        );
      }

      // 3. Clone each budget into the target month
      final clonedBudgets = <BudgetModel>[];

      for (final sourceBudget in sourceBudgets) {
        // Build a fresh budget for the target month — no id, reset status/timestamps
        final budgetData = {
          'month': targetMonth,
          if (sourceBudget.title != null) 'title': sourceBudget.title,
          'budget_type': sourceBudget.budgetType.name,
          'period_type': sourceBudget.periodType.name,
          'status': 'active',
          if (sourceBudget.notes != null) 'notes': sourceBudget.notes,
          if (sourceBudget.customTargetAmount != null)
            'custom_target_amount': sourceBudget.customTargetAmount,
          'user_id': supabaseService.userId!,
          if (sourceBudget.accountId != null)
            'account_id': sourceBudget.accountId,
        };

        final budgetResponse = await supabaseService.client
            .from('budgets')
            .insert(budgetData)
            .select()
            .single();

        final newBudget =
            BudgetModel.fromJson(Map<String, dynamic>.from(budgetResponse));

        // Clone each category, resetting id and linking to the new budget
        final clonedCategories = <BudgetCategoryModel>[];

        if (sourceBudget.categories.isNotEmpty && newBudget.id != null) {
          final createdCategories = await Future.wait(
            sourceBudget.categories.map((cat) {
              final cloned = BudgetCategoryModel(
                budgetId: newBudget.id!,
                financeCategoryId: cat.financeCategoryId,
                targetAmount: cat.targetAmount,
                userId: supabaseService.userId,
              );
              return categoryDataSource.createCategory(cloned);
            }),
          );
          clonedCategories.addAll(createdCategories);
        }

        clonedBudgets.add(newBudget.withCategories(clonedCategories));
      }

      return targetPlan.withBudgets(clonedBudgets);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to copy month plan from $sourceMonth to $targetMonth',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
