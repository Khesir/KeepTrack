import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/repositories/finance_repository.dart';

class FinanceInitializationService {
  final FinanceCategoryRepository _categoryRepository;

  FinanceInitializationService(this._categoryRepository);

  Future<Result<bool>> initializeDefaultCategories([String userId = '']) async {
    try {
      final existingResult = await _categoryRepository.getCategories();
      final existing = existingResult.dataOrNull ?? [];
      final existingNames = existing.map((c) => c.name.toLowerCase()).toSet();

      final missing = _defaultCategories(userId)
          .where((c) => !existingNames.contains(c.name.toLowerCase()))
          .toList();

      if (missing.isEmpty) return Result.success(false);

      int count = 0;
      for (final category in missing) {
        final result = await _categoryRepository.createCategory(category);
        if (result.isSuccess) count++;
      }

      AppLogger.info('Seeded $count default categories');
      return Result.success(true);
    } catch (e, st) {
      AppLogger.error('Failed to seed default categories', e, st);
      return Result.error(UnknownFailure(message: 'Failed to seed categories', stackTrace: st, originalError: e));
    }
  }

  List<FinanceCategory> _defaultCategories(String userId) => [
    FinanceCategory(name: 'Subscription', type: CategoryType.expense, userId: userId),
    FinanceCategory(name: 'Receivable', type: CategoryType.income, userId: userId),
    FinanceCategory(name: 'Debt', type: CategoryType.expense, userId: userId),
    FinanceCategory(name: 'Goals', type: CategoryType.savings, userId: userId),
    FinanceCategory(name: 'Loans', type: CategoryType.income, userId: userId),
    FinanceCategory(name: 'Borrowed', type: CategoryType.income, userId: userId),
    FinanceCategory(name: 'Loan Repayment', type: CategoryType.expense, userId: userId),
  ];
}
