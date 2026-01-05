/// App routing configuration
/// Uses named routes for better organization and maintainability
library;

import 'package:flutter/material.dart';
import 'package:keep_track/features/settings/setting_page.dart';
import 'package:keep_track/features/tasks/presentation/screens/configuration/project_management_screen.dart';
import 'package:keep_track/features/tasks/presentation/screens/configuration/task_management_screen.dart';
import '../../features/finance/modules/budget/domain/entities/budget.dart';
import '../../features/finance/modules/transaction/domain/entities/transaction.dart';
import '../../features/finance/presentation/screens/configuration/accounts/account_management.dart';
import '../../features/finance/presentation/screens/configuration/budgets/budget_management_screen.dart';
import '../../features/finance/presentation/screens/configuration/budgets/create_budget_screen.dart';
import '../../features/finance/presentation/screens/configuration/budgets/budget_detail_screen.dart';
import '../../features/finance/presentation/screens/configuration/categories/category_management_screen.dart';
import '../../features/finance/presentation/screens/configuration/goals/goals_management_screen.dart';
import '../../features/finance/presentation/screens/configuration/debts/debts_management_screen.dart';
import '../../features/finance/presentation/screens/configuration/planned_payments/planned_payments_management_screen.dart';
import '../../features/finance/presentation/screens/transactions/create_transaction_screen.dart';
import '../../features/finance/presentation/screens/transactions/create_transfer_transaction_screen.dart';
import '../../features/finance/presentation/screens/finance_main_screen.dart';
import '../../features/settings/subpages/app_configuration_page.dart';
import '../../features/tasks/modules/tasks/domain/entities/task.dart';
import '../../features/tasks/presentation/screens/tasks_main_screen.dart';

import '../../features/tasks/modules/projects/domain/entities/project.dart';

/// App routes
class AppRoutes {
  // Home
  static const String home = '/';

  // Tasks
  static const String taskList = '/tasks';
  static const String taskDetail = '/tasks/detail';
  static const String taskCreate = '/tasks/create';

  // Projects
  static const String projectList = '/projects';
  static const String projectDetail = '/projects/detail';
  // Note: projectCreate not implemented - uses dialog in ProjectListScreen
  // static const String projectCreate = '/projects/create';

  // Budget
  static const String budgetList = '/budget';
  static const String budgetDetail = '/budget/detail';
  static const String budgetCreate = '/budget/create';
  static const String budgetEdit = '/budget/edit';

  // Settings
  static const String settings = '/settings';
  static const String settingsConfig = '/settings/config';

  // Task Management Settings
  static const String taskManagement = '/task-management';
  static const String projectManagement = '/project-management';

  // Finance Management
  static const String accountManagement = '/account-management';
  static const String categoryManagement = '/category-management';
  static const String budgetManagement = '/budget-management';
  static const String goalsManagement = '/goals-management';
  static const String debtsManagement = '/debts-management';
  static const String plannedPaymentsManagement =
      '/planned-payments-management';

  // Transaction
  static const String transactionCreate = '/create';
  static const String transferCreate = '/transfer/create';
}

/// App router - handles all route generation
/// Note: Home route is handled by MaterialApp's `home` parameter
class AppRouter {
  /// Generate routes based on route settings
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Tasks
      case AppRoutes.taskList:
        return MaterialPageRoute(
          builder: (_) => const TasksMainScreen(),
          settings: settings,
        );
      case AppRoutes.taskCreate:
        // Redirect to task management screen for task creation
        return MaterialPageRoute(
          builder: (_) => const TaskManagementScreen(),
          settings: settings,
        );
      case AppRoutes.taskManagement:
        return MaterialPageRoute(
          builder: (_) => const TaskManagementScreen(),
          settings: settings,
        );
      case AppRoutes.projectManagement:
        return MaterialPageRoute(
          builder: (_) => const ProjectManagementScreen(),
          settings: settings,
        );

      // Budget
      case AppRoutes.budgetList:
        return MaterialPageRoute(
          builder: (_) => const FinanceMainScreen(),
          settings: settings,
        );

