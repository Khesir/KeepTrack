import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/core/utils/icon_helper.dart';
import 'package:persona_codex/features/finance/modules/account/domain/entities/account.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';

import '../../../state/account_controller.dart';
import 'widget/account_management_dialog.dart';

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

  void _showAccountDialog({Account? account}) {
    showDialog(
      context: context,
      builder: (context) => AccountManagementDialog(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            onPressed: () => _showAccountDialog(),
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
              // Total balance card - always shown
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
                              leading: Icon(
                                IconHelper.fromString(account.iconCodePoint),
                                color: account.colorHex != null
                                    ? Color(
                                        int.parse(
                                          account.colorHex!.replaceFirst(
                                            '#',
                                            '0xff',
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(account.name),
                              subtitle: Text(
                                account.accountType.toString().split('.').last,
                              ),
                              trailing: Text(
                                _currencyFormat.format(account.balance),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => _showAccountDialog(account: account),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(child: Text(message)),
      ),
    );
  }
}
