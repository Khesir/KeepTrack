import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';

import '../entities/payment_enums.dart';

/// Repository interface for managing planned/recurring payments
abstract class PlannedPaymentRepository {
  /// Get all planned payments for the current user
  Future<Result<List<PlannedPayment>>> getPlannedPayments();

  /// Get a specific planned payment by ID
  Future<Result<PlannedPayment>> getPlannedPaymentById(String id);

  /// Create a new planned payment
  Future<Result<PlannedPayment>> createPlannedPayment(PlannedPayment payment);

  /// Update an existing planned payment
  Future<Result<PlannedPayment>> updatePlannedPayment(PlannedPayment payment);

  /// Delete a planned payment
  Future<Result<void>> deletePlannedPayment(String id);

  /// Get planned payments filtered by status
  Future<Result<List<PlannedPayment>>> getPlannedPaymentsByStatus(
    PaymentStatus status,
  );

  /// Get planned payments filtered by category
  Future<Result<List<PlannedPayment>>> getPlannedPaymentsByCategory(
    PaymentCategory category,
  );

  /// Get upcoming payments (due within the next 7 days)
  Future<Result<List<PlannedPayment>>> getUpcomingPayments();

  /// Update the next payment date (after a payment is made)
  Future<Result<PlannedPayment>> recordPayment(String id);

  /// Skip a payment (move to next payment date without recording payment)
  /// For installments, this does NOT count as a paid installment
  Future<Result<PlannedPayment>> skipPayment(String id);
}
