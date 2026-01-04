import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/debt_model.dart';
import '../debt_datasource.dart';

/// Supabase implementation of DebtDataSource
class DebtDataSourceSupabase implements DebtDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'debts';

  DebtDataSourceSupabase(this.supabaseService);

  @override
  Future<List<DebtModel>> fetchDebts() async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('user_id', supabaseService.userId!)
          .order('created_at', ascending: false);

      return (response as List).map((doc) => DebtModel.fromJson(doc)).toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch debts',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<DebtModel?> fetchDebtById(String id) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!)
          .maybeSingle();

      return response != null ? DebtModel.fromJson(response) : null;
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch debts',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<DebtModel> createDebt(DebtModel debt) async {
    try {
      final doc = debt.toJson();
      final response = await supabaseService.client
          .from(tableName)
          .insert(doc)
          .select()
          .single();

      return DebtModel.fromJson(response);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to create debt',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<DebtModel> updateDebt(DebtModel debt) async {
    try {
      if (debt.id == null) {
        throw Exception('Cannot update debt without an ID');
      }

      final doc = debt.toJson();
      final response = await supabaseService.client
          .from(tableName)
          .update(doc)
          .eq('id', debt.id!)
          .eq('user_id', supabaseService.userId!)
          .select()
          .single();

      return DebtModel.fromJson(response);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to update debt',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteDebt(String id) async {
    try {
      await supabaseService.client
          .from(tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to delete debt',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<DebtModel>> fetchDebtsByType(String type) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('type', type)
          .eq('user_id', supabaseService.userId!)
          .order('created_at', ascending: false);

      return (response as List).map((doc) => DebtModel.fromJson(doc)).toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch debts by type',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<DebtModel>> fetchDebtsByStatus(String status) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      return (response as List).map((doc) => DebtModel.fromJson(doc)).toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch debts by status',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
