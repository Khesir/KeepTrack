import 'package:persona_codex/core/state/stream_state.dart';
import '../../modules/planned_payment/domain/entities/planned_payment.dart';
import '../../modules/planned_payment/domain/repositories/planned_payment_repository.dart';

/// Controller for managing planned payment list state
class PlannedPaymentController
    extends StreamState<AsyncState<List<PlannedPayment>>> {
  final PlannedPaymentRepository _repository;

  PlannedPaymentController(this._repository) : super(const AsyncLoading()) {
    loadPlannedPayments();
  }

  /// Load all planned payments
  Future<void> loadPlannedPayments() async {
    final result = await _repository.getPlannedPayments();
    result.fold(
      onSuccess: (payments) => emit(AsyncData(payments)),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Create a new planned payment
  Future<void> createPlannedPayment(PlannedPayment payment) async {
    await execute(() async {
      final created = await _repository.createPlannedPayment(payment);
      final current = data ?? [];
      return [...current, created];
    });
    // final result = await _repository.createPlannedPayment(payment);
    // result.fold(
    //   onSuccess: (_) => loadPlannedPayments(),
    //   onError: (failure) => emit(AsyncError(failure.message, failure)),
    // );
  }

  /// Update an existing planned payment
  Future<void> updatePlannedPayment(PlannedPayment payment) async {
    final result = await _repository.updatePlannedPayment(payment);
    result.fold(
      onSuccess: (_) => loadPlannedPayments(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Delete a planned payment
  Future<void> deletePlannedPayment(String id) async {
    final result = await _repository.deletePlannedPayment(id);
    result.fold(
      onSuccess: (_) => loadPlannedPayments(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Record a payment (updates last payment date and calculates next)
  Future<void> recordPayment(String id) async {
    final result = await _repository.recordPayment(id);
    result.fold(
      onSuccess: (_) => loadPlannedPayments(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Load planned payments by status
  Future<void> loadPlannedPaymentsByStatus(PaymentStatus status) async {
    final result = await _repository.getPlannedPaymentsByStatus(status);
    result.fold(
      onSuccess: (payments) => emit(AsyncData(payments)),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Load planned payments by category
  Future<void> loadPlannedPaymentsByCategory(PaymentCategory category) async {
    final result = await _repository.getPlannedPaymentsByCategory(category);
    result.fold(
      onSuccess: (payments) => emit(AsyncData(payments)),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Load upcoming payments (due within 7 days)
  Future<void> loadUpcomingPayments() async {
    final result = await _repository.getUpcomingPayments();
    result.fold(
      onSuccess: (payments) => emit(AsyncData(payments)),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }
}
