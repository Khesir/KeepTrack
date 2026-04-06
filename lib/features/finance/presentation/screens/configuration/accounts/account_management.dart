import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../../../state/account_controller.dart';
import 'account_form_screen.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  late final AccountController _controller;
  late final SupabaseService supabaseService;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<AccountController>();
    supabaseService = locator.get<SupabaseService>();
  }

  final _currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  void _showAccountForm({Account? account}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountFormScreen(
          account: account,
          userId: supabaseService.userId!,
          onSave: (updatedAccount) async {
            if (account != null) {
              await _controller.updateAccount(updatedAccount);
            } else {
              await _controller.createAccount(updatedAccount);
            }
          },
          onDelete: account != null
              ? () async => await _controller.deleteAccount(account.id!)
              : null,
        ),
      ),
    );
  }

  /// Build the leading avatar for an account list tile.
  Widget _buildAccountAvatar(Account account) {
    const double radius = 22;

    if (account.imageUrl != null) {
      ImageProvider? imageProvider;
      if (account.imageUrl!.startsWith('data:')) {
        try {
          final base64Str = account.imageUrl!.split(',').last;
          imageProvider = MemoryImage(base64Decode(base64Str));
        } catch (_) {
          imageProvider = null;
        }
      } else {
        imageProvider = NetworkImage(account.imageUrl!);
      }

      if (imageProvider != null) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        );
      }
    }

    // Fallback: icon with color background
    Color? iconColor;
    if (account.colorHex != null) {
      try {
        iconColor = Color(
          int.parse(account.colorHex!.replaceFirst('#', '0xff')),
        );
      } catch (_) {
        iconColor = null;
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: iconColor ?? Theme.of(context).colorScheme.primary,
      child: Icon(
        IconHelper.fromString(account.iconCodePoint),
        color: Colors.white,
        size: 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            onPressed: () => _showAccountForm(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AsyncStreamBuilder<List<Account>>(
        state: _controller,
        builder: (context, accounts) {
          final totalBalance = accounts.fold(0.0, (sum, a) => sum + a.balance);

          return Column(
            children: [
              // Total balance card
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  title: const Text('Total Balance'),
                  subtitle: Text(
                    '${accounts.length} account${accounts.length != 1 ? 's' : ''}',
                  ),
                  trailing: Text(
                    _currencyFormat.format(totalBalance),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              // Accounts list or empty state
              Expanded(
                child: accounts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text('No accounts found.'),
                            SizedBox(height: 8),
                            Text(
                              'Tap + to create your first account',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: _buildAccountAvatar(account),
                              title: Text(account.name),
                              subtitle: Text(account.accountType.name),
                              trailing: Text(
                                _currencyFormat.format(account.balance),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => _showAccountForm(account: account),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loadingBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(child: Text(message)),
      ),
    );
  }
}
