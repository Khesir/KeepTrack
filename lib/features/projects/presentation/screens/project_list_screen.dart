import 'package:flutter/material.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/features/projects/domain/usecase/create_project_usecase.dart';
import 'package:persona_codex/features/projects/domain/usecase/get_projects_usecase.dart';
import 'package:persona_codex/features/projects/presentation/state/project_list_controller.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../../tasks/domain/entities/task.dart';

/// Project list screen - Displays all projects
class ProjectListScreen extends ScopedScreen {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ScopedScreenState<ProjectListScreen>
    with AppLayoutControlled {
  late final ProjectListController _controller;
  late final TaskRepository _taskRepository;

  // Store task counts: projectId -> {completed, total}
  final Map<String, Map<String, int>> _taskCounts = {};

  @override
  void registerServices() {
    // No DI registration needed for controller/usecases
  }

  @override
  void initState() {
    super.initState();

    // Create controller without DI (as requested)
    final projectRepo = scope.get<ProjectRepository>();
    _taskRepository = scope.get<TaskRepository>();

    _controller = ProjectListController(
      getProjectUsecase: GetProjectsUsecase(projectRepo),
      createProjectUsecase: CreateProjectUsecase(projectRepo),
    );
  }

  Future<void> _loadTaskCounts(List<Project> projects) async {
    for (final project in projects) {
      if (project.id != null) {
        try {
          final tasks = await _taskRepository.getTasksByProject(project.id!);
          final completed = tasks.where((t) => t.isCompleted).length;
          setState(() {
            _taskCounts[project.id!] = {
              'completed': completed,
              'total': tasks.length,
            };
          });
        } catch (e) {
          // Silently fail - task counts are optional
        }
      }
    }
  }

  @override
  void onReady() {
    configureLayout(
      title: 'Projects',
      fab: FloatingActionButton(
        onPressed: _createProject,
        child: const Icon(Icons.add),
      ),
      showBottomNav: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createProject() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _CreateProjectDialog(),
    );

    if (result != null) {
      final project = CreateProjectParams(
        name: result['name']!,
        description: result['description'],
        color: result['color'],
      );
      await _controller
          .createProject(project)
          .then((_) => _controller.loadProjects());
    }
  }

  void _openProject(Project project) {
    context.goToProjectDetail(project).then((_) => _controller.loadProjects());
  }

  Future<void> _archiveProject(Project project) async {
    // Projects from DB always have IDs
    if (project.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Project ID is missing')),
      );
      return;
    }

    // try {
    //   await _projectRepository.archiveProject(project.id!);
    //   _loadProjects();
    // } catch (e) {
    //   if (mounted) {
    //     ScaffoldMessenger.of(
    //       context,
    //     ).showSnackBar(SnackBar(content: Text('Error archiving project: $e')));
    //   }
    // }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Project>>(
      state: _controller,
      builder: (context, projects) {
        // Load task counts when projects are loaded
        if (projects.isNotEmpty && _taskCounts.isEmpty) {
          _loadTaskCounts(projects);
        }

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No projects yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            _taskCounts.clear(); // Clear counts to reload
            await _controller.loadProjects();
          },
          child: ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final taskCount = _taskCounts[project.id];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: project.color != null
                        ? _parseColor(project.color!)
                        : Colors.blue,
                    child: Text(
                      project.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
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
                      if (taskCount != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${taskCount['completed']} / ${taskCount['total']} tasks',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.archive),
                    onPressed: () => _archiveProject(project),
                  ),
                  onTap: () => _openProject(project),
                  isThreeLine: project.description != null && taskCount != null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CreateProjectDialog extends StatefulWidget {
  const _CreateProjectDialog();

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Project'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children:
                [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                ].map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'description': _descriptionController.text,
                'color':
                    '#${_selectedColor.value.toRadixString(16).substring(2)}',
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
