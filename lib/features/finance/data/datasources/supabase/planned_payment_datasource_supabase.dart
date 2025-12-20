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
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .order('next_payment_date', ascending: true);

    return (response as List)
        .map((doc) => PlannedPaymentModel.fromJson(doc))
        .toList();
  }

  @override
  Future<PlannedPaymentModel?> fetchPlannedPaymentById(String id) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? PlannedPaymentModel.fromJson(response) : null;
  }

  @override
  Future<PlannedPaymentModel> createPlannedPayment(
    PlannedPaymentModel payment,
  ) async {
    final doc = payment.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .insert(doc)
        .select()
        .single();

    return PlannedPaymentModel.fromJson(response);
  }

  @override
  Future<PlannedPaymentModel> updatePlannedPayment(
    PlannedPaymentModel payment,
  ) async {
    if (payment.id == null) {
      throw Exception('Cannot update planned payment without an ID');
    }

    final doc = payment.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .update(doc)
        .eq('id', payment.id!)
        .select()
        .single();

    return PlannedPaymentModel.fromJson(response);
  }

  @override
  Future<void> deletePlannedPayment(String id) async {
    await supabaseService.client.from(tableName).delete().eq('id', id);
  }

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByStatus(
    String status,
  ) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('status', status)
        .order('next_payment_date', ascending: true);

    return (response as List)
        .map((doc) => PlannedPaymentModel.fromJson(doc))
        .toList();
  }

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByCategory(
    String category,
  ) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('category', category)
        .order('next_payment_date', ascending: true);

    return (response as List)
        .map((doc) => PlannedPaymentModel.fromJson(doc))
        .toList();
  }

  @override
  Future<List<PlannedPaymentModel>> fetchUpcomingPayments() async {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));

    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('status', 'active')
        .gte('next_payment_date', now.toIso8601String())
        .lte('next_payment_date', sevenDaysLater.toIso8601String())
        .order('next_payment_date', ascending: true);

    return (response as List)
        .map((doc) => PlannedPaymentModel.fromJson(doc))
        .toList();
  }
}
