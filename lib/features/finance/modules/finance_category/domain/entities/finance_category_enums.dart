import 'package:flutter/material.dart';

enum CategoryType { income, expense, investment, savings, transfer }

extension CategoryTypeExtension on CategoryType {
  /// Human-readable name
  String get displayName {
    switch (this) {
      case CategoryType.income:
        return 'Income';
      case CategoryType.expense:
        return 'Expense';
      case CategoryType.investment:
        return 'Investment';
      case CategoryType.savings:
        return 'Savings';
      case CategoryType.transfer:
        return 'Transfer';
    }
  }

  /// Short description
  String get description {
    switch (this) {
      case CategoryType.income:
        return 'Money coming in';
      case CategoryType.expense:
        return 'Money going out';
      case CategoryType.investment:
        return 'Long-term growth';
      case CategoryType.savings:
        return 'Money set aside';
      case CategoryType.transfer:
        return 'Move money between accounts';
    }
  }

  /// Color associated with category type
  Color get color {
    switch (this) {
      case CategoryType.income:
        return Colors.green;
      case CategoryType.expense:
        return Colors.red;
      case CategoryType.investment:
        return Colors.blue;
      case CategoryType.savings:
        return Colors.orange;
      case CategoryType.transfer:
        return Colors.purple;
    }
  }

  /// Icon associated with category type
  IconData get icon {
    switch (this) {
      case CategoryType.income:
        return Icons.arrow_downward;
      case CategoryType.expense:
        return Icons.arrow_upward;
      case CategoryType.investment:
        return Icons.trending_up;
      case CategoryType.savings:
        return Icons.savings;
      case CategoryType.transfer:
        return Icons.swap_horiz;
    }
  }
}
