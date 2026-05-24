import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';

class TransactionPlan {
  final String? id;
  final String userId;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime plannedDate;
  final TransactionPlanStatus status;
  final String? financeCategoryId;
  final String? budgetId;
  final String? budgetProfileId;
  final String? notes;
  final String? completedTransactionId;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const TransactionPlan({
    this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.type,
    required this.plannedDate,
    this.status = TransactionPlanStatus.pending,
    this.financeCategoryId,
    this.budgetId,
    this.budgetProfileId,
    this.notes,
    this.completedTransactionId,
    this.completedAt,
    this.createdAt,
  });

  bool get isPending => status == TransactionPlanStatus.pending;
  bool get isOverdue => isPending && plannedDate.isBefore(DateTime.now());
  bool get isDueToday {
    final now = DateTime.now();
    return isPending &&
        plannedDate.year == now.year &&
        plannedDate.month == now.month &&
        plannedDate.day == now.day;
  }

  TransactionPlan copyWith({
    String? description,
    double? amount,
    TransactionType? type,
    DateTime? plannedDate,
    TransactionPlanStatus? status,
    String? financeCategoryId,
    String? budgetId,
    String? budgetProfileId,
    String? notes,
  }) {
    return TransactionPlan(
      id: id,
      userId: userId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      plannedDate: plannedDate ?? this.plannedDate,
      status: status ?? this.status,
      financeCategoryId: financeCategoryId ?? this.financeCategoryId,
      budgetId: budgetId ?? this.budgetId,
      budgetProfileId: budgetProfileId ?? this.budgetProfileId,
      notes: notes ?? this.notes,
      completedTransactionId: completedTransactionId,
      completedAt: completedAt,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TransactionPlan && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum TransactionPlanStatus {
  pending,
  completed,
  cancelled;

  String get displayName => switch (this) {
        pending => 'Planned',
        completed => 'Completed',
        cancelled => 'Cancelled',
      };
}
