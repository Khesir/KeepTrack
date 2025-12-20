import 'package:persona_codex/core/state/stream_state.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';

/// Controller for managing debt list state
class DebtController extends StreamState<AsyncState<List<Debt>>> {
  final DebtRepository _repository;

  DebtController(this._repository) : super(const AsyncLoading()) {
    loadDebts();
  }

  /// Load all debts
  Future<void> loadDebts() async {
    final result = await _repository.getDebts();
    result.fold(
      onSuccess: (debts) => emit(AsyncData(debts)),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Create a new debt
  Future<void> createDebt(Debt debt) async {
    final result = await _repository.createDebt(debt);
    result.fold(
      onSuccess: (_) => loadDebts(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Update an existing debt
  Future<void> updateDebt(Debt debt) async {
    final result = await _repository.updateDebt(debt);
    result.fold(
      onSuccess: (_) => loadDebts(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Delete a debt
  Future<void> deleteDebt(String id) async {
    final result = await _repository.deleteDebt(id);
    result.fold(
      onSuccess: (_) => loadDebts(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Update debt payment (record partial payment)
  Future<void> updateDebtPayment(String id, double newRemainingAmount) async {
    final result = await _repository.updateDebtPayment(id, newRemainingAmount);
    result.fold(
      onSuccess: (_) => loadDebts(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Mark debt as settled (fully paid)
  Future<void> settleDebt(String id) async {
    final result = await _repository.settleDebt(id);
    result.fold(
      onSuccess: (_) => loadDebts(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Load debts by type
  Future<void> loadDebtsByType(DebtType type) async {
    final result = await _repository.getDebtsByType(type);
    result.fold(
      onSuccess: (debts) => emit(AsyncData(debts)),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Load debts by status
  Future<void> loadDebtsByStatus(DebtStatus status) async {
    final result = await _repository.getDebtsByStatus(status);
    result.fold(
      onSuccess: (debts) => emit(AsyncData(debts)),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }
}
