import '../../domain/entities/savings_bucket.dart';

class SavingsBucketModel extends SavingsBucket {
  SavingsBucketModel({
    super.id,
    required super.userId,
    required super.name,
    required super.balance,
    super.colorHex,
    super.iconCodePoint,
  });

  factory SavingsBucketModel.fromJson(Map<String, dynamic> json) {
    return SavingsBucketModel(
      id: json['id'] as String?,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      colorHex: json['colorHex'] as String?,
      iconCodePoint: json['iconCodePoint']?.toString(),
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'balance': balance,
      if (colorHex != null) 'colorHex': colorHex,
      if (iconCodePoint != null) 'iconCodePoint': int.tryParse(iconCodePoint!),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'name': name,
      'balance': balance,
      if (colorHex != null) 'colorHex': colorHex,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
    };
  }

  factory SavingsBucketModel.fromEntity(SavingsBucket bucket) {
    return SavingsBucketModel(
      id: bucket.id,
      userId: bucket.userId,
      name: bucket.name,
      balance: bucket.balance,
      colorHex: bucket.colorHex,
      iconCodePoint: bucket.iconCodePoint,
    );
  }
}
