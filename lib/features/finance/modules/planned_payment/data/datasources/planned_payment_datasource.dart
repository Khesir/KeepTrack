import 'package:keep_track/features/finance/modules/planned_payment/data/models/planned_payment_model.dart';

/// Data source interface for PlannedPayment operations
abstract class PlannedPaymentDataSource {
  /// Fetch all planned payments for the current user
  Future<List<PlannedPaymentModel>> fetchPlannedPayments();

  /// Fetch a specific planned payment by ID
  Future<PlannedPaymentModel?> fetchPlannedPaymentById(String id);

  /// Create a new planned payment
  Future<PlannedPaymentModel> createPlannedPayment(
    PlannedPaymentModel payment,
  );

  /// Update an existing planned payment
  Future<PlannedPaymentModel> updatePlannedPayment(
    PlannedPaymentModel payment,
  );

  /// Delete a planned payment
  Future<void> deletePlannedPayment(String id);

  /// Fetch planned payments filtered by status
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByStatus(String status);

  /// Fetch planned payments filtered by category
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByCategory(
    String category,
  );

  /// Fetch upcoming payments (due within the next 7 days)
  Future<List<PlannedPaymentModel>> fetchUpcomingPayments();
}
