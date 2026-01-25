import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/entities/bucket.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../../state/bucket_controller.dart';
import '../../state/task_controller.dart';

class BucketManagementScreen extends ScopedScreen {
  const BucketManagementScreen({super.key});

  @override
  State<BucketManagementScreen> createState() => _BucketManagementScreenState();
}

class _BucketManagementScreenState extends ScopedScreenState<BucketManagementScreen>
    with AppLayoutControlled {
  late final BucketController _controller;
  late final TaskController _taskController;
  late final SupabaseService _supabaseService;

  @override
  void registerServices() {
    _controller = locator.get<BucketController>();
    _taskController = locator.get<TaskController>();
    _supabaseService = locator.get<SupabaseService>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Manage Buckets', showBottomNav: false);
  }

  void _showBucketDialog({Bucket? bucket, List<Task>? allTasks}) {
    showDialog(
      context: context,
      builder: (context) => _BucketManagementDialog(
        bucket: bucket,
        userId: _supabaseService.userId!,
        onSave: (updatedBucket) async {
          try {
            if (bucket != null) {
              await _controller.updateBucket(updatedBucket);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bucket updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              await _controller.createBucket(updatedBucket);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bucket created successfully'),
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
        onDelete: bucket != null
            ? () async {
                try {
                  // Check if bucket has tasks
                  if (allTasks != null) {
                    final tasksInBucket =
                        allTasks.where((t) => t.bucketId == bucket.id).toList();
                    if (tasksInBucket.isNotEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cannot delete bucket: ${tasksInBucket.length} task(s) associated. Remove tasks from bucket first.',
                            ),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                      return;
                    }
                  }

                  await _controller.deleteBucket(bucket.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bucket deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting bucket: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            : null,
        onArchive: bucket != null && !bucket.isArchive
            ? () async {
                try {
                  await _controller.archiveBucket(bucket.id!);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bucket archived successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error archiving bucket: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            : null,
        onUnarchive: bucket != null && bucket.isArchive
            ? () async {
                try {
                  await _controller.unarchiveBucket(bucket.id!);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bucket unarchived successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error unarchiving bucket: ${e.toString()}'),
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
        title: const Text('Buckets'),
        actions: [
          AsyncStreamBuilder<List<Task>>(
            state: _taskController,
            builder: (context, tasks) {
              return IconButton(
                onPressed: () => _showBucketDialog(allTasks: tasks),
                icon: const Icon(Icons.add),
              );
            },
            loadingBuilder: (_) => IconButton(
              onPressed: () => _showBucketDialog(),
              icon: const Icon(Icons.add),
            ),
            errorBuilder: (_, __) => IconButton(
              onPressed: () => _showBucketDialog(),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: AsyncStreamBuilder<List<Task>>(
        state: _taskController,
        builder: (context, tasks) {
          return AsyncStreamBuilder<List<Bucket>>(
            state: _controller,
            builder: (context, buckets) {
              final activeBuckets = buckets.where((b) => !b.isArchive).length;

              return Column(
                children: [
                  // Stats card
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: ListTile(
                      title: const Text('Total Buckets'),
                      subtitle: Text('$activeBuckets active'),
                      trailing: Text(
                        '${buckets.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  // Buckets list or empty state
                  Expanded(
                    child: buckets.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text('No buckets found.'),
                                SizedBox(height: 8),
                                Text(
                                  'Tap + to create your first bucket',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: buckets.length,
                            itemBuilder: (context, index) {
                              final bucket = buckets[index];
                              final taskCount = tasks
                                  .where((t) => t.bucketId == bucket.id)
                                  .length;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.inbox,
                                      color: bucket.isArchive
                                          ? Colors.grey
                                          : Colors.purple[700],
                                    ),
                                  ),
                                  title: Text(
                                    bucket.name,
                                    style: TextStyle(
                                      decoration: bucket.isArchive
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$taskCount task(s)'),
                                      if (bucket.createdAt != null)
                                        Text(
                                          'Created: ${DateFormat('MMM d, yyyy').format(bucket.createdAt!)}',
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
                                      if (bucket.isArchive)
                                        const Icon(
                                          Icons.archive,
                                          color: Colors.orange,
                                        ),
                                    ],
                                  ),
                                  onTap: () => _showBucketDialog(
                                    bucket: bucket,
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
            loadingBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, message) => Center(child: Text(message)),
          );
        },
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(child: Text(message)),
      ),
    );
  }
}

/// Bucket Management Dialog
class _BucketManagementDialog extends StatefulWidget {
  final Bucket? bucket;
  final String userId;
  final Future<void> Function(Bucket) onSave;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onArchive;
  final Future<void> Function()? onUnarchive;

  const _BucketManagementDialog({
    this.bucket,
    required this.userId,
    required this.onSave,
    this.onDelete,
    this.onArchive,
    this.onUnarchive,
  });

  @override
  State<_BucketManagementDialog> createState() =>
      _BucketManagementDialogState();
}

class _BucketManagementDialogState extends State<_BucketManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bucket?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final bucket = Bucket(
        id: widget.bucket?.id,
        name: _nameController.text.trim(),
        isArchive: widget.bucket?.isArchive ?? false,
        userId: widget.userId,
        createdAt: widget.bucket?.createdAt,
        updatedAt: widget.bucket?.updatedAt,
      );

      await widget.onSave(bucket);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bucket'),
        content: const Text(
          'Are you sure you want to delete this bucket? This action cannot be undone.',
        ),
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.bucket != null;

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Bucket' : 'Create Bucket',
                  style: const TextStyle(
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
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Bucket Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inbox),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a bucket name';
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEdit && widget.onDelete != null) ...[
                  TextButton(
                    onPressed: _isSaving ? null : _handleDelete,
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const Spacer(),
                ],
                if (widget.onArchive != null)
                  TextButton(
                    onPressed: _isSaving ? null : widget.onArchive,
                    child: const Text('Archive'),
                  ),
                if (widget.onUnarchive != null)
                  TextButton(
                    onPressed: _isSaving ? null : widget.onUnarchive,
                    child: const Text('Unarchive'),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(isEdit ? 'Save' : 'Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
