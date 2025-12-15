import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/budget_model.dart';
import '../budget_datasource.dart';

/// Supabase implementation of BudgetDataSource
class BudgetDataSourceSupabase implements BudgetDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'budgets';

  BudgetDataSourceSupabase(this.supabaseService);

  @override
  Future<List<BudgetModel>> getBudgets() async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .order('month', ascending: false);

    return (response as List)
        .map((doc) => BudgetModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BudgetModel?> getBudgetById(String id) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? BudgetModel.fromJson(response as Map<String, dynamic>) : null;
  }

  @override
  Future<BudgetModel?> getBudgetByMonth(String month) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('month', month)
        .maybeSingle();

    return response != null ? BudgetModel.fromJson(response as Map<String, dynamic>) : null;
  }

  @override
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    final doc = budget.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .insert(doc)
        .select()
        .single();

    return BudgetModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    if (budget.id == null) {
      throw Exception('Cannot update budget without an ID');
    }

    final doc = budget.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .update(doc)
        .eq('id', budget.id!)
        .select()
        .single();

    return BudgetModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await supabaseService.client
        .from(tableName)
        .delete()
        .eq('id', id);
  }
}
