import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/features/finance/domain/entities/debt.dart';

/// Repository interface for managing debts (lending and borrowing)
abstract class DebtRepository {
  /// Get all debts for the current user
  Future<Result<List<Debt>>> getDebts();

  /// Get a specific debt by ID
  Future<Result<Debt>> getDebtById(String id);

  /// Create a new debt
  Future<Result<Debt>> createDebt(Debt debt);

  /// Update an existing debt
  Future<Result<Debt>> updateDebt(Debt debt);

  /// Delete a debt
  Future<Result<void>> deleteDebt(String id);

  /// Get debts filtered by type (lending or borrowing)
  Future<Result<List<Debt>>> getDebtsByType(DebtType type);

  /// Get debts filtered by status
  Future<Result<List<Debt>>> getDebtsByStatus(DebtStatus status);

  /// Update the remaining amount of a debt (for recording payments)
  Future<Result<Debt>> updateDebtPayment(String id, double newRemainingAmount);

  /// Mark a debt as settled
  Future<Result<Debt>> settleDebt(String id);
}
