import 'package:flutter/material.dart';

class ContributionChart extends StatelessWidget {
  const ContributionChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - will be replaced with actual task activity from database
    final contributions = _generateMockContributions();

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
                  'Last 12 Weeks',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_getTotalTasks(contributions)} tasks completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contribution grid
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day labels
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      ...List.generate(12, (weekIndex) {
                        return Container(
                          width: 28,
                          alignment: Alignment.center,
                          child: Text(
                            'W${12 - weekIndex}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Grid of contributions (7 rows for days of week)
                  ...List.generate(7, (dayIndex) {
                    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          // Day label
                          SizedBox(
                            width: 40,
                            child: Text(
                              dayLabels[dayIndex],
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          // Contribution squares for this day across 12 weeks
                          ...List.generate(12, (weekIndex) {
                            final tasks = contributions[weekIndex][dayIndex];
                            return _buildContributionSquare(tasks);
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Less',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                const SizedBox(width: 4),
                _buildContributionSquare(0),
                _buildContributionSquare(1),
                _buildContributionSquare(3),
                _buildContributionSquare(5),
                _buildContributionSquare(8),
                const SizedBox(width: 4),
                Text(
                  'More',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
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
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // Generate mock data: 12 weeks x 7 days
  List<List<int>> _generateMockContributions() {
    final random = [3, 0, 5, 2, 8, 1, 4, 0, 6, 3, 2, 7, 1, 0, 4, 5, 2, 3, 0, 1];
    return List.generate(12, (weekIndex) {
      return List.generate(7, (dayIndex) {
        final index = (weekIndex * 7 + dayIndex) % random.length;
        return random[index];
      });
    });
  }

  int _getTotalTasks(List<List<int>> contributions) {
    int total = 0;
    for (var week in contributions) {
      for (var dayTasks in week) {
        total += dayTasks;
      }
    }
    return total;
  }
}
