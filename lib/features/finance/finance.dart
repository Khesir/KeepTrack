/// Budget Management Feature
///
/// Barrel export for the budget feature
library;

// Domain
export 'modules/budget/domain/entities/budget.dart';
export 'modules/budget/domain/entities/budget_category.dart';
// BudgetRecord is deprecated - use Transaction instead
// export 'domain/entities/budget_record.dart';
export 'modules/budget/domain/repositories/budget_repository.dart';

// Data
export 'modules/budget/data/models/budget_model.dart';
export 'modules/budget/data/models/budget_category_model.dart';
// BudgetRecordModel is deprecated - use TransactionModel instead
// export 'data/models/budget_record_model.dart';
export 'modules/budget/data/datasources/budget_datasource.dart';
export 'modules/budget/data/repositories/budget_repository_impl.dart';

// Presentation
export 'presentation/screens/budget_list_screen.dart';
export 'presentation/screens/budget_detail_screen.dart';
export 'presentation/screens/create_budget_screen.dart';

// DI Setup
export 'finance_di.dart';
