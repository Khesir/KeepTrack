import '../../domain/entities/wallet.dart';

class WalletModel extends Wallet {
  WalletModel({
    super.id,
    required super.userId,
    required super.name,
    required super.balance,
    super.type,
    super.colorHex,
    super.iconCodePoint,
    super.notes,
    super.labels,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String?,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      type: WalletType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WalletType.standard,
      ),
      colorHex: json['colorHex'] as String?,
      iconCodePoint: json['iconCodePoint']?.toString(),
      notes: json['notes'] as String?,
      labels: (json['labels'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'name': name,
      'balance': balance,
      'type': type.name,
      if (colorHex != null) 'colorHex': colorHex,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
      if (notes != null) 'notes': notes,
      'labels': labels,
    };
  }

  factory WalletModel.fromEntity(Wallet wallet) {
    return WalletModel(
      id: wallet.id,
      userId: wallet.userId,
      name: wallet.name,
      balance: wallet.balance,
      type: wallet.type,
      colorHex: wallet.colorHex,
      iconCodePoint: wallet.iconCodePoint,
      notes: wallet.notes,
      labels: wallet.labels,
    );
  }
}
