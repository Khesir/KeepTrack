import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/features/profile/domain/contribution_data.dart';

/// Activity feed showing recent contributions with pagination
class ContributionActivityFeed extends StatefulWidget {
  final ContributionSummary summary;
  final int itemsPerPage;

  const ContributionActivityFeed({
    super.key,
    required this.summary,
    this.itemsPerPage = 10,
  });

  @override
  State<ContributionActivityFeed> createState() =>
      _ContributionActivityFeedState();
}

class _ContributionActivityFeedState extends State<ContributionActivityFeed> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    // Get all activities sorted by timestamp (most recent first)
    final allActivities = <ContributionActivity>[];

    for (final contribution in widget.summary.contributionsByDate.values) {
      allActivities.addAll(contribution.activities);
    }

    // Sort by timestamp descending
    allActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (allActivities.isEmpty) {
      return _buildEmptyState(context);
    }

    // Calculate pagination
    final totalPages = (allActivities.length / widget.itemsPerPage).ceil();
    final startIndex = _currentPage * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage).clamp(
      0,
      allActivities.length,
    );
    final displayActivities = allActivities.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with pagination
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  'Showing ${startIndex + 1}-$endIndex of ${allActivities.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                // Previous page button
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                  tooltip: 'Previous page',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                // Next page button
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                  tooltip: 'Next page',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Activity list
        ...displayActivities.map((activity) {
          return _buildActivityItem(context, activity);
        }),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start creating tasks, projects, or sessions!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    ContributionActivity activity,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getActivityColor(activity.type).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getActivityColor(activity.type).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              size: 20,
              color: _getActivityColor(activity.type),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActivityActionText(activity.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Timestamp - Show actual date/time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('MMM d, y').format(activity.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                DateFormat('h:mm a').format(activity.timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(ContributionType type) {
    switch (type) {
      case ContributionType.taskCreated:
        return Colors.blue;
      case ContributionType.taskCompleted:
        return Colors.green;
      case ContributionType.sessionCreated:
        return Colors.orange;
      case ContributionType.projectCreated:
        return Colors.purple;
    }
  }

  IconData _getActivityIcon(ContributionType type) {
    switch (type) {
      case ContributionType.taskCreated:
        return Icons.add_task;
      case ContributionType.taskCompleted:
        return Icons.check_circle;
      case ContributionType.sessionCreated:
        return Icons.timer;
      case ContributionType.projectCreated:
        return Icons.folder_open;
    }
  }

  String _getActivityActionText(ContributionType type) {
    switch (type) {
      case ContributionType.taskCreated:
        return 'Created task';
      case ContributionType.taskCompleted:
        return 'Completed task';
      case ContributionType.sessionCreated:
        return 'Started session';
      case ContributionType.projectCreated:
        return 'Created project';
    }
  }
}
