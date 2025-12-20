import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/features/finance/data/datasources/debt_datasource.dart';
import 'package:persona_codex/features/finance/data/models/debt_model.dart';
import 'package:persona_codex/features/finance/domain/entities/debt.dart';
import 'package:persona_codex/features/finance/domain/repositories/debt_repository.dart';

/// Debt repository implementation
class DebtRepositoryImpl implements DebtRepository {
  final DebtDataSource dataSource;

  DebtRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Debt>>> getDebts() async {
    try {
      final models = await dataSource.fetchDebts();
      final debts = models;
      return Result.success(debts);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch debts', originalError: e),
      );
    }
  }

  @override
  Future<Result<Debt>> getDebtById(String id) async {
    try {
      final model = await dataSource.fetchDebtById(id);
      if (model == null) {
        return Result.error(
          NotFoundFailure(message: 'Debt not found: $id'),
        );
      }
      return Result.success(model);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch debt', originalError: e),
      );
    }
  }

  @override
  Future<Result<Debt>> createDebt(Debt debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      final created = await dataSource.createDebt(model);
      return Result.success(created);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to create debt', originalError: e),
      );
    }
  }

  @override
  Future<Result<Debt>> updateDebt(Debt debt) async {
    try {
      final model = DebtModel.fromEntity(debt);
      final updated = await dataSource.updateDebt(model);
      return Result.success(updated);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to update debt', originalError: e),
      );
    }
  }

  @override
  Future<Result<void>> deleteDebt(String id) async {
    try {
      await dataSource.deleteDebt(id);
      return Result.success(null);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to delete debt', originalError: e),
      );
    }
  }

  @override
  Future<Result<List<Debt>>> getDebtsByType(DebtType type) async {
    try {
      final typeString = type.name;
      final models = await dataSource.fetchDebtsByType(typeString);
      final debts = models;
      return Result.success(debts);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch debts by type', originalError: e),
      );
    }
  }

  @override
  Future<Result<List<Debt>>> getDebtsByStatus(DebtStatus status) async {
    try {
      final statusString = status.name;
      final models = await dataSource.fetchDebtsByStatus(statusString);
      final debts = models;
      return Result.success(debts);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch debts by status', originalError: e),
      );
    }
  }

  @override
  Future<Result<Debt>> updateDebtPayment(
    String id,
    double newRemainingAmount,
  ) async {
    try {
      final result = await getDebtById(id);
      if (result.isError) {
        return result;
      }

      final debt = result.data!;
      final updated = debt.copyWith(
        remainingAmount: newRemainingAmount,
        updatedAt: DateTime.now(),
        // If fully paid, mark as settled
        status: newRemainingAmount <= 0 ? DebtStatus.settled : debt.status,
        settledAt:
            newRemainingAmount <= 0 ? DateTime.now() : debt.settledAt,
      );

      return updateDebt(updated);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to update debt payment', originalError: e),
      );
    }
  }

  @override
  Future<Result<Debt>> settleDebt(String id) async {
    try {
      final result = await getDebtById(id);
      if (result.isError) {
        return result;
      }

      final debt = result.data!;
      final updated = debt.copyWith(
        remainingAmount: 0,
        status: DebtStatus.settled,
        settledAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return updateDebt(updated);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to settle debt', originalError: e),
      );
    }
  }
}
