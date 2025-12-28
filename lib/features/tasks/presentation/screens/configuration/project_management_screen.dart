import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:persona_codex/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';

import '../../state/project_controller.dart';
import '../../state/task_controller.dart';
import 'widgets/project_management_dialog.dart';

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() =>
      _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  late final ProjectController _controller;
  late final TaskController _taskController;
  late final SupabaseService supabaseService;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<ProjectController>();
    _taskController = locator.get<TaskController>();
    supabaseService = locator.get<SupabaseService>();
  }

  void _showProjectDialog({Project? project, List<Task>? allTasks}) {
    showDialog(
      context: context,
      builder: (context) => ProjectManagementDialog(
        project: project,
        userId: supabaseService.userId!,
        onSave: (updatedProject) async {
          try {
            if (project != null) {
              await _controller.updateProject(updatedProject);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Project updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              await _controller.createProject(updatedProject);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Project created successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onDelete: project != null
            ? () async {
                try {
                  // Check if project has tasks
                  if (allTasks != null) {
                    final tasksInProject = allTasks.where((t) => t.projectId == project.id).toList();
                    if (tasksInProject.isNotEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cannot delete project: ${tasksInProject.length} task(s) associated. Delete tasks first.',
                            ),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                      return;
                    }
                  }

                  await _controller.deleteProject(project.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Project deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting project: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          AsyncStreamBuilder<List<Task>>(
            state: _taskController,
            builder: (context, tasks) {
              return IconButton(
                onPressed: () => _showProjectDialog(allTasks: tasks),
                icon: const Icon(Icons.add),
              );
            },
            loadingBuilder: (_) => IconButton(
              onPressed: () => _showProjectDialog(),
              icon: const Icon(Icons.add),
            ),
            errorBuilder: (_, __) => IconButton(
              onPressed: () => _showProjectDialog(),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: AsyncStreamBuilder<List<Task>>(
        state: _taskController,
        builder: (context, tasks) {
          return AsyncStreamBuilder<List<Project>>(
            state: _controller,
            builder: (context, projects) {
              final activeProjects =
                  projects.where((p) => !p.isArchived).length;

              return Column(
            children: [
              // Stats card - always shown
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  title: const Text('Total Projects'),
                  subtitle: Text('$activeProjects active'),
                  trailing: Text(
                    '${projects.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              // Projects list or empty state
              Expanded(
                child: projects.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text('No projects found.'),
                            SizedBox(height: 8),
                            Text(
                              'Tap + to create your first project',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          final projectColor = project.color != null
                              ? Color(int.parse(
                                  project.color!.replaceFirst('#', '0xff')))
                              : Colors.blue[700]!;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: projectColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.folder,
                                  color: projectColor,
                                ),
                              ),
                              title: Text(project.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (project.description != null)
                                    Text(
                                      project.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  if (project.createdAt != null)
                                    Text(
                                      'Created: ${DateFormat('MMM d, yyyy').format(project.createdAt!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: project.isArchived
                                  ? const Icon(Icons.archive, color: Colors.orange)
                                  : null,
                              onTap: () => _showProjectDialog(
                                project: project,
                                allTasks: tasks,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
            },
            loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, message) => Center(child: Text(message)),
          );
        },
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(child: Text(message)),
      ),
    );
  }
}
