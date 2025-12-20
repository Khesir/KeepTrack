/// Debt entity for tracking lending (money lent out) and borrowing (money owed)
class Debt {
  final String? id; // Optional - Supabase auto-generates
  final DebtType type;
  final String personName;
  final String description;
  final double originalAmount;
  final double remainingAmount;
  final DateTime startDate;
  final DateTime? dueDate;
  final DebtStatus status;
  final String? notes;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final DateTime? settledAt;

  Debt({
    this.id,
    required this.type,
    required this.personName,
    required this.description,
    required this.originalAmount,
    required this.remainingAmount,
    required this.startDate,
    this.dueDate,
    this.status = DebtStatus.active,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.settledAt,
  });

  /// Calculate repayment progress (0.0 to 1.0)
  double get progress => originalAmount > 0
      ? ((originalAmount - remainingAmount) / originalAmount).clamp(0.0, 1.0)
      : 0.0;

  /// Calculate amount paid/received so far
  double get paidAmount => originalAmount - remainingAmount;

  /// Check if debt is overdue
  bool get isOverdue {
    if (dueDate == null || status != DebtStatus.active) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Calculate days until due date (negative if overdue)
  int? get daysUntilDue => dueDate?.difference(DateTime.now()).inDays;

  Debt copyWith({
    String? id,
    DebtType? type,
    String? personName,
    String? description,
    double? originalAmount,
    double? remainingAmount,
    DateTime? startDate,
    DateTime? dueDate,
    DebtStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? settledAt,
  }) {
    return Debt(
      id: id ?? this.id,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      description: description ?? this.description,
      originalAmount: originalAmount ?? this.originalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Debt &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Debt(id: $id, type: ${type.name}, person: $personName, remaining: $remainingAmount)';
}

enum DebtType {
  lending,  // Money you lent out
  borrowing; // Money you owe

  String get displayName {
    switch (this) {
      case DebtType.lending:
        return 'Lending';
      case DebtType.borrowing:
        return 'Borrowing';
    }
  }
}

enum DebtStatus {
  active,
  overdue,
  settled;

  String get displayName {
    switch (this) {
      case DebtStatus.active:
        return 'Active';
      case DebtStatus.overdue:
        return 'Overdue';
      case DebtStatus.settled:
        return 'Settled';
    }
  }
}
