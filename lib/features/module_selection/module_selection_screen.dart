import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/config/app_info.dart';
import 'package:keep_track/core/services/notification/notification_service.dart';
import 'package:keep_track/core/services/version_checker_service.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/auth/presentation/screens/auth_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Netflix-style module selection screen after login
/// Users can choose between Task Management and Finance Management
class ModuleSelectionScreen extends StatefulWidget {
  const ModuleSelectionScreen({super.key});

  @override
  State<ModuleSelectionScreen> createState() => _ModuleSelectionScreenState();
}

class _ModuleSelectionScreenState extends State<ModuleSelectionScreen> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final result = await VersionCheckerService.instance.checkForUpdates();

    if (!mounted) return;

    if (result.updateAvailable) {
      _showUpdateDialog(result);
    }
  }

  Future<void> _triggerTestNotification() async {
    final notificationService = NotificationService.instance;

    if (!notificationService.isInitialized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification service not initialized'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await notificationService.showNotification(
      id: 99999,
      title: 'Test Notification',
      body: 'This is a test notification from KeepTrack!',
      payload: 'test',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification triggered!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showUpdateDialog(VersionCheckResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.system_update, size: 48, color: Colors.blue),
        title: const Text('Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of KeepTrack is available!',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _buildVersionRow('Current:', result.currentVersion),
            _buildVersionRow('Latest:', result.latestVersion ?? 'Unknown'),
            if (result.releaseNotes != null && result.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'What\'s new:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(
                    result.releaseNotes!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              // Try custom download URL first, fallback to GitHub releases
              final primaryUrl = Uri.parse(AppInfo.downloadUrl);
              final fallbackUrl = Uri.parse(result.releaseUrl ?? AppInfo.releasesUrl);

              if (await canLaunchUrl(primaryUrl)) {
                await launchUrl(primaryUrl, mode: LaunchMode.externalApplication);
              } else if (await canLaunchUrl(fallbackUrl)) {
                await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(String label, String version) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Text(
            version,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

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
                        // Debug notification test button (only in debug mode)
                        if (kDebugMode) ...[
                          IconButton(
                            onPressed: _triggerTestNotification,
                            icon: const Icon(Icons.notifications_active),
                            tooltip: 'Test Notification',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              foregroundColor: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
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
            if (value == 'manage_account') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AuthSettingsScreen(),
                ),
              );
            } else if (value == 'signout') {
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
              value: 'manage_account',
              child: Row(
                children: [
                  Icon(Icons.manage_accounts, size: 18),
                  SizedBox(width: 12),
                  Text('Manage Account'),
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
