import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/data/datasources/planned_payment_datasource.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/data/models/planned_payment_model.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/domain/repositories/planned_payment_repository.dart';

import '../../domain/entities/payment_enums.dart';

/// PlannedPayment repository implementation
class PlannedPaymentRepositoryImpl implements PlannedPaymentRepository {
  final PlannedPaymentDataSource dataSource;

  PlannedPaymentRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<PlannedPayment>>> getPlannedPayments() async {
    final models = await dataSource.fetchPlannedPayments();
    final payments = models;
    return Result.success(payments);
  }

  @override
  Future<Result<PlannedPayment>> getPlannedPaymentById(String id) async {
    final model = await dataSource.fetchPlannedPaymentById(id);
    if (model == null) {
      return Result.error(
        NotFoundFailure(message: 'Planned payment not found: $id'),
      );
    }
    return Result.success(model);
  }

  @override
  Future<Result<PlannedPayment>> createPlannedPayment(
    PlannedPayment payment,
  ) async {
    final model = PlannedPaymentModel.fromEntity(payment);
    final created = await dataSource.createPlannedPayment(model);
    return Result.success(created);
  }

  @override
  Future<Result<PlannedPayment>> updatePlannedPayment(
    PlannedPayment payment,
  ) async {
    final model = PlannedPaymentModel.fromEntity(payment);
    final updated = await dataSource.updatePlannedPayment(model);
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deletePlannedPayment(String id) async {
    await dataSource.deletePlannedPayment(id);
    return Result.success(null);
  }

  @override
  Future<Result<List<PlannedPayment>>> getPlannedPaymentsByStatus(
    PaymentStatus status,
  ) async {
    final statusString = status.name;
    final models = await dataSource.fetchPlannedPaymentsByStatus(statusString);
    final payments = models;
    return Result.success(payments);
  }

  @override
  Future<Result<List<PlannedPayment>>> getPlannedPaymentsByCategory(
    PaymentCategory category,
  ) async {
    final categoryString = category.name;
    final models = await dataSource.fetchPlannedPaymentsByCategory(
      categoryString,
    );
    final payments = models;
    return Result.success(payments);
  }

  @override
  Future<Result<List<PlannedPayment>>> getUpcomingPayments() async {
    final models = await dataSource.fetchUpcomingPayments();
    final payments = models;
    return Result.success(payments);
  }

  @override
  Future<Result<PlannedPayment>> recordPayment(String id) async {
    final result = await getPlannedPaymentById(id);
    if (result.isError) {
      return result;
    }

    final payment = result.data;

    // For one-time payments, close them after recording payment
    if (payment.frequency == PaymentFrequency.oneTime) {
      final updated = payment.copyWith(
        lastPaymentDate: DateTime.now(),
        status: PaymentStatus.closed,
        updatedAt: DateTime.now(),
      );
      return updatePlannedPayment(updated);
    }

    // For installment plans, decrement remaining installments
    if (payment.isInstallmentPlan) {
      final newRemaining = (payment.remainingInstallments ?? 0) - 1;
      final nextDate = _calculateNextPaymentDate(
        payment.nextPaymentDate,
        payment.frequency,
      );

      // Check if this was the last installment OR if end date is reached
      final shouldClose = newRemaining <= 0 ||
          (payment.endDate != null && nextDate.isAfter(payment.endDate!));

      if (shouldClose) {
        final updated = payment.copyWith(
          lastPaymentDate: DateTime.now(),
          remainingInstallments: newRemaining.clamp(0, payment.totalInstallments ?? 0),
          status: PaymentStatus.closed,
          updatedAt: DateTime.now(),
        );
        return updatePlannedPayment(updated);
      }

      // Otherwise, update remaining count and next payment date
      final updated = payment.copyWith(
        lastPaymentDate: DateTime.now(),
        remainingInstallments: newRemaining,
        nextPaymentDate: nextDate,
        updatedAt: DateTime.now(),
      );
      return updatePlannedPayment(updated);
    }

    // For regular recurring payments, calculate next payment date
    final nextDate = _calculateNextPaymentDate(
      payment.nextPaymentDate,
      payment.frequency,
    );

    // Check if next payment date would be after end date
    if (payment.endDate != null && nextDate.isAfter(payment.endDate!)) {
      // End date reached, close the payment
      final updated = payment.copyWith(
        lastPaymentDate: DateTime.now(),
        nextPaymentDate: nextDate,
        status: PaymentStatus.closed,
        updatedAt: DateTime.now(),
      );
      return updatePlannedPayment(updated);
    }

    // Otherwise, just update to next payment date
    final updated = payment.copyWith(
      lastPaymentDate: DateTime.now(),
      nextPaymentDate: nextDate,
      updatedAt: DateTime.now(),
    );

    return updatePlannedPayment(updated);
  }

  @override
  Future<Result<PlannedPayment>> skipPayment(String id) async {
    final result = await getPlannedPaymentById(id);
    if (result.isError) {
      return result;
    }

    final payment = result.data;

    // Cannot skip one-time payments
    if (payment.frequency == PaymentFrequency.oneTime) {
      return Result.error(
        ValidationFailure('Cannot skip one-time payments'),
      );
    }

    // For all payment types (installments and recurring), just move next payment date
    // For installments, remaining count stays the same (skipping doesn't count as payment)
    final updated = payment.copyWith(
      nextPaymentDate: _calculateNextPaymentDate(
        payment.nextPaymentDate,
        payment.frequency,
      ),
      updatedAt: DateTime.now(),
    );

    return updatePlannedPayment(updated);
  }

  /// Calculate the next payment date based on frequency
  DateTime _calculateNextPaymentDate(
    DateTime currentDate,
    PaymentFrequency frequency,
  ) {
    return switch (frequency) {
      PaymentFrequency.oneTime =>
        currentDate, // Won't be used, but return current
      PaymentFrequency.daily => currentDate.add(const Duration(days: 1)),
      PaymentFrequency.weekly => currentDate.add(const Duration(days: 7)),
      PaymentFrequency.biweekly => currentDate.add(const Duration(days: 14)),
      PaymentFrequency.monthly => _addMonths(currentDate, 1),
      PaymentFrequency.quarterly => _addMonths(currentDate, 3),
      PaymentFrequency.yearly => DateTime(
        currentDate.year + 1,
        currentDate.month,
        currentDate.day,
      ),
    };
  }

  /// Add months to a date, handling edge cases like month-end dates
  DateTime _addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;

    // Handle year rollover
    while (month > 12) {
      year++;
      month -= 12;
    }

    // Handle edge case: if day doesn't exist in target month (e.g., Jan 31 -> Feb 28)
    final daysInTargetMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > daysInTargetMonth ? daysInTargetMonth : date.day;

    return DateTime(year, month, day);
  }
}
