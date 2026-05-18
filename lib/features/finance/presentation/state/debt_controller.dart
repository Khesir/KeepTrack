import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/core/services/notification/notification_scheduler.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/debt/domain/entities/debt.dart';
import '../../modules/debt/domain/repositories/debt_repository.dart';

/// Controller for managing debt list state
class DebtController extends StreamState<AsyncState<List<Debt>>> {
  final DebtRepository _debtRepository;

  DebtController(this._debtRepository) : super(const AsyncLoading()) {
    loadDebts();
  }

  /// Load all debts, optionally scoped to a budget profile
  Future<void> loadDebts({String? budgetProfileId}) async {
    await execute(() async {
      final debts = await _debtRepository.getDebts(budgetProfileId: budgetProfileId).then((r) => r.unwrap());
      // Schedule notifications for debts with due dates
      _scheduleDebtNotifications(debts);
      return debts;
    });
  }

  /// Schedule notifications for all active debts with due dates
  Future<void> _scheduleDebtNotifications(List<Debt> debts) async {
    if (!PlatformNotificationHelper.instance.isSupportedPlatform) return;

    try {
      final scheduler = locator.get<NotificationScheduler>();
      final activeDebts = debts.where((d) =>
          d.status == DebtStatus.active &&
          d.dueDate != null &&
          d.dueDate!.isAfter(DateTime.now()));

      for (final debt in activeDebts) {
        if (debt.id == null || debt.dueDate == null) continue;

        await scheduler.scheduleDebtDueNotifications(
          debtId: debt.id!,
          personName: debt.personName,
          amount: debt.remainingAmount,
          dueDate: debt.dueDate!,
        );
      }
    } catch (e) {
      AppLogger.warning('DebtController: Failed to schedule notifications: $e');
    }
  }

  /// Create a new debt with category and automatically create associated transaction
  Future<void> createDebtWithCategory(Debt debt, String? categoryId) async {
    await execute(() async {
      // Create debt — the NestJS backend handles any linked transaction logic
      // via the financeCategoryId field if provided
      final debtWithCategory = categoryId != null
          ? debt
          : debt;
      await _debtRepository.createDebt(debtWithCategory).then((r) => r.unwrap());
      await loadDebts();
      final current = data ?? [];
      return current;
    });
  }

  /// Create a debt record only, without an initial transaction.
  /// Use when no wallet is involved (pre-existing or informal debt).
  Future<void> createDebtOnly(Debt debt) async {
    await execute(() async {
      await _debtRepository.createDebt(debt).then((r) => r.unwrap());
      await loadDebts();
      final current = data ?? [];
      return current;
    });
  }

  /// Create a new debt and automatically create associated transaction
  /// Uses RPC function for atomic operation
  /// Deprecated: Use createDebtWithCategory instead
  @Deprecated('Use createDebtWithCategory to provide a category')
  Future<void> createDebt(Debt debt) async {
    await createDebtWithCategory(debt, null);
  }

  /// Update an existing debt
  Future<void> updateDebt(Debt debt) async {
    await execute(() async {
      await _debtRepository.updateDebt(debt).then((r) => r.unwrap());
      loadDebts();
      final current = data ?? [];
      return current;
    });
  }

  /// Delete a debt
  Future<void> deleteDebt(String id) async {
    await execute(() async {
      await _debtRepository.deleteDebt(id).then((r) => r.unwrap());
      loadDebts();
      final current = data ?? [];
      return current;
    });
  }

  /// Update debt payment (record partial payment)
  Future<void> updateDebtPayment(String id, double newRemainingAmount) async {
    await execute(() async {
      await _debtRepository
          .updateDebtPayment(id, newRemainingAmount)
          .then((r) => r.unwrap());
      loadDebts();

      final current = data ?? [];
      return current;
    });
  }

  /// Mark debt as settled (fully paid)
  Future<void> settleDebt(String id) async {
    await execute(() async {
      await _debtRepository.settleDebt(id).then((r) => r.unwrap());
      loadDebts();

      final current = data ?? [];
      return current;
    });
  }

  /// Load debts by type
  Future<void> loadDebtsByType(DebtType type) async {
    await execute(() async {
      return await _debtRepository.getDebtsByType(type).then((r) => r.unwrap());
    });
  }

  /// Load debts by status
  Future<void> loadDebtsByStatus(DebtStatus status) async {
    await execute(() async {
      return await _debtRepository
          .getDebtsByStatus(status)
          .then((r) => r.unwrap());
    });
  }

  /// Record a payment against a debt. Returns the updated debt.
  Future<Debt> payDebt(
    String id, {
    required double amount,
    double? fee,
  }) async {
    final updated = await _debtRepository
        .payDebt(id, amount: amount, fee: fee)
        .then((r) => r.unwrap());
    await executeSilent(() async {
      final current = data ?? [];
      return current.map((d) => d.id == id ? updated : d).toList();
    });
    return updated;
  }
}
