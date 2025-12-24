import 'package:flutter/material.dart';

enum PaymentCategory {
  bills,
  subscriptions,
  insurance,
  loan,
  rent,
  utilities,
  other;

  String get displayName {
    switch (this) {
      case PaymentCategory.bills:
        return 'Bills';
      case PaymentCategory.subscriptions:
        return 'Subscriptions';
      case PaymentCategory.insurance:
        return 'Insurance';
      case PaymentCategory.loan:
        return 'Loan';
      case PaymentCategory.rent:
        return 'Rent';
      case PaymentCategory.utilities:
        return 'Utilities';
      case PaymentCategory.other:
        return 'Other';
    }
  }
}

extension PaymentCategoryX on PaymentCategory {
  String get label => displayName;

  IconData get icon => switch (this) {
    PaymentCategory.bills => Icons.receipt_long,
    PaymentCategory.subscriptions => Icons.subscriptions,
    PaymentCategory.insurance => Icons.shield,
    PaymentCategory.loan => Icons.account_balance,
    PaymentCategory.rent => Icons.home,
    PaymentCategory.utilities => Icons.flash_on,
    PaymentCategory.other => Icons.more_horiz,
  };

  Color get color => switch (this) {
    PaymentCategory.bills => Colors.blue,
    PaymentCategory.subscriptions => Colors.purple,
    PaymentCategory.insurance => Colors.green,
    PaymentCategory.loan => Colors.orange,
    PaymentCategory.rent => Colors.teal,
    PaymentCategory.utilities => Colors.amber,
    PaymentCategory.other => Colors.grey,
  };
}

enum PaymentFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
  oneTime;

  String get displayName {
    switch (this) {
      case PaymentFrequency.oneTime:
        return 'One-time';
      case PaymentFrequency.daily:
        return 'Daily';
      case PaymentFrequency.weekly:
        return 'Weekly';
      case PaymentFrequency.biweekly:
        return 'Bi-weekly';
      case PaymentFrequency.monthly:
        return 'Monthly';
      case PaymentFrequency.quarterly:
        return 'Quarterly';
      case PaymentFrequency.yearly:
        return 'Yearly';
    }
  }
}

enum PaymentStatus {
  active,
  paused,
  cancelled,
  closed;

  String get displayName {
    switch (this) {
      case PaymentStatus.active:
        return 'Active';
      case PaymentStatus.paused:
        return 'Paused';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.closed:
        return 'Closed';
    }
  }
}
