import 'package:keep_track/features/finance/modules/debt/data/models/debt_model.dart';

/// Data source interface for Debt operations
abstract class DebtDataSource {
  /// Fetch all debts for the current user, optionally scoped to a budget profile
  Future<List<DebtModel>> fetchDebts({String? budgetProfileId});

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

  /// Record a payment against a debt. Returns the updated debt.
  Future<DebtModel> payDebt(
    String id, {
    required double amount,
    double? fee,
  });
}
