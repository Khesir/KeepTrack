import 'package:persona_codex/features/finance/domain/entities/account.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class AccountModel {
  final String? id; // optional - db auto-generates
  final String name;
  final double balance;
  final String? color;
  final String? bankAccountNumber;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final bool isArchived;

  AccountModel({
    this.id,
    required this.name,
    this.balance = 0,
    this.bankAccountNumber,
    this.createdAt,
    this.updatedAt,
    this.color,
    this.isArchived = false,
  });

  /// Convert from domain entity to model
  factory AccountModel.fromEntity(Account account) {
    return AccountModel(
      id: account.id,
      name: account.name,
      balance: account.balance,
      color: account.color,
      bankAccountNumber: account.bankAccountNumber,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
      isArchived: account.isArchived,
    );
  }

  /// Convert from model to domain entity
  Account toEntity() {
    return Account(
      id: id,
      name: name,
      balance: balance,
      color: color,
      bankAccountNumber: bankAccountNumber,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isArchived: isArchived,
    );
  }

  /// Convert from Supabase JSON
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      color: json['color'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'balance': balance,
      if (color != null) 'color': color,
      if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'is_archived': isArchived,
    };
  }
}
