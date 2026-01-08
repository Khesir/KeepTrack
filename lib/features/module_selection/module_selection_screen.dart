import 'package:flutter/material.dart';

/// Netflix-style module selection screen after login
/// Users can choose between Task Management and Finance Management
class ModuleSelectionScreen extends StatelessWidget {
  const ModuleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.dashboard,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Personal Codex',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your workspace',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Module Cards
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive layout
                        final isWideScreen = constraints.maxWidth > 600;

                        if (isWideScreen) {
                          // Side by side for tablets/desktop
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: _ModuleCard(
                                  title: 'Task Management',
                                  description: 'Manage tasks, projects, and pomodoro sessions',
                                  icon: Icons.task_alt,
                                  color: Colors.blue,
                                  onTap: () => _navigateToTaskModule(context),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Flexible(
                                child: _ModuleCard(
                                  title: 'Finance Management',
                                  description: 'Track accounts, budgets, and transactions',
                                  icon: Icons.account_balance_wallet,
                                  color: Colors.green,
                                  onTap: () => _navigateToFinanceModule(context),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Stacked for mobile
                          return Column(
                            children: [
                              _ModuleCard(
                                title: 'Task Management',
                                description: 'Manage tasks, projects, and pomodoro sessions',
                                icon: Icons.task_alt,
                                color: Colors.blue,
                                onTap: () => _navigateToTaskModule(context),
                              ),
                              const SizedBox(height: 24),
                              _ModuleCard(
                                title: 'Finance Management',
                                description: 'Track accounts, budgets, and transactions',
                                icon: Icons.account_balance_wallet,
                                color: Colors.green,
                                onTap: () => _navigateToFinanceModule(context),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTaskModule(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/task-module');
  }

  void _navigateToFinanceModule(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/finance-module');
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Arrow indicator
                Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
