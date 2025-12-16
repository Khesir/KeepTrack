import '../../domain/entities/budget_record.dart';

/// Budget record model - DTO for database
class BudgetRecordModel {
  final String id;
  final String budgetId;
  final String categoryId;
  final double amount;
  final String? description;
  final DateTime date;
  final String type;

  BudgetRecordModel({
    required this.id,
    required this.budgetId,
    required this.categoryId,
    required this.amount,
    this.description,
    required this.date,
    required this.type,
  });

  factory BudgetRecordModel.fromEntity(BudgetRecord record) {
    return BudgetRecordModel(
      id: record.id,
      budgetId: record.budgetId,
      categoryId: record.categoryId,
      amount: record.amount,
      description: record.description,
      date: record.date,
      type: record.type.name,
    );
  }

  BudgetRecord toEntity() {
    return BudgetRecord(
      id: id,
      budgetId: budgetId,
      categoryId: categoryId,
      amount: amount,
      description: description,
      date: date,
      type: RecordType.values.firstWhere((e) => e.name == type),
    );
  }

  factory BudgetRecordModel.fromJson(Map<String, dynamic> json) {
    return BudgetRecordModel(
      id: json['id'] as String,
      budgetId: json['budgetId'] as String,
      categoryId: json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'budgetId': budgetId,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
    };
  }
}
