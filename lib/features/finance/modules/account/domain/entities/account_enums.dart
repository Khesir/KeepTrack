enum AccountType {
  cash,
  bank,
  credit,
  investment,
  savings,
  other, // fallback
}

extension AccountTypeX on AccountType {
  String get name {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank';
      case AccountType.credit:
        return 'Credit';
      case AccountType.investment:
        return 'Investment';
      case AccountType.savings:
        return 'Savings';
      case AccountType.other:
        return 'Other';
    }
  }

  /// Convert string from database to enum
  static AccountType fromString(String? str) {
    switch (str?.toLowerCase()) {
      case 'cash':
        return AccountType.cash;
      case 'bank':
        return AccountType.bank;
      case 'credit':
        return AccountType.credit;
      case 'investment':
        return AccountType.investment;
      case 'savings':
        return AccountType.savings;
      default:
        return AccountType.other;
    }
  }
}
