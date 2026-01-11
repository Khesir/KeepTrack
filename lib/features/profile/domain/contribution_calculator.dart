import 'package:keep_track/features/profile/domain/contribution_data.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/modules/pomodoro/domain/entities/pomodoro_session.dart';

/// Calculator for contribution statistics
class ContributionCalculator {
  /// Calculate contributions for a date range
  static ContributionSummary calculateContributions({
    required DateTime startDate,
    required DateTime endDate,
    required List<Task> tasks,
    required List<Project> projects,
    required List<PomodoroSession> sessions,
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

    int tasksCreated = 0;
    int tasksCompleted = 0;
    int sessionsCreated = 0;
    int projectsCreated = 0;

    // Process tasks
    for (final task in tasks) {
      // Task created
      if (task.createdAt != null &&
          !task.createdAt!.isBefore(start) &&
          !task.createdAt!.isAfter(end)) {
        final dayKey = DateTime(
          task.createdAt!.year,
          task.createdAt!.month,
          task.createdAt!.day,
        );

        if (contributionsByDate.containsKey(dayKey)) {
          final existing = contributionsByDate[dayKey]!;
          contributionsByDate[dayKey] = ContributionData(
            date: dayKey,
            count: existing.count + 1,
            activities: [
              ...existing.activities,
              ContributionActivity(
                timestamp: task.createdAt!,
                type: ContributionType.taskCreated,
                title: task.title,
                id: task.id,
              ),
            ],
          );
          tasksCreated++;
        }
      }

      // Task completed
      if (task.completedAt != null &&
          !task.completedAt!.isBefore(start) &&
          !task.completedAt!.isAfter(end)) {
        final dayKey = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );

        if (contributionsByDate.containsKey(dayKey)) {
          final existing = contributionsByDate[dayKey]!;
          contributionsByDate[dayKey] = ContributionData(
            date: dayKey,
            count: existing.count + 1,
            activities: [
              ...existing.activities,
              ContributionActivity(
                timestamp: task.completedAt!,
                type: ContributionType.taskCompleted,
                title: task.title,
                id: task.id,
              ),
            ],
          );
          tasksCompleted++;
        }
      }
    }

    // Process projects
    for (final project in projects) {
      if (project.createdAt != null &&
          !project.createdAt!.isBefore(start) &&
          !project.createdAt!.isAfter(end)) {
        final dayKey = DateTime(
          project.createdAt!.year,
          project.createdAt!.month,
          project.createdAt!.day,
        );

        if (contributionsByDate.containsKey(dayKey)) {
          final existing = contributionsByDate[dayKey]!;
          contributionsByDate[dayKey] = ContributionData(
            date: dayKey,
            count: existing.count + 1,
            activities: [
              ...existing.activities,
              ContributionActivity(
                timestamp: project.createdAt!,
                type: ContributionType.projectCreated,
                title: project.name,
                id: project.id,
              ),
            ],
          );
          projectsCreated++;
        }
      }
    }

    // Process sessions
    for (final session in sessions) {
      if (!session.startedAt.isBefore(start) &&
          !session.startedAt.isAfter(end)) {
        final dayKey = DateTime(
          session.startedAt.year,
          session.startedAt.month,
          session.startedAt.day,
        );

        if (contributionsByDate.containsKey(dayKey)) {
          final existing = contributionsByDate[dayKey]!;
          contributionsByDate[dayKey] = ContributionData(
            date: dayKey,
            count: existing.count + 1,
            activities: [
              ...existing.activities,
              ContributionActivity(
                timestamp: session.startedAt,
                type: ContributionType.sessionCreated,
                title: session.title,
                id: session.id,
              ),
            ],
          );
          sessionsCreated++;
        }
      }
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

    final totalContributions = tasksCreated +
        tasksCompleted +
        sessionsCreated +
        projectsCreated;

    return ContributionSummary(
      totalContributions: totalContributions,
      tasksCreated: tasksCreated,
      tasksCompleted: tasksCompleted,
      sessionsCreated: sessionsCreated,
      projectsCreated: projectsCreated,
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
    required List<Task> tasks,
    required List<Project> projects,
    required List<PomodoroSession> sessions,
  }) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return calculateContributions(
      startDate: startDate,
      endDate: endDate,
      tasks: tasks,
      projects: projects,
      sessions: sessions,
    );
  }

  /// Get contribution data for a specific year
  static ContributionSummary getYearlyContributions({
    required int year,
    required List<Task> tasks,
    required List<Project> projects,
    required List<PomodoroSession> sessions,
  }) {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);

    return calculateContributions(
      startDate: startDate,
      endDate: endDate,
      tasks: tasks,
      projects: projects,
      sessions: sessions,
    );
  }
}
