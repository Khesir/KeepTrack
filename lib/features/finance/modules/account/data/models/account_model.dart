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

  /// Convert from domain entity to model
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

  /// Convert from Supabase JSON
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      accountType: AccountTypeX.fromString(json['account_type'] as String?),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      colorHex: json['color_hex'] as String?,
      iconCodePoint: json['icon_code_point'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userId: json['user_id'] as String?,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'account_type': accountType.name,
      'balance': balance,
      if (colorHex != null) 'color_hex': colorHex,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
      'is_active': isActive,
      'is_archived': isArchived,
      if (userId != null) 'user_id': userId,
    };
  }
}
