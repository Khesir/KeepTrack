import '../../../finance_category/domain/entities/finance_category_enums.dart';
import '../../domain/entities/budget_category.dart';

/// Budget category model - DTO for database
class BudgetCategoryModel {
  final String id;
  final String name;
  final String type;
  final double targetAmount;

  BudgetCategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
  });

  factory BudgetCategoryModel.fromEntity(BudgetCategory category) {
    return BudgetCategoryModel(
      id: category.id,
      name: category.name,
      type: category.type.name,
      targetAmount: category.targetAmount,
    );
  }

  BudgetCategory toEntity() {
    return BudgetCategory(
      id: id,
      name: name,
      type: CategoryType.values.firstWhere((e) => e.name == type),
      targetAmount: targetAmount,
    );
  }

  factory BudgetCategoryModel.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'type': type, 'targetAmount': targetAmount};
  }
}
