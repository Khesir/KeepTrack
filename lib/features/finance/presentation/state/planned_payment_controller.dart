import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/core/services/notification/notification_scheduler.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/planned_payment/domain/entities/payment_enums.dart';
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
    await execute(() async {
      final result = await _repository.getPlannedPayments().then(
        (r) => r.unwrap(),
      );
      // Schedule notifications for upcoming payments
      _schedulePaymentNotifications(result);
      return result;
    });
  }

  /// Schedule notifications for all active planned payments
  Future<void> _schedulePaymentNotifications(List<PlannedPayment> payments) async {
    if (!PlatformNotificationHelper.instance.isSupportedPlatform) return;

    try {
      final scheduler = locator.get<NotificationScheduler>();
      final activePayments = payments.where((p) =>
          p.status == PaymentStatus.active &&
          p.nextPaymentDate.isAfter(DateTime.now()));

      for (final payment in activePayments) {
        if (payment.id == null) continue;

        await scheduler.schedulePaymentDueNotifications(
          paymentId: payment.id!,
          name: payment.name,
          amount: payment.amount,
          dueDate: payment.nextPaymentDate,
        );
      }
    } catch (e) {
      AppLogger.warning('PlannedPaymentController: Failed to schedule notifications: $e');
    }
  }

  /// Create a new planned payment
  Future<void> createPlannedPayment(PlannedPayment payment) async {
    await execute(() async {
      final created = await _repository
          .createPlannedPayment(payment)
          .then((r) => r.unwrap());

      final current = data ?? [];
      return [...current, created];
    });
  }

  /// Update an existing planned payment
  Future<void> updatePlannedPayment(PlannedPayment payment) async {
    await execute(() async {
      await _repository.updatePlannedPayment(payment).then((r) => r.unwrap());
      // Refresh the list on success
      loadPlannedPayments();
      final current = data ?? [];
      return current;
    });
  }

  /// Delete a planned payment
  Future<void> deletePlannedPayment(String id) async {
    await execute(() async {
      await _repository.deletePlannedPayment(id).then((r) => r.unwrap());

      loadPlannedPayments();
      final current = data ?? [];
      return current;
    });
  }

  /// Record a payment (updates last payment date and calculates next)
  Future<void> recordPayment(String id) async {
    await execute(() async {
      await _repository.recordPayment(id).then((r) => r.unwrap());

      loadPlannedPayments();
      final current = data ?? [];
      return current;
    });
  }

  /// Load planned payments by status
  Future<void> loadPlannedPaymentsByStatus(PaymentStatus status) async {
    await execute(() async {
      return await _repository
          .getPlannedPaymentsByStatus(status)
          .then((r) => r.unwrap());
    });
  }

  /// Load planned payments by category
  Future<void> loadPlannedPaymentsByCategory(PaymentCategory category) async {
    return await _repository
        .getPlannedPaymentsByCategory(category)
        .then((r) => r.unwrap());
  }

  /// Load upcoming payments (due within 7 days)
  Future<void> loadUpcomingPayments() async {
    return await _repository.getUpcomingPayments().then((r) => r.unwrap());
  }
}
