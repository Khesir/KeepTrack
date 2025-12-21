import '../../domain/entities/budget.dart';
import 'budget_category_model.dart';

/// Budget model - DTO for Supabase
///
/// Note: Records/transactions are now in a separate transactions table.
/// Use TransactionRepository to manage transactions for a budget.
class BudgetModel {
  final String? id; // Optional - Supabase auto-generates
  final String month;
  final List<BudgetCategoryModel> categories;
  final String status;
  final String? notes;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final DateTime? closedAt;

  BudgetModel({
    this.id,
    required this.month,
    this.categories = const [],
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
  });

  factory BudgetModel.fromEntity(Budget budget) {
    return BudgetModel(
      id: budget.id,
      month: budget.month,
      categories: budget.categories
          .map((cat) => BudgetCategoryModel.fromEntity(cat))
          .toList(),
      status: budget.status.name,
      notes: budget.notes,
      createdAt: budget.createdAt,
      updatedAt: budget.updatedAt,
      closedAt: budget.closedAt,
    );
  }

  Budget toEntity() {
    return Budget(
      id: id,
      month: month,
      categories: categories.map((cat) => cat.toEntity()).toList(),
      status: BudgetStatus.values.firstWhere((e) => e.name == status),
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      closedAt: closedAt,
    );
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String?,
      month: json['month'] as String,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((cat) => BudgetCategoryModel.fromJson(cat as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'month': month,
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
    };
  }
}
