import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/presentation/state/project_controller.dart';

enum ProjectStatusFilter { all, active, postponed, closed }

/// Projects Tab with Card Design
class ProjectsTab extends ScopedScreen {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends ScopedScreenState<ProjectsTab>
    with AppLayoutControlled {
  late final ProjectController _controller;
  ProjectStatusFilter _statusFilter = ProjectStatusFilter.all;

  @override
  void registerServices() {
    _controller = locator.get<ProjectController>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Projects', showBottomNav: true);
  }

  List<Project> _filterProjects(List<Project> projects) {
    if (_statusFilter == ProjectStatusFilter.all) {
      return projects.where((p) => !p.isArchived).toList();
    }

    return projects.where((project) {
      if (project.isArchived) return false;

      switch (_statusFilter) {
        case ProjectStatusFilter.active:
          return project.status == ProjectStatus.active;
        case ProjectStatusFilter.postponed:
          return project.status == ProjectStatus.postponed;
        case ProjectStatusFilter.closed:
          return project.status == ProjectStatus.closed;
        case ProjectStatusFilter.all:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return AsyncStreamBuilder<List<Project>>(
          state: _controller,
          builder: (context, projects) {
            final filteredProjects = _filterProjects(projects);

            return Scaffold(
              backgroundColor: isDesktop ? AppColors.backgroundSecondary : null,
              body: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1400 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        if (!isDesktop)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Projects',
                                style: isDesktop
                                    ? AppTextStyles.h1
                                    : Theme.of(
                                        context,
                                      ).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                              ),

                              Text(
                                '${filteredProjects.length} project${filteredProjects.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: isDesktop ? AppSpacing.xl : 12),

                        // Status Filters
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip(
                                    'All',
                                    ProjectStatusFilter.all,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'Active',
                                    ProjectStatusFilter.active,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'Postponed',
                                    ProjectStatusFilter.postponed,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'Closed',
                                    ProjectStatusFilter.closed,
                                  ),
                                ],
                              ),
                            ),
                            if (isDesktop)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.projectManagement,
                                  );
                                },
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Manage Projects'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Empty State or Projects Grid
                        if (filteredProjects.isEmpty)
                          _buildEmptyState()
                        else if (isDesktop)
                          ResponsiveGrid(
                            spacing: AppSpacing.lg,
                            desktopChildAspectRatio: 0.85,
                            children: filteredProjects
                                .map((project) => _buildProjectCard(project))
                                .toList(),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: filteredProjects.length,
                            itemBuilder: (context, index) {
                              final project = filteredProjects[index];
                              return _buildProjectCard(project);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              floatingActionButton: isDesktop
                  ? null
                  : FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.projectManagement,
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Manage Projects'),
                    ),
            );
          },
          loadingBuilder: (_) => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          errorBuilder: (context, message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading projects',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _controller.loadProjects(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, ProjectStatusFilter filter) {
    final isSelected = _statusFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = filter;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No projects found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusFilter == ProjectStatusFilter.all
                  ? 'Create your first project to get started'
                  : 'No projects with this status',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    // Parse color from project
    final projectColor = project.color != null
        ? Color(int.parse(project.color!.replaceFirst('#', '0xff')))
        : Colors.blue[700]!;

    final statusColor = project.status == ProjectStatus.active
        ? Colors.green
        : project.status == ProjectStatus.postponed
        ? Colors.orange
        : Colors.grey;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context
              .goToProjectDetail(project)
              .then((_) => _controller.loadActiveProjects());
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
                  colors: [projectColor, projectColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.folder, color: Colors.white, size: 32),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Spacer(),

                    // Created date
                    if (project.createdAt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Created ${DateFormat('MMM d, yyyy').format(project.createdAt!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),

                    // Status Badge
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            project.status == ProjectStatus.active
                                ? Icons.check_circle
                                : project.status == ProjectStatus.postponed
                                ? Icons.pause_circle
                                : Icons.cancel,
                            size: 12,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            project.status.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
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
