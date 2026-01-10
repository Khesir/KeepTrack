import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/screens/configuration/widgets/task_management_dialog.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

class CreateTaskPage extends StatefulWidget {
  final String? parentTaskId;

  const CreateTaskPage({super.key, this.parentTaskId});

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parentTaskId != null ? 'Create Subtask' : 'Create Task'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TaskManagementDialog(
            userId: _supabaseService.userId!,
            parentTaskId: widget.parentTaskId,
            onSave: (newTask) async {
              try {
                await _controller.createTask(newTask);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.parentTaskId != null
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
          ),
        ),
      ),
    );
  }
}
