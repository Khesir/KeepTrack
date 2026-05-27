class SavingsBucket {
  final String? id;
  final String userId;
  final String name;
  final double balance;
  final String? colorHex;
  final String? iconCodePoint;

  const SavingsBucket({
    this.id,
    required this.userId,
    required this.name,
    required this.balance,
    this.colorHex,
    this.iconCodePoint,
  });

  SavingsBucket copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    String? colorHex,
    String? iconCodePoint,
  }) {
    return SavingsBucket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsBucket && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
