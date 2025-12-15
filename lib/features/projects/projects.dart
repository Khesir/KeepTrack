/// Project Management Feature
///
/// Barrel export for the projects feature
library;

// Domain
export 'domain/entities/project.dart';
export 'domain/repositories/project_repository.dart';

// Data
export 'data/models/project_model.dart';
export 'data/datasources/project_datasource.dart';
export 'data/datasources/supabase/project_datasource_supabase.dart';
export 'data/repositories/project_repository_impl.dart';

// Presentation
export 'presentation/screens/project_list_screen.dart';
export 'presentation/screens/project_detail_screen.dart';

// DI Setup
export 'projects_di.dart';
