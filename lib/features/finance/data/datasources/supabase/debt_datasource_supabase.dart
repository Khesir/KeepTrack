import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/debt_model.dart';
import '../debt_datasource.dart';

/// Supabase implementation of DebtDataSource
class DebtDataSourceSupabase implements DebtDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'debts';

  DebtDataSourceSupabase(this.supabaseService);

  @override
  Future<List<DebtModel>> fetchDebts() async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((doc) => DebtModel.fromJson(doc)).toList();
  }

  @override
  Future<DebtModel?> fetchDebtById(String id) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? DebtModel.fromJson(response) : null;
  }

  @override
  Future<DebtModel> createDebt(DebtModel debt) async {
    final doc = debt.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .insert(doc)
        .select()
        .single();

    return DebtModel.fromJson(response);
  }

  @override
  Future<DebtModel> updateDebt(DebtModel debt) async {
    if (debt.id == null) {
      throw Exception('Cannot update debt without an ID');
    }

    final doc = debt.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .update(doc)
        .eq('id', debt.id!)
        .select()
        .single();

    return DebtModel.fromJson(response);
  }

  @override
  Future<void> deleteDebt(String id) async {
    await supabaseService.client.from(tableName).delete().eq('id', id);
  }

  @override
  Future<List<DebtModel>> fetchDebtsByType(String type) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('type', type)
        .order('created_at', ascending: false);

    return (response as List).map((doc) => DebtModel.fromJson(doc)).toList();
  }

  @override
  Future<List<DebtModel>> fetchDebtsByStatus(String status) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('status', status)
        .order('created_at', ascending: false);

    return (response as List).map((doc) => DebtModel.fromJson(doc)).toList();
  }
}
