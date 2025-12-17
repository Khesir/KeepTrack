import 'package:flutter/material.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';

class AppConfigurationPage extends StatelessWidget {
  const AppConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GCashColors.background,
      appBar: AppBar(title: const Text('Configuration')),
      body: ListView(
        padding: GCashSpacing.screenPadding,
        children: [
          const SizedBox(height: 8),
          _buildSection(context, 'Financial Management', [
            _buildTile(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Manage Wallets',
              subtitle: 'Add, edit, and delete wallets',
              color: GCashColors.primary,
              onTap: () => Navigator.pushNamed(context, '/wallet-management'),
            ),
            _buildTile(
              context,
              icon: Icons.category,
              title: 'Manage Categories',
              subtitle: 'Organize income and expense categories',
              color: GCashColors.info,
              onTap: () => Navigator.pushNamed(context, '/category-management'),
            ),
            _buildTile(
              context,
              icon: Icons.account_balance,
              title: 'Manage Budgets',
              subtitle: 'Create and track monthly budgets',
              color: GCashColors.success,
              onTap: () => Navigator.pushNamed(context, '/budget-management'),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection(context, 'Task Management', [
            _buildTile(
              context,
              icon: Icons.toggle_on,
              title: 'Manage Task Statuses',
              subtitle: 'Define custom task statuses (e.g., To Do, In Progress)',
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/task-status-management'),
            ),
            _buildTile(
              context,
              icon: Icons.priority_high,
              title: 'Manage Task Priorities',
              subtitle: 'Configure priority levels for tasks',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/task-priority-management'),
            ),
            _buildTile(
              context,
              icon: Icons.label,
              title: 'Manage Task Tags',
              subtitle: 'Create tags to organize and filter tasks',
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/task-tag-management'),
            ),
            _buildTile(
              context,
              icon: Icons.folder_special,
              title: 'Manage Project Templates',
              subtitle: 'Define templates for recurring project types',
              color: Colors.teal,
              onTap: () => Navigator.pushNamed(context, '/project-template-management'),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection(context, 'Quick Actions', [
            _buildTile(
              context,
              icon: Icons.add_circle,
              title: 'Create Transaction',
              subtitle: 'Add income, expense, or transfer',
              color: GCashColors.warning,
              onTap: () => Navigator.pushNamed(context, '/create'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: GCashTextStyles.h3),
        ),
        ...tiles,
      ],
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GCashTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GCashTextStyles.bodySmall.copyWith(
                          color: GCashColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: GCashColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
