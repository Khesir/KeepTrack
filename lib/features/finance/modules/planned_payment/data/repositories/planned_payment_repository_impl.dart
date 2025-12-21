import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/data/datasources/planned_payment_datasource.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/data/models/planned_payment_model.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:persona_codex/features/finance/modules/planned_payment/domain/repositories/planned_payment_repository.dart';

/// PlannedPayment repository implementation
class PlannedPaymentRepositoryImpl implements PlannedPaymentRepository {
  final PlannedPaymentDataSource dataSource;

  PlannedPaymentRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<PlannedPayment>>> getPlannedPayments() async {
    try {
      final models = await dataSource.fetchPlannedPayments();
      final payments = models;
      return Result.success(payments);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch planned payments', originalError: e),
      );
    }
  }

  @override
  Future<Result<PlannedPayment>> getPlannedPaymentById(String id) async {
    try {
      final model = await dataSource.fetchPlannedPaymentById(id);
      if (model == null) {
        return Result.error(
          NotFoundFailure(message: 'Planned payment not found: $id'),
        );
      }
      return Result.success(model);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch planned payment', originalError: e),
      );
    }
  }

  @override
  Future<Result<PlannedPayment>> createPlannedPayment(
    PlannedPayment payment,
  ) async {
    try {
      final model = PlannedPaymentModel.fromEntity(payment);
      final created = await dataSource.createPlannedPayment(model);
      return Result.success(created);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to create planned payment', originalError: e),
      );
    }
  }

  @override
  Future<Result<PlannedPayment>> updatePlannedPayment(
    PlannedPayment payment,
  ) async {
    try {
      final model = PlannedPaymentModel.fromEntity(payment);
      final updated = await dataSource.updatePlannedPayment(model);
      return Result.success(updated);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to update planned payment', originalError: e),
      );
    }
  }

  @override
  Future<Result<void>> deletePlannedPayment(String id) async {
    try {
      await dataSource.deletePlannedPayment(id);
      return Result.success(null);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to delete planned payment', originalError: e),
      );
    }
  }

  @override
  Future<Result<List<PlannedPayment>>> getPlannedPaymentsByStatus(
    PaymentStatus status,
  ) async {
    try {
      final statusString = status.name;
      final models = await dataSource.fetchPlannedPaymentsByStatus(statusString);
      final payments = models;
      return Result.success(payments);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch planned payments by status', originalError: e),
      );
    }
  }

  @override
  Future<Result<List<PlannedPayment>>> getPlannedPaymentsByCategory(
    PaymentCategory category,
  ) async {
    try {
      final categoryString = category.name;
      final models =
          await dataSource.fetchPlannedPaymentsByCategory(categoryString);
      final payments = models;
      return Result.success(payments);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch planned payments by category', originalError: e),
      );
    }
  }

  @override
  Future<Result<List<PlannedPayment>>> getUpcomingPayments() async {
    try {
      final models = await dataSource.fetchUpcomingPayments();
      final payments = models;
      return Result.success(payments);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch upcoming payments', originalError: e),
      );
    }
  }

  @override
  Future<Result<PlannedPayment>> recordPayment(String id) async {
    try {
      final result = await getPlannedPaymentById(id);
      if (result.isError) {
        return result;
      }

      final payment = result.data!;
      final updated = payment.copyWith(
        lastPaymentDate: DateTime.now(),
        nextPaymentDate: _calculateNextPaymentDate(
          payment.nextPaymentDate,
          payment.frequency,
        ),
        updatedAt: DateTime.now(),
      );

      return updatePlannedPayment(updated);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to record payment', originalError: e),
      );
    }
  }

  /// Calculate the next payment date based on frequency
  DateTime _calculateNextPaymentDate(
    DateTime currentDate,
    PaymentFrequency frequency,
  ) {
    return switch (frequency) {
      PaymentFrequency.daily => currentDate.add(const Duration(days: 1)),
      PaymentFrequency.weekly => currentDate.add(const Duration(days: 7)),
      PaymentFrequency.biweekly => currentDate.add(const Duration(days: 14)),
      PaymentFrequency.monthly => DateTime(
          currentDate.year,
          currentDate.month + 1,
          currentDate.day,
        ),
      PaymentFrequency.quarterly => DateTime(
          currentDate.year,
          currentDate.month + 3,
          currentDate.day,
        ),
      PaymentFrequency.yearly => DateTime(
          currentDate.year + 1,
          currentDate.month,
          currentDate.day,
        ),
    };
  }
}
