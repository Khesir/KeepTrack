class Account {
  final String? id; // optional - db auto-generates
  final String name;
  final double balance;
  final String? color;
  final String? bankAccountNumber;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final bool isArchived;

  Account({
    this.id,
    required this.name,
    this.balance = 0,
    this.bankAccountNumber,
    this.createdAt,
    this.updatedAt,
    this.color,
    this.isArchived = false,
  });
  Map get transactions => {};

  /// Create a copy of Account with optional updated fields
  Account copyWith({
    String? id,
    String? name,
    double? balance,
    String? color,
    String? bankAccountNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      color: color ?? this.color,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Account(id: $id, name: $name)';
}
