import 'package:flutter/material.dart';
import 'package:persona_codex/core/routing/app_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ListTile(
          //   title: const Text('Data & Sync'),
          //   subtitle: const Text('Export, import, and sync your data'),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () => Navigator.pushNamed(context, '/settings/data'),
          // ),
          // ListTile(
          //   title: const Text('Backend / Data'),
          //   subtitle: const Text('Configure backend and data sources'),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => const BackendSettingsPage()),
          //   ),
          // ),
          // ListTile(
          //   title: const Text('Security'),
          //   subtitle: const Text('Change PIN code and secure your app'),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => const SecurityPage()),
          //   ),
          // ),
          ListTile(
            title: const Text('Configuration'),
            subtitle: const Text(
              'Manage accounts, categories, transactions, and goals',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.settingsConfig),
          ),
        ],
      ),
    );
  }
}
