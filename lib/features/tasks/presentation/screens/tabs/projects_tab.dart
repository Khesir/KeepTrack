import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Projects Tab with Card Design
class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Projects',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${dummyProjects.length} projects',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Projects Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: dummyProjects.length,
            itemBuilder: (context, index) {
              final project = dummyProjects[index];
              return _buildProjectCard(project);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(ProjectItem project) {
    final completedTasks = project.completedTasks;
    final totalTasks = project.totalTasks;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to project detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Header with Color
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    project.color,
                    project.color.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    project.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Project Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    if (project.description != null) ...[
                      Text(
                        project.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Spacer(),

                    // Progress
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: project.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: project.color.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(project.color),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$completedTasks/$totalTasks',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            if (project.dueDate != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d').format(project.dueDate!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Project Data Class
class ProjectItem {
  final String id;
  final String name;
  final String? description;
  final Color color;
  final IconData icon;
  final int completedTasks;
  final int totalTasks;
  final DateTime? dueDate;

  ProjectItem({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.icon,
    required this.completedTasks,
    required this.totalTasks,
    this.dueDate,
  });
}

// Dummy Project Data
final dummyProjects = [
  ProjectItem(
    id: '1',
    name: 'Mobile App Redesign',
    description: 'Redesign the mobile application UI/UX',
    color: Colors.blue[700]!,
    icon: Icons.phone_android,
    completedTasks: 8,
    totalTasks: 15,
    dueDate: DateTime.now().add(const Duration(days: 14)),
  ),
  ProjectItem(
    id: '2',
    name: 'Backend Migration',
    description: 'Migrate backend services to cloud infrastructure',
    color: Colors.purple[700]!,
    icon: Icons.cloud_upload,
    completedTasks: 3,
    totalTasks: 10,
    dueDate: DateTime.now().add(const Duration(days: 30)),
  ),
  ProjectItem(
    id: '3',
    name: 'Marketing Campaign',
    description: 'Q4 marketing and promotional campaign',
    color: Colors.orange[700]!,
    icon: Icons.campaign,
    completedTasks: 12,
    totalTasks: 20,
    dueDate: DateTime.now().add(const Duration(days: 7)),
  ),
  ProjectItem(
    id: '4',
    name: 'API Documentation',
    description: 'Update API documentation for v2.0',
    color: Colors.green[700]!,
    icon: Icons.description,
    completedTasks: 5,
    totalTasks: 8,
    dueDate: DateTime.now().add(const Duration(days: 21)),
  ),
  ProjectItem(
    id: '5',
    name: 'Security Audit',
    description: 'Comprehensive security audit and fixes',
    color: Colors.red[700]!,
    icon: Icons.security,
    completedTasks: 2,
    totalTasks: 12,
    dueDate: DateTime.now().add(const Duration(days: 45)),
  ),
  ProjectItem(
    id: '6',
    name: 'Customer Portal',
    description: 'Build new customer self-service portal',
    color: Colors.teal[700]!,
    icon: Icons.people,
    completedTasks: 15,
    totalTasks: 25,
    dueDate: DateTime.now().add(const Duration(days: 60)),
  ),
];
