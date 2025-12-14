/// Task Management Feature
///
/// Barrel export for the tasks feature
library;

// Domain
export 'domain/entities/task.dart';
export '../projects/domain/entities/project.dart';
export 'domain/repositories/task_repository.dart';
export '../projects/domain/repositories/project_repository.dart';

// Data
export 'data/models/task_model.dart';
export 'data/datasources/task_datasource.dart';
export 'data/datasources/mongodb/task_datasource_supabase.dart';
export 'data/repositories/task_repository_impl.dart';

// Presentation
export 'presentation/screens/task_list_screen.dart';
export 'presentation/screens/task_detail_screen.dart';
export '../projects/presentation/project_list_screen.dart';
export '../projects/presentation/project_detail_screen.dart';

// DI Setup
export 'tasks_di.dart';
