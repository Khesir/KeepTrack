import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import '../../../state/account_controller.dart';

/// Accounts Tab with Card Design
class AccountsTabNew extends StatefulWidget {
  const AccountsTabNew({super.key});

  @override
  State<AccountsTabNew> createState() => _AccountsTabNewState();
}

class _AccountsTabNewState extends State<AccountsTabNew> {
  late final AccountController _controller;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<AccountController>();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final desktopBg = isDark ? const Color(0xFF09090B) : AppColors.backgroundSecondary;

        return Scaffold(
          backgroundColor: isDesktop ? desktopBg : null,
          body: AsyncStreamBuilder<List<Account>>(
            state: _controller,
            builder: (context, accounts) {
              // Calculate total balance
              final totalBalance = accounts.fold<double>(
                0,
                (sum, account) => sum + account.balance,
              );

              return SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1400 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Balance Summary Card
                        _buildTotalBalanceCard(
                          totalBalance,
                          accounts.length,
                          isDesktop,
                        ),
                        SizedBox(height: isDesktop ? AppSpacing.xl : 24),

                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Accounts',
                              style: isDesktop
                                  ? AppTextStyles.h2
                                  : Theme.of(context).textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${accounts.length} account${accounts.length != 1 ? 's' : ''}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isDesktop ? AppSpacing.lg : 16),

                        // Empty State or Accounts List
                        if (accounts.isEmpty)
                          _buildEmptyState()
                        else if (isDesktop)
                          _buildDesktopGrid(accounts)
                        else
                          _buildMobileList(accounts),
                      ],
                    ),
                  ),
                ),
              );
            },
            loadingBuilder: (_) => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            errorBuilder: (context, message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading accounts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _controller.loadAccounts(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, '/account-management');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Manage Accounts'),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No accounts yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first account to get started',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList(List<Account> accounts) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAccountCard(account),
        );
      },
    );
  }

  Widget _buildDesktopGrid(List<Account> accounts) {
    return ResponsiveGrid(
      spacing: AppSpacing.lg,
      mobileChildAspectRatio: 1.8,
      desktopChildAspectRatio: 1.8,
      children: accounts.map((account) => _buildAccountCard(account)).toList(),
    );
  }

  Widget _buildTotalBalanceCard(
    double totalBalance,
    int accountCount,
    bool isDesktop,
  ) {
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Total Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              NumberFormat.currency(
                symbol: currencyFormatter.currencySymbol,
                decimalDigits: 2,
              ).format(totalBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              accountCount == 0
                  ? 'No accounts'
                  : 'Across $accountCount account${accountCount != 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    // Parse color and icon from account
    final accountColor = account.colorHex != null
        ? Color(int.parse(account.colorHex!.replaceFirst('#', '0xff')))
        : Colors.blue[700]!;

    final accountIcon = IconHelper.fromString(account.iconCodePoint);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to account detail or show edit dialog
          // You can implement navigation here
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Account Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accountColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(accountIcon, color: accountColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.accountType.toString().split('.').last,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: account.isActive
                          ? Colors.green[50]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      account.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: account.isActive
                            ? Colors.green[700]
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current Balance',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(
                      symbol: currencyFormatter.currencySymbol,
                      decimalDigits: 2,
                    ).format(account.balance),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: accountColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bottom row - Bank Account Number and Archived badge
              Row(
                children: [
                  // Bank Account Number (if available)
                  if (account.bankAccountNumber != null)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance,
                            size: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              account.bankAccountNumber!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Spacer(),

                  // Archived badge
                  if (account.isArchived) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.archive,
                            size: 11,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Archived',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
