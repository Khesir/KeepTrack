import 'account_enums.dart';

class Account {
  final String? id; // optional - db auto-generates
  final String name;
  final AccountType accountType;
  final double balance;
  final String? colorHex; // Store color as hex string
  final String? iconCodePoint; // Store icon as code point
  final String? bankAccountNumber;
  final bool isActive;
  final bool isArchived;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final String? userId;

  Account({
    this.id,
    required this.name,
    this.accountType = AccountType.cash,
    this.balance = 0,
    this.colorHex,
    this.iconCodePoint,
    this.bankAccountNumber,
    this.isActive = true,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
    this.userId,
  });

  /// Create a copy of Account with optional updated fields
  Account copyWith({
    String? id,
    String? name,
    AccountType? accountType,
    double? balance,
    String? colorHex,
    String? iconCodePoint,
    String? bankAccountNumber,
    bool? isActive,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      balance: balance ?? this.balance,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
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
