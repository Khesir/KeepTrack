import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/core/services/notification/notification_scheduler.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/payment_enums.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/planned_payment_controller.dart';

/// Helper class for scheduling finance-related notifications
/// Handles notifications for:
/// - Planned payments due dates
/// - Debt due dates
class FinanceNotificationHelper {
  final NotificationScheduler _scheduler;
  final PlannedPaymentController _paymentController;
  final DebtController _debtController;

  FinanceNotificationHelper({
    NotificationScheduler? scheduler,
    PlannedPaymentController? paymentController,
    DebtController? debtController,
  })  : _scheduler = scheduler ?? locator.get<NotificationScheduler>(),
        _paymentController = paymentController ?? locator.get<PlannedPaymentController>(),
        _debtController = debtController ?? locator.get<DebtController>();

  /// Schedule notifications for all active planned payments and debts
  /// Should be called on app startup and when payments/debts are updated
  Future<void> scheduleAllFinanceNotifications() async {
    AppLogger.info('FinanceNotificationHelper: Scheduling all finance notifications...');

    await _schedulePaymentNotifications();
    await _scheduleDebtNotifications();

    AppLogger.info('FinanceNotificationHelper: All finance notifications scheduled');
  }

  /// Schedule notifications for all active planned payments
  Future<void> _schedulePaymentNotifications() async {
    try {
      // Get current payments from controller state
      final payments = _paymentController.data;
      if (payments == null || payments.isEmpty) {
        AppLogger.info('FinanceNotificationHelper: No planned payments to schedule');
        return;
      }

      // Filter active payments with future due dates
      final activePayments = payments.where((p) =>
          p.status == PaymentStatus.active &&
          p.nextPaymentDate.isAfter(DateTime.now()));

      for (final payment in activePayments) {
        if (payment.id == null) continue;

        await _scheduler.schedulePaymentDueNotifications(
          paymentId: payment.id!,
          name: payment.name,
          amount: payment.amount,
          dueDate: payment.nextPaymentDate,
        );
      }

      AppLogger.info('FinanceNotificationHelper: Scheduled notifications for ${activePayments.length} payments');
    } catch (e, stackTrace) {
      AppLogger.error('FinanceNotificationHelper: Failed to schedule payment notifications', e, stackTrace);
    }
  }

  /// Schedule notifications for all active debts with due dates
  Future<void> _scheduleDebtNotifications() async {
    try {
      // Get current debts from controller state
      final debts = _debtController.data;
      if (debts == null || debts.isEmpty) {
        AppLogger.info('FinanceNotificationHelper: No debts to schedule');
        return;
      }

      // Filter active debts with future due dates
      final activeDebts = debts.where((d) =>
          d.status == DebtStatus.active &&
          d.dueDate != null &&
          d.dueDate!.isAfter(DateTime.now()));

      for (final debt in activeDebts) {
        if (debt.id == null || debt.dueDate == null) continue;

        await _scheduler.scheduleDebtDueNotifications(
          debtId: debt.id!,
          personName: debt.personName,
          amount: debt.remainingAmount,
          dueDate: debt.dueDate!,
        );
      }

      AppLogger.info('FinanceNotificationHelper: Scheduled notifications for ${activeDebts.length} debts');
    } catch (e, stackTrace) {
      AppLogger.error('FinanceNotificationHelper: Failed to schedule debt notifications', e, stackTrace);
    }
  }

  /// Schedule notifications for a single planned payment
  Future<void> schedulePaymentNotification(PlannedPayment payment) async {
    if (payment.id == null) return;
    if (payment.status != PaymentStatus.active) return;
    if (payment.nextPaymentDate.isBefore(DateTime.now())) return;

    await _scheduler.schedulePaymentDueNotifications(
      paymentId: payment.id!,
      name: payment.name,
      amount: payment.amount,
      dueDate: payment.nextPaymentDate,
    );
  }

  /// Cancel notifications for a single planned payment
  Future<void> cancelPaymentNotification(String paymentId) async {
    await _scheduler.cancelPaymentDueNotifications(paymentId);
  }

  /// Schedule notifications for a single debt
  Future<void> scheduleDebtNotification(Debt debt) async {
    if (debt.id == null || debt.dueDate == null) return;
    if (debt.status != DebtStatus.active) return;
    if (debt.dueDate!.isBefore(DateTime.now())) return;

    await _scheduler.scheduleDebtDueNotifications(
      debtId: debt.id!,
      personName: debt.personName,
      amount: debt.remainingAmount,
      dueDate: debt.dueDate!,
    );
  }

  /// Cancel notifications for a single debt
  Future<void> cancelDebtNotification(String debtId) async {
    await _scheduler.cancelDebtDueNotifications(debtId);
  }

  /// Reschedule all notifications (cancel existing and schedule new)
  Future<void> rescheduleAllNotifications() async {
    AppLogger.info('FinanceNotificationHelper: Rescheduling all finance notifications...');
    await scheduleAllFinanceNotifications();
  }
}
