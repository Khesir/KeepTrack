enum WalletType {
  standard,
  creditCard;

  String get displayName {
    switch (this) {
      case WalletType.standard:
        return 'Standard';
      case WalletType.creditCard:
        return 'Credit Card';
    }
  }
}

class Wallet {
  final String? id;
  final String userId;
  final String name;
  final double balance;
  final WalletType type;
  final String? colorHex;
  final String? iconCodePoint;

  const Wallet({
    this.id,
    required this.userId,
    required this.name,
    required this.balance,
    this.type = WalletType.standard,
    this.colorHex,
    this.iconCodePoint,
  });

  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    WalletType? type,
    String? colorHex,
    String? iconCodePoint,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
