import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/planned_payment_model.dart';
import '../planned_payment_datasource.dart';

/// Supabase implementation of PlannedPaymentDataSource
class PlannedPaymentDataSourceSupabase implements PlannedPaymentDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'planned_payments';

  PlannedPaymentDataSourceSupabase(this.supabaseService);

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPayments() async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('user_id', supabaseService.userId!)
          .order('next_payment_date', ascending: true);

      return (response as List)
          .map((doc) => PlannedPaymentModel.fromJson(doc))
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to Fetch planned payments',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<PlannedPaymentModel?> fetchPlannedPaymentById(String id) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!)
          .maybeSingle();

      return response != null ? PlannedPaymentModel.fromJson(response) : null;
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to Fetch planned payment by ID',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<PlannedPaymentModel> createPlannedPayment(
    PlannedPaymentModel payment,
  ) async {
    try {
      final doc = {...payment.toJson()};
      final response = await supabaseService.client
          .from(tableName)
          .insert(doc)
          .select()
          .single();

      return PlannedPaymentModel.fromJson(response);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to create planned payment',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<PlannedPaymentModel> updatePlannedPayment(
    PlannedPaymentModel payment,
  ) async {
    try {
      if (payment.id == null) {
        throw Exception('Cannot update planned payment without an ID');
      }

      final doc = {...payment.toJson()};
      final response = await supabaseService.client
          .from(tableName)
          .update(doc)
          .eq('id', payment.id!)
          .eq('user_id', supabaseService.userId!)
          .select()
          .single();

      return PlannedPaymentModel.fromJson(response);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to Update Planned Payment',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deletePlannedPayment(String id) async {
    try {
      await supabaseService.client
          .from(tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to Delete Planned Payment',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByStatus(
    String status,
  ) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('user_id', supabaseService.userId!)
          .eq('status', status)
          .order('next_payment_date', ascending: true);

      return (response as List)
          .map((doc) => PlannedPaymentModel.fromJson(doc))
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to Fetch Planned Payment By Status',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByCategory(
    String category,
  ) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('user_id', supabaseService.userId!)
          .eq('category', category)
          .order('next_payment_date', ascending: true);

      return (response as List)
          .map((doc) => PlannedPaymentModel.fromJson(doc))
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to Fetch Planned Payment By Category',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<PlannedPaymentModel>> fetchUpcomingPayments() async {
    try {
      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));

      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('user_id', supabaseService.userId!)
          .eq('status', 'active')
          .gte('next_payment_date', now.toIso8601String())
          .lte('next_payment_date', sevenDaysLater.toIso8601String())
          .order('next_payment_date', ascending: true);

      return (response as List)
          .map((doc) => PlannedPaymentModel.fromJson(doc))
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to Fetch Planned Payment By Category',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
