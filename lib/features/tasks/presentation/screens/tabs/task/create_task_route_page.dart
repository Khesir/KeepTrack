import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/task/components/task_form_page.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../../../../modules/projects/domain/entities/project.dart';
import '../../../state/project_controller.dart';

class CreateTaskRoutePage extends StatefulWidget {
  const CreateTaskRoutePage({super.key});

  @override
  State<CreateTaskRoutePage> createState() => _CreateTaskRoutePageState();
}

class _CreateTaskRoutePageState extends State<CreateTaskRoutePage> {
  late final TaskController _controller;
  late final SupabaseService _supabase;
  late final ProjectController _projectController;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TaskController>();
    _supabase = locator.get<SupabaseService>();
    _projectController = locator.get<ProjectController>();

    // Load active projects
    _projectController.loadActiveProjects();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Project>>(
      state: _projectController,
      builder: (context, projects) {
        final activeProjects = projects
            .where((p) => p.status == ProjectStatus.active && !p.isArchived)
            .toList();

        return TaskFormPage(
          userId: _supabase.userId!,
          projects: activeProjects,
          isDialog: false,
          isDialogContent: false,
          onSave: (Task task) async {
            try {
              await _controller.createTask(task);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task created successfully'),
                  backgroundColor: Colors.green,
                ),
              );

              Navigator.pop(context);
            } catch (e) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create task: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }
}
