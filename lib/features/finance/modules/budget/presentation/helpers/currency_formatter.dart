import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  return '₱${NumberFormat('#,##0.00').format(amount)}';
}
