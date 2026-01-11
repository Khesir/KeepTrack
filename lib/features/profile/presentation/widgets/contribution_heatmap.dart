import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/features/profile/domain/contribution_data.dart';

/// GitHub-style contribution heatmap
class ContributionHeatmap extends StatelessWidget {
  final ContributionSummary summary;

  const ContributionHeatmap({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final contributions = summary.contributionsByDate;
    final sortedDates = contributions.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stats row
        _buildStatsRow(context),
        const SizedBox(height: 16),

        // Scrollable heatmap with ScrollConfiguration
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Prevent scroll notifications from bubbling up to parent
            return true;
          },
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              scrollbars: true,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Month labels
                    _buildMonthLabels(sortedDates, contributions),

                    // Main grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day labels
                        _buildDayLabels(),
                        const SizedBox(width: 10),

                        // Contribution squares
                        _buildHeatmapGrid(context, contributions, sortedDates),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Legend
        _buildLegend(context),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildStatChip(
          context,
          '${summary.totalContributions}',
          'contributions',
          Icons.trending_up,
          Colors.blue,
        ),
        _buildStatChip(
          context,
          '${summary.currentStreak}',
          'day streak',
          Icons.local_fire_department,
          Colors.orange,
        ),
        if (summary.longestStreak > 0)
          _buildStatChip(
            context,
            '${summary.longestStreak}',
            'longest',
            Icons.emoji_events,
            Colors.amber,
          ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMonthLabels(
    List<DateTime> dates,
    Map<DateTime, ContributionData> contributions,
  ) {
    if (dates.isEmpty) return const SizedBox();

    // Build weeks first to calculate positions
    final weeks = _buildWeeks(dates);

    final monthLabels = <Widget>[];
    int? lastMonth;
    int? lastYear;

    for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
      final week = weeks[weekIndex];
      if (week.isEmpty) continue;

      // Find the first day in this week that's within the date range
      DateTime? representativeDay;
      for (final day in week) {
        final dayKey = DateTime(day.year, day.month, day.day);
        if (day.isAfter(dates.first.subtract(const Duration(days: 1))) &&
            day.isBefore(dates.last.add(const Duration(days: 1)))) {
          representativeDay = day;
          break;
        }
      }

      // If no valid day found in range, use the middle day of the week
      representativeDay ??= week[week.length ~/ 2];

      final currentMonth = representativeDay.month;
      final currentYear = representativeDay.year;

      // Only add label if it's a new month (checking both month and year)
      if (lastMonth != currentMonth || lastYear != currentYear) {
        // Format to always get 3-letter month abbreviation
        String monthName = DateFormat('MMM', 'en_US').format(representativeDay);

        // Ensure it's exactly 3 characters
        if (monthName.length > 3) {
          monthName = monthName.substring(0, 3);
        }

        monthLabels.add(
          SizedBox(
            width: 17, // 14px square + 3px padding
            child: Text(
              monthName,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        lastMonth = currentMonth;
        lastYear = currentYear;
      } else {
        // Add empty space for weeks without month change
        monthLabels.add(const SizedBox(width: 17));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 38, bottom: 6),
      child: SizedBox(height: 16, child: Row(children: monthLabels)),
    );
  }

  Widget _buildDayLabels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildDayLabel('Mon'),
        const SizedBox(height: 3),
        _buildDayLabel(''),
        const SizedBox(height: 3),
        _buildDayLabel('Wed'),
        const SizedBox(height: 3),
        _buildDayLabel(''),
        const SizedBox(height: 3),
        _buildDayLabel('Fri'),
        const SizedBox(height: 3),
        _buildDayLabel(''),
        const SizedBox(height: 3),
        _buildDayLabel('Sun'),
      ],
    );
  }

  Widget _buildDayLabel(String label) {
    return SizedBox(
      height: 14,
      width: 28,
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        textAlign: TextAlign.right,
      ),
    );
  }

  List<List<DateTime>> _buildWeeks(List<DateTime> sortedDates) {
    if (sortedDates.isEmpty) return [];

    final weeks = <List<DateTime>>[];
    final firstDate = sortedDates.first;
    final lastDate = sortedDates.last;

    // Start from the beginning of the week containing firstDate
    // Week starts on Monday (weekday 1), ends on Sunday (weekday 7)
    int daysToSubtract = firstDate.weekday - 1; // Monday = 0 days back
    final weekStart = firstDate.subtract(Duration(days: daysToSubtract));

    DateTime current = weekStart;
    List<DateTime> currentWeek = [];

    // Calculate end of last week (the Sunday after lastDate)
    int daysToAdd = 7 - lastDate.weekday; // Days until Sunday
    final weekEnd = lastDate.add(Duration(days: daysToAdd));

    while (current.isBefore(weekEnd) || current.isAtSameMomentAs(weekEnd)) {
      currentWeek.add(current);

      // Sunday is the last day of the week (weekday == 7)
      if (current.weekday == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }

      current = current.add(const Duration(days: 1));
    }

    // Add remaining days if any
    if (currentWeek.isNotEmpty) {
      weeks.add(List.from(currentWeek));
    }

    return weeks;
  }

  Widget _buildHeatmapGrid(
    BuildContext context,
    Map<DateTime, ContributionData> contributions,
    List<DateTime> sortedDates,
  ) {
    final weeks = _buildWeeks(sortedDates);

    return Row(
      children: weeks.map((week) {
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Column(
            children: week.map((date) {
              final dayKey = DateTime(date.year, date.month, date.day);
              final data = contributions[dayKey];

              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: _buildContributionSquare(context, date, data),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContributionSquare(
    BuildContext context,
    DateTime date,
    ContributionData? data,
  ) {
    final level = data?.level ?? 0;
    final count = data?.count ?? 0;

    Color color;
    switch (level) {
      case 0:
        color = Colors.grey[200]!;
        break;
      case 1:
        color = Colors.green[200]!;
        break;
      case 2:
        color = Colors.green[400]!;
        break;
      case 3:
        color = Colors.green[600]!;
        break;
      case 4:
        color = Colors.green[800]!;
        break;
      default:
        color = Colors.grey[200]!;
    }

    return Tooltip(
      message:
          '${count} contributions on ${DateFormat('MMM d, y').format(date)}',
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: level > 0 ? color : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(width: 4),
        _buildLegendSquare(Colors.grey[200]!),
        _buildLegendSquare(Colors.green[200]!),
        _buildLegendSquare(Colors.green[400]!),
        _buildLegendSquare(Colors.green[600]!),
        _buildLegendSquare(Colors.green[800]!),
        const SizedBox(width: 4),
        Text('More', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildLegendSquare(Color color) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
