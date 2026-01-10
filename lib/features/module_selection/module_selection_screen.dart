import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';

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
              // Header with profile
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // User profile in top right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildUserProfile(context),
                      ],
                    ),
                    const SizedBox(height: 16),
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

  Widget _buildUserProfile(BuildContext context) {
    final authController = locator.get<AuthController>();
    final user = authController.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        return PopupMenuButton<String>(
          tooltip: 'Account options',
          offset: const Offset(0, 8),
          constraints: BoxConstraints(
            minWidth: 200,
            maxWidth: 200,
          ),
          onSelected: (value) async {
            if (value == 'signout') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await authController.signOut();
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 16),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'signout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Sign Out', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                if (user?.photoUrl != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(user!.photoUrl!),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          Theme.of(context).colorScheme.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                const SizedBox(width: 8),
                // User name
                Text(
                  user?.displayName ?? 'User',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
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
