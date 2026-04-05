import 'package:keep_track/features/profile/domain/contribution_data.dart';

/// Calculator for contribution statistics
class ContributionCalculator {
  /// Calculate contributions for a date range
  static ContributionSummary calculateContributions({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Normalize dates to start of day
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // Build contribution map for each day
    final Map<DateTime, ContributionData> contributionsByDate = {};

    // Initialize all days in range with 0 contributions
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final dayStart = DateTime(current.year, current.month, current.day);
      contributionsByDate[dayStart] = ContributionData(
        date: dayStart,
        count: 0,
        activities: [],
      );
      current = current.add(const Duration(days: 1));
    }

    // Sort activities by timestamp (most recent first)
    for (final entry in contributionsByDate.entries) {
      final sorted = List<ContributionActivity>.from(entry.value.activities)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      contributionsByDate[entry.key] = ContributionData(
        date: entry.key,
        count: entry.value.count,
        activities: sorted,
      );
    }

    // Calculate streaks
    final streaks = _calculateStreaks(contributionsByDate);

    return ContributionSummary(
      totalContributions: 0,
      tasksCreated: 0,
      tasksCompleted: 0,
      sessionsCreated: 0,
      projectsCreated: 0,
      currentStreak: streaks['current']!,
      longestStreak: streaks['longest']!,
      contributionsByDate: contributionsByDate,
    );
  }

  /// Calculate current and longest streaks
  static Map<String, int> _calculateStreaks(
    Map<DateTime, ContributionData> contributions,
  ) {
    final sortedDates = contributions.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    if (sortedDates.isEmpty) {
      return {'current': 0, 'longest': 0};
    }

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    // Calculate longest streak
    DateTime? prevDate;
    for (final date in sortedDates) {
      final data = contributions[date]!;

      if (data.count > 0) {
        if (prevDate == null ||
            date.difference(prevDate).inDays == 1) {
          tempStreak++;
          longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
        } else {
          tempStreak = 1;
        }
        prevDate = date;
      } else {
        tempStreak = 0;
        prevDate = null;
      }
    }

    // Calculate current streak (backwards from today)
    for (int i = 0; i <= 365; i++) {
      final checkDate = todayKey.subtract(Duration(days: i));
      final data = contributions[checkDate];

      if (data != null && data.count > 0) {
        currentStreak++;
      } else {
        break;
      }
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }

  /// Get contribution data for a specific month
  static ContributionSummary getMonthlyContributions({
    required int year,
    required int month,
  }) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return calculateContributions(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get contribution data for a specific year
  static ContributionSummary getYearlyContributions({
    required int year,
  }) {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);

    return calculateContributions(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
