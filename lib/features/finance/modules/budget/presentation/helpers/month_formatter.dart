const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _monthNamesShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a "YYYY-MM" string to "Month Year" (e.g. "May 2026").
String formatMonthDisplay(String monthStr, {bool short = false}) {
  try {
    final parts = monthStr.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    final names = short ? _monthNamesShort : _monthNames;
    return '${names[month - 1]} $year';
  } catch (_) {
    return monthStr;
  }
}

/// Returns "YYYY-MM" for the current month.
String currentMonthKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}
