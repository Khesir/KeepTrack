import 'package:flutter/material.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/entities/bucket.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';

import 'task_form_page.dart';

/// Wrapper widget that shows TaskFormPage in dialog mode
/// This maintains backward compatibility with existing code
class TaskManagementDialog extends StatelessWidget {
  final Task? task;
  final String userId;
  final Future<void> Function(Task) onSave;
  final Future<void> Function()? onDelete;
  final List<Project>? projects;
  final List<Bucket>? buckets;
  final String? parentTaskId;
  final bool
  useDialogContent; // Use dialog content mode (for custom dialog wrappers)

  const TaskManagementDialog({
    super.key,
    this.task,
    required this.userId,
    required this.onSave,
    this.onDelete,
    this.projects,
    this.parentTaskId,
    this.useDialogContent = false,
    this.buckets,
  });

  @override
  Widget build(BuildContext context) {
    return TaskFormPage(
      task: task,
      userId: userId,
      onSave: onSave,
      onDelete: onDelete,
      projects: projects,
      buckets: buckets,
      parentTaskId: parentTaskId,
      isDialog: !useDialogContent,
      isDialogContent: useDialogContent,
    );
  }
}
