import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import 'package:persona_codex/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:persona_codex/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:persona_codex/features/finance/modules/finance_category/domain/repositories/finance_repository.dart';

/// Service to initialize default finance data for new users
class FinanceInitializationService {
  final FinanceCategoryRepository _categoryRepository;

  FinanceInitializationService(this._categoryRepository);

  /// Initialize default finance categories for a new user
  /// Returns true if initialization was successful, false if user already has categories
  Future<Result<bool>> initializeDefaultCategories(String userId) async {
    try {
      AppLogger.info('Initializing default finance categories for user: $userId');

      // Check if user already has categories
      final existingResult = await _categoryRepository.getCategories();
      if (existingResult.isSuccess) {
        final existing = existingResult.dataOrNull ?? [];
        if (existing.isNotEmpty) {
          AppLogger.info(
            'User already has ${existing.length} categories, skipping initialization',
          );
          return Result.success(false);
        }
      }

      // Define default categories
      final defaultCategories = _getDefaultCategories(userId);

      // Create all categories
      int successCount = 0;
      for (final category in defaultCategories) {
        final result = await _categoryRepository.createCategory(category);
        if (result.isSuccess) {
          successCount++;
          AppLogger.info('Created category: ${category.name} (${category.type.displayName})');
        } else {
          AppLogger.warning(
            'Failed to create category: ${category.name}',
            result.failureOrNull,
          );
        }
      }

      AppLogger.info(
        'Default categories initialized: $successCount/${defaultCategories.length} created',
      );
      return Result.success(true);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize default categories', e, stackTrace);
      return Result.error(
        UnknownFailure(
          message: 'Failed to initialize default categories',
          stackTrace: stackTrace,
          originalError: e,
        ),
      );
    }
  }

  /// Get list of default categories
  List<FinanceCategory> _getDefaultCategories(String userId) {
    return [
      // Income categories
      FinanceCategory(
        name: 'Salary',
        type: CategoryType.income,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Freelance',
        type: CategoryType.income,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Business Income',
        type: CategoryType.income,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Other Income',
        type: CategoryType.income,
        userId: userId,
      ),

      // Expense categories
      FinanceCategory(
        name: 'Food & Dining',
        type: CategoryType.expense,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Transportation',
        type: CategoryType.expense,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Shopping',
        type: CategoryType.expense,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Entertainment',
        type: CategoryType.expense,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Bills & Utilities',
        type: CategoryType.expense,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Healthcare',
        type: CategoryType.expense,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Education',
        type: CategoryType.expense,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Personal Care',
        type: CategoryType.expense,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Other Expenses',
        type: CategoryType.expense,
        userId: userId,
      ),

      // Investment categories
      FinanceCategory(
        name: 'Stocks',
        type: CategoryType.investment,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Crypto',
        type: CategoryType.investment,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Real Estate',
        type: CategoryType.investment,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Mutual Funds',
        type: CategoryType.investment,
        userId: userId,
      ),

      // Savings categories
      FinanceCategory(
        name: 'Emergency Fund',
        type: CategoryType.savings,
        userId: userId,
      ),
      FinanceCategory(
        name: 'Vacation Fund',
        type: CategoryType.savings,
        userId: userId,
      ),
      FinanceCategory(
        name: 'General Savings',
        type: CategoryType.savings,
        userId: userId,
      ),

      // Transfer category
      FinanceCategory(
        name: 'Account Transfer',
        type: CategoryType.transfer,
        userId: userId,
      ),
    ];
  }
}
