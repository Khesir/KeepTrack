import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/entities/bucket.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';

class ProjectManagementDialog extends StatefulWidget {
  final Project? project;
  final String userId;
  final Future<void> Function(Project) onSave;
  final Future<void> Function()? onDelete;
  final List<Bucket>? buckets;

  const ProjectManagementDialog({
    super.key,
    this.project,
    required this.userId,
    required this.onSave,
    this.onDelete,
    this.buckets,
  });

  @override
  State<ProjectManagementDialog> createState() =>
      _ProjectManagementDialogState();
}

class _ProjectManagementDialogState extends State<ProjectManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  bool _isArchived = false;
  Color _selectedColor = Colors.blue;
  String? _selectedBucketId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.project?.description ?? '');
    _isArchived = widget.project?.isArchived ?? false;
    _selectedColor = widget.project?.color != null
        ? Color(
            int.parse(widget.project!.color!.replaceFirst('#', '0xff')))
        : Colors.blue;
    _selectedBucketId = widget.project?.bucketId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.project != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Project' : 'Add Project'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter project name' : null,
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Color Picker
                Row(
                  children: [
                    const Text('Color:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _pickColor,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bucket Selection
                if (widget.buckets != null && widget.buckets!.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    value: _selectedBucketId,
                    decoration: const InputDecoration(
                      labelText: 'Bucket',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No Bucket'),
                      ),
                      ...widget.buckets!.where((b) => !b.isArchive).map(
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

                // Archived
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Archived'),
                  value: _isArchived,
                  onChanged: (v) => setState(() => _isArchived = v),
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
                  title: const Text('Delete Project'),
                  content: const Text(
                    'Are you sure you want to delete this project?',
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

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
            showLabel: true,
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final project = Project(
      id: widget.project?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      color: '#${_selectedColor.value.toRadixString(16).padLeft(8, '0')}',
      isArchived: _isArchived,
      userId: widget.userId,
      createdAt: widget.project?.createdAt,
      updatedAt: widget.project?.updatedAt,
      bucketId: _selectedBucketId,
    );

    await widget.onSave(project);
    if (mounted) Navigator.pop(context);
  }
}
