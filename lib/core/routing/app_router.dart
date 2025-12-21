/// App routing configuration
/// Uses named routes for better organization and maintainability
library;

import 'package:flutter/material.dart';
import 'package:persona_codex/features/settings/setting_page.dart';
import '../../features/finance/modules/budget/domain/entities/budget.dart';
import '../../features/finance/presentation/screens/configuration/account_management.dart';
import '../../features/finance/presentation/screens/budget_detail_screen.dart';
import '../../features/finance/presentation/screens/budget_list_screen.dart';
import '../../features/finance/presentation/screens/create_budget_screen.dart';
import '../../features/finance/presentation/screens/configuration/category_management_screen.dart';
import '../../features/finance/presentation/screens/configuration/goals_management_screen.dart';
import '../../features/finance/presentation/screens/configuration/debts/debts_management_screen.dart';
import '../../features/finance/presentation/screens/configuration/planned_payments/planned_payments_management_screen.dart';
import '../../features/settings/subpages/app_configuration_page.dart';
import '../../features/settings/management/task_status_management_screen.dart';
import '../../features/settings/management/task_priority_management_screen.dart';
import '../../features/settings/management/task_tag_management_screen.dart';
import '../../features/settings/management/project_template_management_screen.dart';
import '../../features/tasks/presentation/screens/tasks_home_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/tasks/domain/entities/task.dart';

import '../../features/projects/presentation/screens/project_list_screen.dart';
import '../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../features/projects/domain/entities/project.dart';

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

  // Settings
  static const String settings = '/settings';
  static const String settingsConfig = '/settings/config';

  // Task Management Settings
  static const String taskStatusManagement = '/task-status-management';
  static const String taskPriorityManagement = '/task-priority-management';
  static const String taskTagManagement = '/task-tag-management';
  static const String projectTemplateManagement =
      '/project-template-management';

  // Finance Management
  static const String accountManagement = '/account-management';
  static const String categoryManagement = '/category-management';
  static const String budgetManagement = '/budget-management';
  static const String goalsManagement = '/goals-management';
  static const String debtsManagement = '/debts-management';
  static const String plannedPaymentsManagement =
      '/planned-payments-management';
}

/// App router - handles all route generation
/// Note: Home route is handled by MaterialApp's `home` parameter
class AppRouter {
  /// Generate routes based on route settings
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Task list
      case AppRoutes.taskList:
        return MaterialPageRoute(
          builder: (_) => const TasksHomeScreen(),
          settings: settings,
        );

      // Task detail (view/edit existing task)
      case AppRoutes.taskDetail:
        final task = settings.arguments as Task?;
        return MaterialPageRoute(
          builder: (_) => TaskDetailScreen(task: task),
          settings: settings,
        );

      // Task create (new task)
      case AppRoutes.taskCreate:
        // Support optional initialProjectId via arguments
        final args = settings.arguments as Map<String, dynamic>?;
        final initialProjectId = args?['initialProjectId'] as String?;
        return MaterialPageRoute(
          builder: (_) =>
              TaskDetailScreen(task: null, initialProjectId: initialProjectId),
          settings: settings,
        );

      // Budget list
      case AppRoutes.budgetList:
        return MaterialPageRoute(
          builder: (_) => const BudgetListScreen(),
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

      // Project list
      case AppRoutes.projectList:
        return MaterialPageRoute(
          builder: (_) => const ProjectListScreen(),
          settings: settings,
        );

      // Project detail (view/edit existing project)
      case AppRoutes.projectDetail:
        final project = settings.arguments as Project?;
        if (project == null) {
          return MaterialPageRoute(
            builder: (_) => UnknownRouteScreen(routeName: settings.name ?? ''),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(project: project),
          settings: settings,
        );
      // Project list
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

      // Task Management Settings
      case AppRoutes.taskStatusManagement:
        return MaterialPageRoute(
          builder: (_) => const TaskStatusManagementScreen(),
          settings: settings,
        );
      case AppRoutes.taskPriorityManagement:
        return MaterialPageRoute(
          builder: (_) => const TaskPriorityManagementScreen(),
          settings: settings,
        );
      case AppRoutes.taskTagManagement:
        return MaterialPageRoute(
          builder: (_) => const TaskTagManagementScreen(),
          settings: settings,
        );
      case AppRoutes.projectTemplateManagement:
        return MaterialPageRoute(
          builder: (_) => const ProjectTemplateManagementScreen(),
          settings: settings,
        );

      // Finance Management
      case AppRoutes.accountManagement:
        return MaterialPageRoute(
          builder: (_) => const AccountManagement(),
          settings: settings,
        );
      case AppRoutes.categoryManagement:
        return MaterialPageRoute(
          builder: (_) => const CategoryManagementScreen(),
          settings: settings,
        );
      case AppRoutes.budgetManagement:
        return MaterialPageRoute(
          builder: (_) => const BudgetListScreen(),
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
