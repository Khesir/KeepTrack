import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/repositories/finance_repository.dart';

import '../../domain/entities/finance_category.dart';
import '../../domain/entities/finance_category_enums.dart';
import '../datasources/finance_category_datasource.dart';
import '../models/finance_category_model.dart';

class FinanceCategoryRepositoryImpl implements FinanceCategoryRepository {
  final FinanceCategoryDataSource dataSource;

  FinanceCategoryRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<FinanceCategory>>> getCategories() async {
    final models = await dataSource.fetchCategories();
    return Result.success(models.map((e) => e.toEntity()).toList());
  }

  @override
  Future<Result<List<FinanceCategory>>> getCategoriesByType(
    CategoryType type,
  ) async {
    final models = await dataSource.fetchCategoriesByType(type.name);
    return Result.success(models.map((e) => e.toEntity()).toList());
  }

  @override
  Future<Result<FinanceCategory>> getCategoryById(String id) async {
    final model = await dataSource.fetchCategoryById(id);
    if (model == null) {
      return Result.error(NotFoundFailure(message: 'Category not found: $id'));
    }
    return Result.success(model.toEntity());
  }

  @override
  Future<Result<FinanceCategory>> createCategory(
    FinanceCategory category,
  ) async {
    final model = FinanceCategoryModel.fromEntity(category);
    final created = await dataSource.createCategory(model);
    return Result.success(created.toEntity());
  }

  @override
  Future<Result<FinanceCategory>> updateCategory(
    FinanceCategory category,
  ) async {
    final model = FinanceCategoryModel.fromEntity(category);
    final updated = await dataSource.updateCategory(model);
    return Result.success(updated.toEntity());
  }

  @override
  Future<Result<void>> deleteCategory(String id) async {
    await dataSource.deleteCategory(id);
    return Result.success(null);
  }

  @override
  Future<Result<List<FinanceCategory>>> getByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return Result.success([]);
    }
    final models = await dataSource.getByIds(ids);

    final entities = models.map((m) => m.toEntity()).toList();

    return Result.success(entities);
  }
}
