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
      if (existingResult.isSuccess) {
        final existing = existingResult.dataOrNull ?? [];
        if (existing.isNotEmpty) return Result.success(false);
      }

      final categories = _defaultCategories(userId);
      int count = 0;
      for (final category in categories) {
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
  ];
}
