import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/entities/bucket.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../../state/bucket_controller.dart';
import '../../state/project_controller.dart';
import '../../state/task_controller.dart';
import 'widgets/project_management_dialog.dart';

class ProjectManagementScreen extends ScopedScreen {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() =>
      _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends ScopedScreenState<ProjectManagementScreen>
    with AppLayoutControlled {
  late final ProjectController _controller;
  late final TaskController _taskController;
  late final BucketController _bucketController;
  late final SupabaseService supabaseService;

  @override
  void registerServices() {
    _controller = locator.get<ProjectController>();
    _taskController = locator.get<TaskController>();
    _bucketController = locator.get<BucketController>();
    supabaseService = locator.get<SupabaseService>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Manage Projects', showBottomNav: false);
    _bucketController.loadBuckets();
  }

  void _showMetadataEditor(Project project) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _MetadataEditorDialog(
        project: project,
        onSave: (updatedMetadata) async {
          final updatedProject = project.copyWith(metadata: updatedMetadata);
          await _controller.updateProject(updatedProject);
          return true;
        },
      ),
    );

    if (result == true && mounted) {
      // Reload the project data
      await _controller.loadProjects();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project information saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showProjectDialog({Project? project, List<Task>? allTasks, List<Bucket>? buckets}) {
    showDialog(
      context: context,
      builder: (context) => ProjectManagementDialog(
        project: project,
        userId: supabaseService.userId!,
        buckets: buckets,
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
    return AsyncStreamBuilder<List<Bucket>>(
      state: _bucketController,
      loadingBuilder: (_) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      errorBuilder: (_, __) => _buildScaffold(null, null, null),
      builder: (context, buckets) {
        return _buildScaffold(buckets, null, null);
      },
    );
  }

  Widget _buildScaffold(List<Bucket>? buckets, List<Task>? tasks, List<Project>? projects) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          AsyncStreamBuilder<List<Task>>(
            state: _taskController,
            builder: (context, tasks) {
              return IconButton(
                onPressed: () => _showProjectDialog(allTasks: tasks, buckets: buckets),
                icon: const Icon(Icons.add),
              );
            },
            loadingBuilder: (_) => IconButton(
              onPressed: () => _showProjectDialog(buckets: buckets),
              icon: const Icon(Icons.add),
            ),
            errorBuilder: (_, __) => IconButton(
              onPressed: () => _showProjectDialog(buckets: buckets),
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline, size: 20),
                                    tooltip: 'Edit Project Information',
                                    onPressed: () => _showMetadataEditor(project),
                                  ),
                                  if (project.isArchived)
                                    const Icon(Icons.archive, color: Colors.orange),
                                ],
                              ),
                              onTap: () => _showProjectDialog(
                                project: project,
                                allTasks: tasks,
                                buckets: buckets,
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

/// Metadata Editor Dialog - Allows adding/editing/deleting project metadata
class _MetadataEditorDialog extends StatefulWidget {
  final Project project;
  final Future<bool> Function(Map<String, String>) onSave;

  const _MetadataEditorDialog({
    required this.project,
    required this.onSave,
  });

  @override
  State<_MetadataEditorDialog> createState() => _MetadataEditorDialogState();
}

class _MetadataEditorDialogState extends State<_MetadataEditorDialog> {
  late Map<String, String> _metadata;
  final _formKey = GlobalKey<FormState>();
  String? _newKey;
  String? _newValue;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _metadata = Map<String, String>.from(widget.project.metadata);
  }

  void _addNewEntry() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_newKey != null && _newValue != null) {
        setState(() {
          _metadata[_newKey!] = _newValue!;
          _newKey = null;
          _newValue = null;
        });
        _formKey.currentState!.reset();
      }
    }
  }

  void _deleteEntry(String key) {
    setState(() {
      _metadata.remove(key);
    });
  }

  void _editEntry(String oldKey, String newKey, String newValue) {
    setState(() {
      if (oldKey != newKey) {
        _metadata.remove(oldKey);
      }
      _metadata[newKey] = newValue;
    });
  }

  Future<void> _saveMetadata() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await widget.onSave(_metadata);
      if (mounted) {
        Navigator.pop(context, success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving metadata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Project Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add dynamic information like links, documentation, ERD, etc.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Existing entries
            if (_metadata.isNotEmpty) ...[
              const Text(
                'Current Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _metadata.length,
                  itemBuilder: (context, index) {
                    final entry = _metadata.entries.elementAt(index);
                    return _buildMetadataEntry(entry.key, entry.value);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Add new entry form
            const Text(
              'Add New Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Label (e.g., Project Link, ERD, Documentation)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a label';
                      }
                      if (_metadata.containsKey(value) && _newKey != value) {
                        return 'This label already exists';
                      }
                      return null;
                    },
                    onSaved: (value) => _newKey = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Value (e.g., https://..., Description)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.text_fields),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value';
                      }
                      return null;
                    },
                    onSaved: (value) => _newValue = value,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addNewEntry,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Entry'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveMetadata,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataEntry(String key, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getMetadataIcon(key),
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          key,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(key, value),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _deleteEntry(key),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String oldKey, String oldValue) {
    final keyController = TextEditingController(text: oldKey);
    final valueController = TextEditingController(text: oldValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
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
              _editEntry(oldKey, keyController.text, valueController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  IconData _getMetadataIcon(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('link') || lowerKey.contains('url')) {
      return Icons.link;
    } else if (lowerKey.contains('erd') || lowerKey.contains('diagram')) {
      return Icons.schema;
    } else if (lowerKey.contains('doc') || lowerKey.contains('documentation')) {
      return Icons.description;
    } else if (lowerKey.contains('repo') || lowerKey.contains('github')) {
      return Icons.code;
    } else {
      return Icons.info;
    }
  }
}
