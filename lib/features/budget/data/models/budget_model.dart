import '../../domain/entities/budget.dart';
import 'budget_category_model.dart';
import 'budget_record_model.dart';

/// Budget model - DTO for database
class BudgetModel {
  final String id;
  final String month;
  final List<BudgetCategoryModel> categories;
  final List<BudgetRecordModel> records;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  BudgetModel({
    required this.id,
    required this.month,
    required this.categories,
    this.records = const [],
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });

  factory BudgetModel.fromEntity(Budget budget) {
    return BudgetModel(
      id: budget.id,
      month: budget.month,
      categories: budget.categories
          .map((cat) => BudgetCategoryModel.fromEntity(cat))
          .toList(),
      records: budget.records
          .map((record) => BudgetRecordModel.fromEntity(record))
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
      records: records.map((record) => record.toEntity()).toList(),
      status: BudgetStatus.values.firstWhere((e) => e.name == status),
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      closedAt: closedAt,
    );
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['_id'] as String,
      month: json['month'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((cat) => BudgetCategoryModel.fromJson(cat as Map<String, dynamic>))
          .toList(),
      records: (json['records'] as List<dynamic>?)
              ?.map((record) => BudgetRecordModel.fromJson(record as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'month': month,
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'records': records.map((record) => record.toJson()).toList(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
    };
  }
}
