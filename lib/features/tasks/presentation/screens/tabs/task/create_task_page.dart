import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/task/components/task_management_dialog.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

class CreateTaskPage extends StatefulWidget {
  final Task? task;
  final String? parentTaskId;
  final bool noPadding;
  const CreateTaskPage({
    super.key,
    this.task,
    this.parentTaskId,
    this.noPadding = true,
  });

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  late final TaskController _controller;
  late final SupabaseService _supabaseService;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TaskController>();
    _supabaseService = locator.get<SupabaseService>();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    final isSubtask = widget.parentTaskId != null;

    String title;
    if (isEdit) {
      title = 'Edit Task';
    } else if (isSubtask) {
      title = 'Create Subtask';
    } else {
      title = 'Create Task';
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TaskManagementDialog(
            task: widget.task,
            userId: _supabaseService.userId!,
            parentTaskId: widget.parentTaskId,
            onSave: (taskData) async {
              try {
                if (isEdit) {
                  await _controller.updateTask(taskData);
                } else {
                  await _controller.createTask(taskData);
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? 'Task updated successfully'
                            : isSubtask
                            ? 'Subtask created successfully'
                            : 'Task created successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
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
            onDelete: isEdit
                ? () async {
                    try {
                      await _controller.deleteTask(widget.task!.id!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
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
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
