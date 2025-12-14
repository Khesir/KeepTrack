/// Budget Management Feature
///
/// Barrel export for the budget feature
library;

// Domain
export 'domain/entities/budget.dart';
export 'domain/entities/budget_category.dart';
export 'domain/entities/budget_record.dart';
export 'domain/repositories/budget_repository.dart';

// Data
export 'data/models/budget_model.dart';
export 'data/models/budget_category_model.dart';
export 'data/models/budget_record_model.dart';
export 'data/datasources/budget_datasource.dart';
export 'data/repositories/budget_repository_impl.dart';

// Presentation
export 'presentation/screens/budget_list_screen.dart';
export 'presentation/screens/budget_detail_screen.dart';
export 'presentation/screens/create_budget_screen.dart';

// DI Setup
export 'budget_di.dart';
