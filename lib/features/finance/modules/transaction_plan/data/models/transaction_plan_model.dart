import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import '../../domain/entities/transaction_plan.dart';

class TransactionPlanModel extends TransactionPlan {
  TransactionPlanModel({
    super.id,
    required super.userId,
    required super.description,
    required super.amount,
    required super.type,
    required super.plannedDate,
    super.status,
    super.financeCategoryId,
    super.budgetId,
    super.notes,
    super.completedTransactionId,
    super.completedAt,
    super.createdAt,
  });

  factory TransactionPlanModel.fromJson(Map<String, dynamic> json) {
    return TransactionPlanModel(
      id: json['id'] as String?,
      userId: json['userId'] as String? ?? '',
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      plannedDate: DateTime.parse(json['plannedDate'] as String),
      status: TransactionPlanStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionPlanStatus.pending,
      ),
      financeCategoryId: json['financeCategoryId'] as String?,
      budgetId: json['budgetId'] as String?,
      notes: json['notes'] as String?,
      completedTransactionId: json['completedTransactionId'] as String?,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'description': description,
      'amount': amount,
      'type': type.name,
      'plannedDate': plannedDate.toIso8601String(),
      if (financeCategoryId != null) 'financeCategoryId': financeCategoryId,
      if (budgetId != null) 'budgetId': budgetId,
      if (notes != null) 'notes': notes,
    };
  }

  factory TransactionPlanModel.fromEntity(TransactionPlan plan) {
    return TransactionPlanModel(
      id: plan.id,
      userId: plan.userId,
      description: plan.description,
      amount: plan.amount,
      type: plan.type,
      plannedDate: plan.plannedDate,
      status: plan.status,
      financeCategoryId: plan.financeCategoryId,
      budgetId: plan.budgetId,
      notes: plan.notes,
      completedTransactionId: plan.completedTransactionId,
      completedAt: plan.completedAt,
      createdAt: plan.createdAt,
    );
  }
}
