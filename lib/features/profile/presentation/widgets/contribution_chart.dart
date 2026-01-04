import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/profile/presentation/state/task_activity_controller.dart';

class ContributionChart extends StatefulWidget {
  const ContributionChart({super.key});

  @override
  State<ContributionChart> createState() => _ContributionChartState();
}

class _ContributionChartState extends State<ContributionChart> {
  late final TaskActivityController _controller;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TaskActivityController>();
    _controller.loadTaskActivity(6); // Load last 6 months
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<Map<DateTime, int>>(
      state: _controller,
      loadingBuilder: (_) => Card(
        elevation: 0,
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ),
      errorBuilder: (context, message) => Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error loading activity: $message'),
        ),
      ),
      builder: (context, activityMap) {
        final contributions = _processActivityData(activityMap);
        final totalTasks = activityMap.values.fold(0, (sum, count) => sum + count);

        return _buildChart(context, contributions, totalTasks);
      },
    );
  }

  Widget _buildChart(BuildContext context, List<List<Map<String, dynamic>>> contributions, int totalTasks) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Last 6 Months Activity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$totalTasks tasks completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contribution grid (GitHub-style)
            _buildGitHubStyleGrid(contributions),
            const SizedBox(height: 16),

            // Legend
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Less',
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 6),
                  _buildContributionSquare(0),
                  _buildContributionSquare(1),
                  _buildContributionSquare(3),
                  _buildContributionSquare(5),
                  _buildContributionSquare(8),
                  const SizedBox(width: 6),
                  Text(
                    'More',
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionSquare(int taskCount) {
    Color color;
    if (taskCount == 0) {
      color = Colors.grey[200]!;
    } else if (taskCount <= 2) {
      color = Colors.green[200]!;
    } else if (taskCount <= 4) {
      color = Colors.green[400]!;
    } else if (taskCount <= 6) {
      color = Colors.green[600]!;
    } else {
      color = Colors.green[800]!;
    }

    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Process activity data into weekly grid (GitHub-style)
  /// Returns list of weeks, each week has 7 days with specific dates and counts
  List<List<Map<String, dynamic>>> _processActivityData(Map<DateTime, int> activityMap) {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);

    // Find the first Monday on or before sixMonthsAgo
    DateTime startDate = sixMonthsAgo;
    while (startDate.weekday != DateTime.monday) {
      startDate = startDate.subtract(const Duration(days: 1));
    }

    final weeks = <List<Map<String, dynamic>>>[];
    DateTime currentDate = startDate;

    // Generate weeks until we reach today
    while (currentDate.isBefore(now) || currentDate.isAtSameMomentAs(now)) {
      final week = <Map<String, dynamic>>[];

      // Generate 7 days for this week (Mon-Sun)
      for (int i = 0; i < 7; i++) {
        final date = currentDate.add(Duration(days: i));
        week.add({
          'date': date,
          'count': activityMap[DateTime(date.year, date.month, date.day)] ?? 0,
        });
      }

      weeks.add(week);
      currentDate = currentDate.add(const Duration(days: 7));
    }

    return weeks;
  }

  Widget _buildGitHubStyleGrid(List<List<Map<String, dynamic>>> weeks) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month markers (above the grid)
          _buildMonthMarkers(weeks),
          const SizedBox(height: 4),

          // Main grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels column
              Column(
                children: [
                  const SizedBox(height: 18), // Space for alignment
                  ...['Mon', '', 'Wed', '', 'Fri', '', 'Sun'].map((label) {
                    return Container(
                      height: 18,
                      width: 30,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              // Weeks columns
              ...weeks.map((week) => _buildWeekColumn(week)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthMarkers(List<List<Map<String, dynamic>>> weeks) {
    final markers = <Widget>[];
    String? lastMonth;

    markers.add(const SizedBox(width: 30)); // Space for day labels

    for (final week in weeks) {
      final firstDay = week.first['date'] as DateTime;
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final currentMonth = monthNames[firstDay.month - 1];

      if (currentMonth != lastMonth) {
        markers.add(
          Container(
            width: 18,
            alignment: Alignment.centerLeft,
            child: Text(
              currentMonth,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        );
        lastMonth = currentMonth;
      } else {
        markers.add(const SizedBox(width: 18));
      }
    }

    return Row(children: markers);
  }

  Widget _buildWeekColumn(List<Map<String, dynamic>> week) {
    return Column(
      children: week.map((day) {
        final count = day['count'] as int;
        return _buildContributionSquare(count);
      }).toList(),
    );
  }
}
