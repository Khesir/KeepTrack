import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import '../../domain/entities/account_enums.dart';

class AccountModel extends Account {
  AccountModel({
    super.id,
    required super.name,
    super.accountType,
    super.balance,
    super.colorHex,
    super.iconCodePoint,
    super.bankAccountNumber,
    super.isActive,
    super.isArchived,
    super.createdAt,
    super.updatedAt,
    super.userId,
  });

  factory AccountModel.fromEntity(Account account) {
    return AccountModel(
      id: account.id,
      name: account.name,
      accountType: account.accountType,
      balance: account.balance,
      colorHex: account.colorHex,
      iconCodePoint: account.iconCodePoint,
      bankAccountNumber: account.bankAccountNumber,
      isActive: account.isActive,
      isArchived: account.isArchived,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
      userId: account.userId,
    );
  }

  /// NestJS API response (camelCase)
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      accountType: AccountTypeX.fromString(json['accountType'] as String?),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      colorHex: json['colorHex'] as String?,
      iconCodePoint: json['iconCodePoint']?.toString(),
      bankAccountNumber: json['bankAccountNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      userId: json['userId'] as String?,
    );
  }

  /// NestJS API request body (camelCase)
  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'accountType': accountType.name,
      'balance': balance,
      if (colorHex != null) 'colorHex': colorHex,
      if (iconCodePoint != null) 'iconCodePoint': int.tryParse(iconCodePoint!),
      if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
      'isActive': isActive,
      'isArchived': isArchived,
    };
  }

  /// Cache serialisation (local storage)
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'accountType': accountType.name,
        'balance': balance,
        if (colorHex != null) 'colorHex': colorHex,
        if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
        if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        'isActive': isActive,
        'isArchived': isArchived,
        if (userId != null) 'userId': userId,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}
