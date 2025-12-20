import 'package:persona_codex/features/finance/data/models/debt_model.dart';

/// Data source interface for Debt operations
abstract class DebtDataSource {
  /// Fetch all debts for the current user
  Future<List<DebtModel>> fetchDebts();

  /// Fetch a specific debt by ID
  Future<DebtModel?> fetchDebtById(String id);

  /// Create a new debt
  Future<DebtModel> createDebt(DebtModel debt);

  /// Update an existing debt
  Future<DebtModel> updateDebt(DebtModel debt);

  /// Delete a debt
  Future<void> deleteDebt(String id);

  /// Fetch debts filtered by type (lending or borrowing)
  Future<List<DebtModel>> fetchDebtsByType(String type);

  /// Fetch debts filtered by status
  Future<List<DebtModel>> fetchDebtsByStatus(String status);
}
