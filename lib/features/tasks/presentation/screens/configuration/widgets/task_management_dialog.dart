import 'package:flutter/material.dart';
import 'package:persona_codex/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:persona_codex/features/tasks/modules/tasks/domain/entities/task.dart';

class TaskManagementDialog extends StatefulWidget {
  final Task? task;
  final String userId;
  final Future<void> Function(Task) onSave;
  final Future<void> Function()? onDelete;
  final List<Project>? projects;
  final String? parentTaskId; // Direct parent task ID when creating subtask

  const TaskManagementDialog({
    super.key,
    this.task,
    required this.userId,
    required this.onSave,
    this.onDelete,
    this.projects,
    this.parentTaskId,
  });

  @override
  State<TaskManagementDialog> createState() => _TaskManagementDialogState();
}

class _TaskManagementDialogState extends State<TaskManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  TaskStatus _selectedStatus = TaskStatus.todo;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _dueDate;
  List<String> _tags = [];
  String? _selectedProjectId;
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _selectedStatus = widget.task?.status ?? TaskStatus.todo;
    _selectedPriority = widget.task?.priority ?? TaskPriority.medium;
    _dueDate = widget.task?.dueDate;
    _tags = widget.task?.tags.toList() ?? [];
    _selectedProjectId = widget.task?.projectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    final isSubtask = widget.parentTaskId != null;

    return AlertDialog(
      title: Text(
        isEdit
            ? 'Edit Task'
            : isSubtask
                ? 'Add Subtask'
                : 'Add Task',
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter task title' : null,
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Status
                DropdownButtonFormField<TaskStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: TaskStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedStatus = v);
                  },
                ),
                const SizedBox(height: 12),

                // Priority
                DropdownButtonFormField<TaskPriority>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: TaskPriority.values
                      .map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPriority = v);
                  },
                ),
                const SizedBox(height: 12),

                // Project
                if (widget.projects != null && widget.projects!.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    value: _selectedProjectId,
                    decoration: const InputDecoration(labelText: 'Project'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No Project'),
                      ),
                      ...widget.projects!.map(
                        (project) => DropdownMenuItem<String?>(
                          value: project.id,
                          child: Text(project.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedProjectId = v),
                  ),
                if (widget.projects != null && widget.projects!.isNotEmpty)
                  const SizedBox(height: 12),

                // Due Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Date'),
                  subtitle: _dueDate != null
                      ? Text(_dueDate!.toString().split(' ')[0])
                      : const Text('Not set'),
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
                        onPressed: _pickDueDate,
                      ),
                    ],
                  ),
                ),

                // Tags
                const Text('Tags:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ..._tags.map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () =>
                              setState(() => _tags.remove(tag)),
                        )),
                    InkWell(
                      onTap: _addTag,
                      child: Chip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: const Text('Add tag'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (isEdit && widget.onDelete != null)
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Task'),
                  content: const Text(
                    'Are you sure you want to delete this task?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await widget.onDelete?.call();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: Text(isEdit ? 'Save' : 'Add')),
      ],
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _addTag() async {
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: _tagController,
          decoration: const InputDecoration(
            hintText: 'Enter tag name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _tagController.text.trim());
              _tagController.clear();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (tag != null && tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      status: _selectedStatus,
      priority: _selectedPriority,
      projectId: _selectedProjectId,
      parentTaskId: widget.parentTaskId ?? widget.task?.parentTaskId,
      dueDate: _dueDate,
      tags: _tags,
      userId: widget.userId,
      createdAt: widget.task?.createdAt,
      updatedAt: widget.task?.updatedAt,
    );

    await widget.onSave(task);
    if (mounted) Navigator.pop(context);
  }
}
