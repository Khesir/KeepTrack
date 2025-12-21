import 'package:persona_codex/features/finance/modules/account/domain/entities/account.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class AccountModel {
  final String? id; // optional - db auto-generates
  final String name;
  final String? accountType;
  final double balance;
  final String? colorHex;
  final String? iconCodePoint;
  final String? bankAccountNumber;
  final bool isActive;
  final bool isArchived;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates

  AccountModel({
    this.id,
    required this.name,
    this.accountType,
    this.balance = 0,
    this.colorHex,
    this.iconCodePoint,
    this.bankAccountNumber,
    this.isActive = true,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
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
    );
  }

  /// Convert from model to domain entity
  Account toEntity() {
    return Account(
      id: id,
      name: name,
      accountType: accountType,
      balance: balance,
      colorHex: colorHex,
      iconCodePoint: iconCodePoint,
      bankAccountNumber: bankAccountNumber,
      isActive: isActive,
      isArchived: isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert from Supabase JSON
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      accountType: json['account_type'] as String?,
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
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (accountType != null) 'account_type': accountType,
      'balance': balance,
      if (colorHex != null) 'color_hex': colorHex,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
      'is_active': isActive,
      'is_archived': isArchived,
    };
  }
}
