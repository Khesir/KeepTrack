import 'package:flutter/material.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../domain/entities/project.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../domain/repositories/project_repository.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../domain/usecase/usecases.dart';
import '../../../tasks/domain/usecases/usecases.dart';
import '../state/project_detail_controller.dart';

/// Project detail screen - Shows project info and its tasks
class ProjectDetailScreen extends ScopedScreen {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ScopedScreenState<ProjectDetailScreen> {
  late ProjectDetailController _controller;

  @override
  void registerServices() {
    // Uses global repository and scope services

    final taskRepository = getService<TaskRepository>();
    final projectRepository = getService<ProjectRepository>();

    scope.registerFactory<ProjectDetailController>(
      () => ProjectDetailController(
        updateProjectUseCase: UpdateProjectUseCase(projectRepository),
        deleteProjectUseCase: DeleteProjectUseCase(projectRepository),
        getTasksByProjectUseCase: GetTasksByProjectUseCase(taskRepository),
        initialProject: widget.project, // current project data
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = scope.get<ProjectDetailController>();
  }

  @override
  void onReady() {
    // Only UI configuration here (if needed)
  }

  @override
  void onDispose() {
    _controller.dispose();
  }

  void _createTask() {
    final project = widget.project;
    if (project.id == null) return;

    context
        .goToTaskCreate(initialProjectId: project.id!)
        .then((_) => _controller.loadTasks());
  }

  void _openTask(Task task) {
    context.goToTaskDetail(task).then((_) => _controller.loadTasks());
  }

  Future<void> _editProject() async {
    final project = widget.project;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EditProjectDialog(project: project),
    );

    if (result != null && project.id != null) {
      final success = await _controller.updateProject(
        UpdateProjectParams(
          projectId: project.id!,
          name: result['name'],
          description: result['description'],
          color: result['color'],
        ),
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error updating project')));
      }
    }
  }

  Future<void> _deleteProject() async {
    final project = widget.project;
    if (project.id == null) return;

    if (_controller.tasks.isNotEmpty) {
      // Warn if project has tasks
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Project'),
          content: Text(
            'This project has ${_controller.tasks.length} task(s). '
            'Please delete or move all tasks before deleting the project.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _controller.deleteProject(project.id!);

      if (success && mounted) {
        context.goBack();
      } else if (!success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error deleting project')));
      }
    }
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return Colors.blue;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<Project?>(
      state: _controller,
      builder: (context, project) {
        // Handle case where project is null (deleted)
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project')),
            body: const Center(child: Text('Project not found')),
          );
        }

        final projectColor = _parseColor(project.color);

        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            backgroundColor: projectColor,
            actions: [
              IconButton(icon: const Icon(Icons.edit), onPressed: _editProject),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteProject,
              ),
            ],
          ),
          body: Column(
            children: [
              // Project Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: projectColor.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (project.description != null &&
                        project.description!.isNotEmpty)
                      Text(
                        project.description!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${_controller.totalCount} tasks • ${_controller.completedCount} completed',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    if (_controller.tasks.isNotEmpty)
                      LinearProgressIndicator(
                        value:
                            _controller.completedCount / _controller.totalCount,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(projectColor),
                      ),
                  ],
                ),
              ),

              // Tasks List
              Expanded(
                child: _controller.isLoadingTasks
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks in this project',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _createTask,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Task'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _controller.loadTasks,
                        child: ListView.builder(
                          itemCount: _controller.tasks.length,
                          itemBuilder: (context, index) {
                            final task = _controller.tasks[index];
                            return _ProjectTaskListItem(
                              task: task,
                              onTap: () => _openTask(task),
                              onToggleComplete: () => _toggleComplete(task),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _createTask,
            backgroundColor: projectColor,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _toggleComplete(Task task) async {
    if (task.id == null) return;

    try {
      final taskRepo = getService<TaskRepository>();
      final updated = task.copyWith(
        status: task.isCompleted ? TaskStatus.todo : TaskStatus.completed,
        completedAt: task.isCompleted ? null : DateTime.now(),
      );

      await taskRepo.updateTask(updated);
      await _controller.loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating task: $e')));
      }
    }
  }
}

class _ProjectTaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;

  const _ProjectTaskListItem({
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggleComplete(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: task.description != null && task.description!.isNotEmpty
            ? Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}

class _EditProjectDialog extends StatefulWidget {
  final Project project;

  const _EditProjectDialog({required this.project});

  @override
  State<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<_EditProjectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(
      text: widget.project.description ?? '',
    );
    _selectedColor = _parseColor(widget.project.color);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return Colors.blue;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Project'),
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}
