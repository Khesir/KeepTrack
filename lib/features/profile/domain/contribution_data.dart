/// Contribution data models for GitHub-style contribution graph
class ContributionData {
  final DateTime date;
  final int count;
  final List<ContributionActivity> activities;

  ContributionData({
    required this.date,
    required this.count,
    required this.activities,
  });

  /// Get contribution level (0-4) for color intensity
  /// 0 = no contributions
  /// 1 = 1-2 contributions (light green)
  /// 2 = 3-5 contributions (medium green)
  /// 3 = 6-9 contributions (dark green)
  /// 4 = 10+ contributions (darkest green)
  int get level {
    if (count == 0) return 0;
    if (count <= 2) return 1;
    if (count <= 5) return 2;
    if (count <= 9) return 3;
    return 4;
  }
}

/// Individual contribution activity
class ContributionActivity {
  final DateTime timestamp;
  final ContributionType type;
  final String title;
  final String? id;

  ContributionActivity({
    required this.timestamp,
    required this.type,
    required this.title,
    this.id,
  });

  String get displayText {
    switch (type) {
      case ContributionType.taskCreated:
        return 'Created task: $title';
      case ContributionType.taskCompleted:
        return 'Completed task: $title';
      case ContributionType.sessionCreated:
        return 'Started session: $title';
      case ContributionType.projectCreated:
        return 'Created project: $title';
    }
  }

  String get icon {
    switch (type) {
      case ContributionType.taskCreated:
        return '📝';
      case ContributionType.taskCompleted:
        return '✅';
      case ContributionType.sessionCreated:
        return '⏱️';
      case ContributionType.projectCreated:
        return '📁';
    }
  }
}

enum ContributionType {
  taskCreated,
  taskCompleted,
  sessionCreated,
  projectCreated,
}

/// Summary of contributions for a period
class ContributionSummary {
  final int totalContributions;
  final int tasksCreated;
  final int tasksCompleted;
  final int sessionsCreated;
  final int projectsCreated;
  final int currentStreak;
  final int longestStreak;
  final Map<DateTime, ContributionData> contributionsByDate;

  ContributionSummary({
    required this.totalContributions,
    required this.tasksCreated,
    required this.tasksCompleted,
    required this.sessionsCreated,
    required this.projectsCreated,
    required this.currentStreak,
    required this.longestStreak,
    required this.contributionsByDate,
  });
}
