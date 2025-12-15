/// Delete budget use case
library;

import 'package:persona_codex/core/error/failure.dart';

import '../repositories/budget_repository.dart';

/// Use case for deleting a budget
class DeleteBudgetUseCase {
  final BudgetRepository _repository;

  DeleteBudgetUseCase(this._repository);

  /// Delete a budget by ID
  Future<void> call(String budgetId) async {
    // Verify budget exists
    final budget = await _repository.getBudgetById(budgetId);
    if (budget == null) {
      throw ValidationFailure('Budget not found');
    }

    // Business rule: Could add check for closed budgets
    // if (budget.isClosed) {
    //   throw ValidationFailure('Cannot delete a closed budget');
    // }

    await _repository.deleteBudget(budgetId);
  }
}
