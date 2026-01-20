import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/entities/bucket.dart';
import 'package:keep_track/features/tasks/presentation/state/bucket_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/project_controller.dart';
import 'package:keep_track/features/tasks/presentation/screens/configuration/widgets/project_management_dialog.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  late final ProjectController _controller;
  late final BucketController _bucketController;
  late final SupabaseService _supabaseService;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<ProjectController>();
    _bucketController = locator.get<BucketController>();
    _supabaseService = locator.get<SupabaseService>();
    _bucketController.loadBuckets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Project')),
      body: AsyncStreamBuilder<List<Bucket>>(
        state: _bucketController,
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, __) => _buildForm(null),
        builder: (context, buckets) => _buildForm(buckets),
      ),
    );
  }

  Widget _buildForm(List<Bucket>? buckets) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ProjectManagementDialog(
          userId: _supabaseService.userId!,
          buckets: buckets,
          onSave: (newProject) async {
            try {
              await _controller.createProject(newProject);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Project created successfully'),
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
    );
  }
}
