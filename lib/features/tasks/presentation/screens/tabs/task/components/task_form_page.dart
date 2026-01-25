import 'package:flutter/material.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/entities/bucket.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';

class TaskFormPage extends StatefulWidget {
  final Task? task;
  final String userId;
  final Future<void> Function(Task) onSave;
  final Future<void> Function()? onDelete;
  final List<Project>? projects;
  final List<Bucket>? buckets;
  final String? parentTaskId;
  final bool isDialog; // Whether this is shown in a dialog or as a full page
  final bool
  isDialogContent; // Whether to return just content for custom dialog wrapper

  const TaskFormPage({
    super.key,
    this.task,
    required this.userId,
    required this.onSave,
    this.onDelete,
    this.projects,
    this.parentTaskId,
    this.isDialog = false,
    this.isDialogContent = false,
    this.buckets,
  });

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  TaskStatus _selectedStatus = TaskStatus.todo;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _dueDate;
  List<String> _tags = [];
  String? _selectedProjectId;
  String? _selectedBucketId;

  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedStatus = widget.task?.status ?? TaskStatus.todo;
    _selectedPriority = widget.task?.priority ?? TaskPriority.medium;
    _dueDate = widget.task?.dueDate;
    _tags = widget.task?.tags.toList() ?? [];
    _selectedProjectId = widget.task?.projectId;
    _selectedBucketId = widget.task?.bucketId; // Add bucket selection
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _addTag() async {
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: _tagController,
          decoration: const InputDecoration(hintText: 'Enter tag name'),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
              _tagController.clear();
            }
          },
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
      bucketId: _selectedBucketId,
    );

    await widget.onSave(task);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.onDelete?.call();
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildFormContent() {
    // Use Column when wrapped in a parent ScrollView (isDialogContent or isDialog)
    // Use ListView otherwise for built-in scrolling
    final formFields = [
      // Title
      TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Enter task title' : null,
        autofocus: !widget.isDialog,
      ),
      const SizedBox(height: 16),

      // Description
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Description',
          border: OutlineInputBorder(),
        ),
        maxLines: 5,
        minLines: 3,
      ),
      const SizedBox(height: 16),

      // Status
      DropdownButtonFormField<TaskStatus>(
        value: _selectedStatus,
        decoration: const InputDecoration(
          labelText: 'Status',
          border: OutlineInputBorder(),
        ),
        items: TaskStatus.values
            .map(
              (status) => DropdownMenuItem(
                value: status,
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 16,
                      color: _getStatusColor(status),
                    ),
                    const SizedBox(width: 8),
                    Text(status.displayName),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selectedStatus = v);
        },
      ),
      const SizedBox(height: 16),

      // Priority
      DropdownButtonFormField<TaskPriority>(
        value: _selectedPriority,
        decoration: const InputDecoration(
          labelText: 'Priority',
          border: OutlineInputBorder(),
        ),
        items: TaskPriority.values
            .map(
              (priority) => DropdownMenuItem(
                value: priority,
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: _getPriorityColor(priority),
                    ),
                    const SizedBox(width: 8),
                    Text(priority.displayName),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selectedPriority = v);
        },
      ),
      const SizedBox(height: 16),

      // Project
      if (widget.projects != null && widget.projects!.isNotEmpty) ...[
        DropdownButtonFormField<String?>(
          value: _selectedProjectId,
          decoration: const InputDecoration(
            labelText: 'Project',
            border: OutlineInputBorder(),
          ),
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
        const SizedBox(height: 16),
      ],
      // Buckets
      if (widget.buckets != null && widget.buckets!.isNotEmpty) ...[
        DropdownButtonFormField<String?>(
          value: _selectedBucketId,
          decoration: const InputDecoration(
            labelText: 'Buckets',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('No Buckets'),
            ),
            ...widget.buckets!.map(
              (bucket) => DropdownMenuItem<String?>(
                value: bucket.id,
                child: Text(bucket.name),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedBucketId = v),
        ),
        const SizedBox(height: 16),
      ],
      // Due Date
      Card(
        child: ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Due Date'),
          subtitle: _dueDate != null
              ? Text(
                  '${_dueDate!.toString().split('.')[0]}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )
              : const Text('Not set'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_dueDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _dueDate = null),
                  tooltip: 'Clear due date',
                ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _pickDueDate,
                tooltip: 'Set due date',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Tags
      const Text(
        'Tags',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._tags.map(
                (tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Add tag'),
                onPressed: _addTag,
              ),
            ],
          ),
        ),
      ),
    ];

    return Form(
      key: _formKey,
      child: widget.isDialogContent || widget.isDialog
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: formFields,
            )
          : ListView(padding: const EdgeInsets.all(16), children: formFields),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red[700]!;
      case TaskPriority.high:
        return Colors.orange[700]!;
      case TaskPriority.medium:
        return Colors.blue[700]!;
      case TaskPriority.low:
        return Colors.grey[600]!;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.orange[700]!;
      case TaskStatus.inProgress:
        return Colors.purple[700]!;
      case TaskStatus.completed:
        return Colors.green[700]!;
      case TaskStatus.cancelled:
        return Colors.red[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    final isSubtask = widget.parentTaskId != null;

    final title = isEdit
        ? 'Edit Task'
        : isSubtask
        ? 'Add Subtask'
        : 'Add Task';

    // Dialog content mode (just form with actions, no AlertDialog wrapper)
    if (widget.isDialogContent) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildFormContent(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEdit && widget.onDelete != null)
                  TextButton(
                    onPressed: _handleDelete,
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  child: Text(isEdit ? 'Save' : 'Create'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Dialog mode
    if (widget.isDialog) {
      return Dialog(
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildFormContent(),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isEdit && widget.onDelete != null)
                      TextButton(
                        onPressed: _handleDelete,
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(isEdit ? 'Save' : 'Add'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Full page mode
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isEdit && widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _handleDelete,
              tooltip: 'Delete Task',
            ),
        ],
      ),
      body: _buildFormContent(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isEdit ? 'Save Changes' : 'Create Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
