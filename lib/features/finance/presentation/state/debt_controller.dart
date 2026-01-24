import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/core/services/notification/notification_scheduler.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../modules/debt/domain/entities/debt.dart';
import '../../modules/debt/domain/repositories/debt_repository.dart';

/// Controller for managing debt list state
class DebtController extends StreamState<AsyncState<List<Debt>>> {
  final DebtRepository _debtRepository;
  final SupabaseService _supabaseService;

  DebtController(this._debtRepository, this._supabaseService)
    : super(const AsyncLoading()) {
    loadDebts();
  }

  /// Load all debts
  Future<void> loadDebts() async {
    await execute(() async {
      final debts = await _debtRepository.getDebts().then((r) => r.unwrap());
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
  /// Uses RPC function for atomic operation
  Future<void> createDebtWithCategory(Debt debt, String? categoryId) async {
    await execute(() async {
      // Call RPC function to create debt with initial transaction atomically
      // Lending = money lent out = expense (reduces wallet)
      // Borrowing = money owed = income (increases wallet)
      await _supabaseService.client.rpc(
        'create_debt_with_initial_transaction',
        params: {
          'p_user_id': _supabaseService.userId,
          'p_account_id': debt.accountId,
          'p_finance_category_id': categoryId,
          'p_debt_type': debt.type.name,
          'p_person_name': debt.personName,
          'p_description': debt.description,
          'p_original_amount': debt.originalAmount,
          'p_start_date': debt.startDate.toIso8601String(),
          'p_due_date': debt.dueDate?.toIso8601String(),
          'p_status': debt.status.name,
          'p_notes': debt.notes,
        },
      );

      // Reload debts to get the newly created debt from the database
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
}
