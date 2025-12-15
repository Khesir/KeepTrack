/// Update budget use case
library;

import 'package:persona_codex/core/error/failure.dart';

import '../entities/budget.dart';
import '../repositories/budget_repository.dart';

/// Use case for updating budget details
class UpdateBudgetUseCase {
  final BudgetRepository _repository;

  UpdateBudgetUseCase(this._repository);

  /// Update budget
  Future<Budget> call(UpdateBudgetParams params) async {
    // Get existing budget
    final existing = await _repository.getBudgetById(params.budgetId);
    if (existing == null) {
      throw ValidationFailure('Budget not found');
    }

    // Create updated budget (only notes can be updated)
    final updated = existing.copyWith(
      notes: params.notes,
    );

    return await _repository.updateBudget(updated);
  }
}

/// Parameters for updating a budget
class UpdateBudgetParams {
  final String budgetId;
  final String? notes;

  UpdateBudgetParams({
    required this.budgetId,
    this.notes,
  });
}
