import 'package:flutter/material.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/project_repository.dart';

/// Task detail screen - Create or edit a task
class TaskDetailScreen extends ScopedScreen {
  final Task? task;
  final String? initialProjectId;

  const TaskDetailScreen({super.key, this.task, this.initialProjectId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ScopedScreenState<TaskDetailScreen> {
  late TaskRepository _taskRepository;
  late ProjectRepository _projectRepository;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  TaskStatus _status = TaskStatus.todo;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  String? _selectedProjectId;
  List<Project> _projects = [];

  bool get _isEditing => widget.task != null;

  @override
  void registerServices() {
    // Uses global repository
  }

  @override
  void onReady() {
    _taskRepository = getService<TaskRepository>();
    _projectRepository = getService<ProjectRepository>();

    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');

    if (widget.task != null) {
      _status = widget.task!.status;
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
      _selectedProjectId = widget.task!.projectId;
    } else if (widget.initialProjectId != null) {
      _selectedProjectId = widget.initialProjectId;
    }

    _loadProjects();
    setState(() {});
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _projectRepository.getActiveProjects();
      setState(() => _projects = projects);
    } catch (e) {
      // Ignore error, projects are optional
    }
  }

  @override
  void onDispose() {
    _titleController.dispose();
    _descriptionController.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final now = DateTime.now();

      if (_isEditing) {
        // Update existing task
        final updated = widget.task!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
          projectId: _selectedProjectId,
          updatedAt: now,
        );

        await _taskRepository.updateTask(updated);
      } else {
        // Create new task
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          status: _status,
          priority: _priority,
          projectId: _selectedProjectId,
          createdAt: now,
          updatedAt: now,
          dueDate: _dueDate,
        );

        await _taskRepository.createTask(newTask);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
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

    if (confirmed != true) return;

    try {
      await _taskRepository.deleteTask(widget.task!.id);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting task: $e')),
        );
      }
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTask,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Project Selector
            if (_projects.isNotEmpty)
              DropdownButtonFormField<String?>(
                value: _selectedProjectId,
                decoration: const InputDecoration(
                  labelText: 'Project (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No Project'),
                  ),
                  ..._projects.map((project) => DropdownMenuItem(
                        value: project.id,
                        child: Text(project.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedProjectId = value);
                },
              ),
            if (_projects.isNotEmpty) const SizedBox(height: 16),

            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: TaskStatus.values
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: TaskPriority.values
                  .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date'),
              subtitle: Text(
                _dueDate != null
                    ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                    : 'No due date',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDueDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveTask,
              child: Text(_isEditing ? 'Update Task' : 'Create Task'),
            ),
          ],
        ),
      ),
    );
  }
}
