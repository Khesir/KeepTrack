import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import '../../modules/debt/domain/entities/debt.dart';
import '../../modules/debt/domain/repositories/debt_repository.dart';

/// Controller for managing debt list state
class DebtController extends StreamState<AsyncState<List<Debt>>> {
  final DebtRepository _repository;

  DebtController(this._repository) : super(const AsyncLoading()) {
    loadDebts();
  }

  /// Load all debts
  Future<void> loadDebts() async {
    await execute(() async {
      return await _repository.getDebts().then((r) => r.unwrap());
    });
  }

  /// Create a new debt
  Future<void> createDebt(Debt debt) async {
    await execute(() async {
      final created = await _repository
          .createDebt(debt)
          .then((r) => r.unwrap());
      final current = data ?? [];

      return [...current, created];
    });
  }

  /// Update an existing debt
  Future<void> updateDebt(Debt debt) async {
    await execute(() async {
      await _repository.updateDebt(debt).then((r) => r.unwrap());
      loadDebts();
      final current = data ?? [];
      return current;
    });
  }

  /// Delete a debt
  Future<void> deleteDebt(String id) async {
    await execute(() async {
      await _repository.deleteDebt(id).then((r) => r.unwrap());
      loadDebts();
      final current = data ?? [];
      return current;
    });
  }

  /// Update debt payment (record partial payment)
  Future<void> updateDebtPayment(String id, double newRemainingAmount) async {
    await execute(() async {
      await _repository
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
      await _repository.settleDebt(id).then((r) => r.unwrap());
      loadDebts();

      final current = data ?? [];
      return current;
    });
  }

  /// Load debts by type
  Future<void> loadDebtsByType(DebtType type) async {
    await execute(() async {
      return await _repository.getDebtsByType(type).then((r) => r.unwrap());
    });
  }

  /// Load debts by status
  Future<void> loadDebtsByStatus(DebtStatus status) async {
    await execute(() async {
      return await _repository.getDebtsByStatus(status).then((r) => r.unwrap());
    });
  }
}