      // Settings
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
          settings: settings,
        );
      case AppRoutes.settingsConfig:
        return MaterialPageRoute(
          builder: (_) => const AppConfigurationPage(),
          settings: settings,
        );

      // Budget detail (view/edit existing budget)
      case AppRoutes.budgetDetail:
        final budget = settings.arguments as Budget?;
        if (budget == null) {
          return MaterialPageRoute(
            builder: (_) => UnknownRouteScreen(routeName: settings.name ?? ''),
          );
        }
        return MaterialPageRoute(
          builder: (_) => BudgetDetailScreen(budget: budget),
          settings: settings,
        );

      // Budget create (new budget)
      case AppRoutes.budgetCreate:
        return MaterialPageRoute(
          builder: (_) => const CreateBudgetScreen(),
          settings: settings,
        );

      // Budget edit (edit existing budget)
      case AppRoutes.budgetEdit:
        final budget = settings.arguments as Budget?;
        if (budget == null) {
          return MaterialPageRoute(
            builder: (_) => UnknownRouteScreen(routeName: settings.name ?? ''),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CreateBudgetScreen(existingBudget: budget),
          settings: settings,
        );

      // Finance Management
      case AppRoutes.accountManagement:
        return MaterialPageRoute(
          builder: (_) => const AccountManagementScreen(),
          settings: settings,
        );
      case AppRoutes.categoryManagement:
        return MaterialPageRoute(
          builder: (_) => const CategoryManagementScreen(),
          settings: settings,
        );
      case AppRoutes.budgetManagement:
        return MaterialPageRoute(
          builder: (_) => const BudgetManagementScreen(),
          settings: settings,
        );
      case AppRoutes.goalsManagement:
        return MaterialPageRoute(
          builder: (_) => const GoalsManagementScreen(),
          settings: settings,
        );
      case AppRoutes.debtsManagement:
        return MaterialPageRoute(
          builder: (_) => const DebtsManagementScreen(),
          settings: settings,
        );
      case AppRoutes.plannedPaymentsManagement:
        return MaterialPageRoute(
          builder: (_) => const PlannedPaymentsManagementScreen(),
          settings: settings,
        );

      // Transaction
      case AppRoutes.transactionCreate:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CreateTransactionScreen(
            initialDescription: args?['initialDescription'] as String?,
            initialAmount: args?['initialAmount'] as double?,
            initialCategoryId: args?['initialCategoryId'] as String?,
            initialAccountId: args?['initialAccountId'] as String?,
            initialType: args?['initialType'] as TransactionType?,
          ),
          settings: settings,
        );

      case AppRoutes.transferCreate:
        return MaterialPageRoute(
          builder: (_) => const CreateTransferTransactionScreen(),
          settings: settings,
        );

      // Unknown route
      default:
        return MaterialPageRoute(
          builder: (_) => UnknownRouteScreen(routeName: settings.name ?? ''),
        );
    }
  }

  /// Navigate to route by name
  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Replace current route
  static Future<T?> replace<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, Object?>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Pop until root
  static void popUntilRoot(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  /// Pop with result
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }
}

/// Helper extensions for easier navigation
extension NavigationExtensions on BuildContext {
  // Tasks
  Future<void> goToTaskList() {
    return AppRouter.push(this, AppRoutes.taskList);
  }

  Future<void> goToTaskDetail(Task task) {
    return AppRouter.push(this, AppRoutes.taskDetail, arguments: task);
  }

  Future<void> goToTaskCreate({String? initialProjectId}) {
    return AppRouter.push(
      this,
      AppRoutes.taskCreate,
      arguments: initialProjectId != null
          ? {'initialProjectId': initialProjectId}
          : null,
    );
  }

  // Projects
  Future<void> goToProjectList() {
    return AppRouter.push(this, AppRoutes.projectList);
  }

  Future<void> goToProjectDetail(Project project) {
    return AppRouter.push(this, AppRoutes.projectDetail, arguments: project);
  }

  // Note: goToProjectCreate() not implemented - uses dialog in ProjectListScreen
  // Future<void> goToProjectCreate() {
  //   return AppRouter.push(this, AppRoutes.projectCreate);
  // }

  // Budget
  Future<void> goToBudgetList() {
    return AppRouter.push(this, AppRoutes.budgetList);
  }

  Future<void> goToBudgetDetail(Budget budget) {
    return AppRouter.push(this, AppRoutes.budgetDetail, arguments: budget);
  }

  Future<void> goToBudgetCreate() {
    return AppRouter.push(this, AppRoutes.budgetCreate);
  }

  // Transaction
  Future<void> goToTransactionCreate({
    String? initialDescription,
    double? initialAmount,
    String? initialCategoryId,
    String? initialAccountId,
    TransactionType? initialType,
  }) {
    return AppRouter.push(
      this,
      AppRoutes.transactionCreate,
      arguments: {
        if (initialDescription != null)
          'initialDescription': initialDescription,
        if (initialAmount != null) 'initialAmount': initialAmount,
        if (initialCategoryId != null) 'initialCategoryId': initialCategoryId,
        if (initialAccountId != null) 'initialAccountId': initialAccountId,
        if (initialType != null) 'initialType': initialType,
      },
    );
  }

  // Generic
  void goBack<T>([T? result]) {
    AppRouter.pop(this, result);
  }
}

/// Unknown route screen
class UnknownRouteScreen extends StatelessWidget {
  final String routeName;

  const UnknownRouteScreen({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Route: $routeName',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.goBack(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
