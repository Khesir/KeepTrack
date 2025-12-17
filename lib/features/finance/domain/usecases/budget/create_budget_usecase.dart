/// Create budget use case
library;

import 'package:persona_codex/core/error/failure.dart';

import '../../entities/budget.dart';
import '../../entities/budget_category.dart';
import '../../repositories/budget_repository.dart';

/// Use case for creating a new budget
class CreateBudgetUseCase {
  final BudgetRepository _repository;

  CreateBudgetUseCase(this._repository);

  /// Create a new budget with validation
  Future<Budget> call(CreateBudgetParams params) async {
    // Validation
    _validateParams(params);

    // Business rule: Check if budget for this month already exists
    final existing = await _repository.getBudgetByMonth(params.month);
    if (existing != null) {
      throw ValidationFailure('Budget for ${params.month} already exists');
    }

    // Create budget entity
    final budget = Budget(
      month: params.month,
      notes: params.notes,
      categories: params.categories ?? [],
    );

    return await _repository.createBudget(budget);
  }

  void _validateParams(CreateBudgetParams params) {
    // Month validation (should be in YYYY-MM format)
    final monthRegex = RegExp(r'^\d{4}-\d{2}$');
    if (!monthRegex.hasMatch(params.month)) {
      throw ValidationFailure('Invalid month format. Use YYYY-MM');
    }
  }
}

/// Parameters for creating a budget
class CreateBudgetParams {
  final String month; // YYYY-MM format
  final String? notes;
  final List<BudgetCategory>? categories;

  CreateBudgetParams({required this.month, this.notes, this.categories});
}
