/// Task Management Feature
///
/// Barrel export for the tasks feature
library;

// Domain
export 'modules/tasks/domain/entities/task.dart';
export 'modules/projects/domain/entities/project.dart';
export 'modules/tasks/domain/repositories/task_repository.dart';
export 'modules/projects/domain/repositories/project_repository.dart';

// Data
export 'modules/tasks/data/models/task_model.dart';
export 'modules/tasks/data/datasources/task_datasource.dart';
export 'modules/tasks/data/datasources/mongodb/task_datasource_supabase.dart';
export 'modules/tasks/data/repositories/task_repository_impl.dart';
export 'modules/projects/data/datasources/supabase/project_datasource_supabase.dart';
export 'modules/projects/data/datasources/project_datasource.dart';
export 'modules/projects/data/repositories/project_repository_impl.dart';
export 'modules/projects/data/models/project_model.dart';

// DI Setup
export 'tasks_di.dart';
