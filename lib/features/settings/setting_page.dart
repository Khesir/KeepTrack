import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<SettingsController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AsyncStreamBuilder<AppSettings>(
        state: _controller,
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(
          child: Text('Error loading settings: $message'),
        ),
        builder: (context, settings) {
          return ListView(
            children: [
              // Appearance Section
              _buildSectionHeader('Appearance'),
              ListTile(
                leading: Icon(settings.themeMode.icon),
                title: const Text('Theme Mode'),
                subtitle: Text(settings.themeMode.displayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeModeDialog(context, settings.themeMode),
              ),

              const Divider(),

              // Currency Section
              _buildSectionHeader('Regional'),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Currency'),
                subtitle: Text(
                  '${settings.currency.displayName} (${settings.currency.symbol})',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCurrencyDialog(context, settings.currency),
              ),

              const Divider(),

              // Configuration Section
              _buildSectionHeader('Management'),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuration'),
                subtitle: const Text(
                  'Manage accounts, categories, transactions, and goals',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, AppRoutes.settingsConfig),
              ),

              const Divider(),

              // Reset Section
              _buildSectionHeader('Data'),
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.orange),
                title: const Text('Reset to Defaults'),
                subtitle: const Text('Reset all settings to default values'),
                onTap: () => _showResetDialog(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, AppThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              value: mode,
              groupValue: currentMode,
              title: Row(
                children: [
                  Icon(mode.icon, size: 20),
                  const SizedBox(width: 12),
                  Text(mode.displayName),
                ],
              ),
              onChanged: (value) {
                if (value != null) {
                  _controller.updateThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, AppCurrency currentCurrency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppCurrency.values.map((currency) {
            return RadioListTile<AppCurrency>(
              value: currency,
              groupValue: currentCurrency,
              title: Text('${currency.displayName} (${currency.symbol})'),
              subtitle: Text(currency.code),
              onChanged: (value) {
                if (value != null) {
                  _controller.updateCurrency(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text(
          'This will reset all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _controller.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
