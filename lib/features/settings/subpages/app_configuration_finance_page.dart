import 'package:flutter/material.dart';

class AppConfigurationFinancePage extends StatelessWidget {
  const AppConfigurationFinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _buildSection(context, 'Financial Management', [
            _buildTile(
              context,
              icon: Icons.account_balance_wallet_rounded,
              title: 'Manage Accounts',
              subtitle: 'Add, edit, and delete financial accounts',
              color: Colors.blue,

              onTap: () => Navigator.pushNamed(context, '/account-management'),
            ),
            _buildTile(
              context,
              icon: Icons.pie_chart_rounded,
              title: 'Manage Budgets',
              subtitle: 'Create and track monthly budgets',
              color: Colors.green,

              onTap: () => Navigator.pushNamed(context, '/budget-management'),
            ),
            _buildTile(
              context,
              icon: Icons.category,
              title: 'Manage Categories',
              subtitle: 'Organize income and expense categories',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/category-management'),
            ),
            _buildTile(
              context,
              icon: Icons.flag,
              title: 'Manage Goals',
              subtitle: 'Create and track savings goals',
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/goals-management'),
            ),
            _buildTile(
              context,
              icon: Icons.swap_horiz,
              title: 'Manage Debts',
              subtitle: 'Track lending and borrowing',
              color: Colors.red,
              onTap: () => Navigator.pushNamed(context, '/debts-management'),
            ),
            _buildTile(
              context,
              icon: Icons.event_repeat,
              title: 'Manage Planned Payments',
              subtitle: 'Set up recurring and scheduled payments',
              color: Colors.teal,
              onTap: () =>
                  Navigator.pushNamed(context, '/planned-payments-management'),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection(context, 'Quick Actions', [
            _buildTile(
              context,
              icon: Icons.add_circle,
              title: 'Create Transaction',
              subtitle: 'Add income, expense, or transfer',
              color: Colors.amber,
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
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...tiles,
      ],
    );
  }

  // ignore: unused_element
  Widget _buildEnhancedTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
