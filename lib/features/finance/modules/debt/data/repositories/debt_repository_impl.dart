import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/features/finance/modules/debt/data/datasources/debt_datasource.dart';
import 'package:keep_track/features/finance/modules/debt/data/models/debt_model.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/debt/domain/repositories/debt_repository.dart';

/// Debt repository implementation
class DebtRepositoryImpl implements DebtRepository {
  final DebtDataSource dataSource;

  DebtRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Debt>>> getDebts() async {
    final models = await dataSource.fetchDebts();
    final debts = models;
    return Result.success(debts);
  }

  @override
  Future<Result<Debt>> getDebtById(String id) async {
    final model = await dataSource.fetchDebtById(id);
    if (model == null) {
      return Result.error(NotFoundFailure(message: 'Debt not found: $id'));
    }
    return Result.success(model);
  }

  @override
  Future<Result<Debt>> createDebt(Debt debt) async {
    final model = DebtModel.fromEntity(debt);
    final created = await dataSource.createDebt(model);
    return Result.success(created);
  }

  @override
  Future<Result<Debt>> updateDebt(Debt debt) async {
    final model = DebtModel.fromEntity(debt);
    final updated = await dataSource.updateDebt(model);
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteDebt(String id) async {
    await dataSource.deleteDebt(id);
    return Result.success(null);
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
        UnknownFailure(
          message: 'Failed to fetch debts by type',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<Debt>>> getDebtsByStatus(DebtStatus status) async {
    final statusString = status.name;
    final models = await dataSource.fetchDebtsByStatus(statusString);
    final debts = models;
    return Result.success(debts);
  }

  @override
  Future<Result<Debt>> updateDebtPayment(
    String id,
    double newRemainingAmount,
  ) async {
    final result = await getDebtById(id);
    if (result.isError) {
      return result;
    }

    final debt = result.data;
    final updated = debt.copyWith(
      remainingAmount: newRemainingAmount,
      updatedAt: DateTime.now(),
      // If fully paid, mark as settled
      status: newRemainingAmount <= 0 ? DebtStatus.settled : debt.status,
      settledAt: newRemainingAmount <= 0 ? DateTime.now() : debt.settledAt,
    );

    return updateDebt(updated);
  }

  @override
  Future<Result<Debt>> settleDebt(String id) async {
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
  }
}
