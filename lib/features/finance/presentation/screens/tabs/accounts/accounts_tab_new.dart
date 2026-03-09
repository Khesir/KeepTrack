import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/screens/configuration/accounts/widget/account_management_dialog.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../../state/account_controller.dart';

class AccountsTabNew extends StatefulWidget {
  const AccountsTabNew({super.key});

  @override
  State<AccountsTabNew> createState() => _AccountsTabNewState();
}

class _AccountsTabNewState extends State<AccountsTabNew> {
  late final AccountController _controller;
  late final SupabaseService _supabaseService;
  Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<AccountController>();
    _supabaseService = locator.get<SupabaseService>();
  }

  void _showAccountDialog({Account? account}) {
    showDialog(
      context: context,
      builder: (_) => AccountManagementDialog(
        account: account,
        userId: _supabaseService.userId!,
        onSave: (a) async {
          if (account != null) {
            await _controller.updateAccount(a);
            // Refresh selected account state
            if (_selectedAccount?.id == a.id) {
              setState(() => _selectedAccount = a);
            }
          } else {
            await _controller.createAccount(a);
          }
        },
        onDelete: account != null
            ? () async {
                await _controller.deleteAccount(account.id!);
                setState(() => _selectedAccount = null);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF09090B) : AppColors.backgroundSecondary;

        return Scaffold(
          backgroundColor: isDesktop ? bg : null,
          body: AsyncStreamBuilder<List<Account>>(
            state: _controller,
            builder: (context, accounts) {
              final totalBalance = accounts
                  .where((a) => !a.isArchived)
                  .fold<double>(0, (s, a) => s + a.balance);
              final activeCount = accounts.where((a) => a.isActive && !a.isArchived).length;
              final archivedCount = accounts.where((a) => a.isArchived).length;

              if (isDesktop) {
                return _DesktopLayout(
                  accounts: accounts,
                  totalBalance: totalBalance,
                  activeCount: activeCount,
                  archivedCount: archivedCount,
                  selectedAccount: _selectedAccount,
                  onSelect: (a) => setState(() => _selectedAccount = a),
                  onAdd: () => _showAccountDialog(),
                  onEdit: (a) => _showAccountDialog(account: a),
                );
              }

              // Mobile: if an account is selected, show detail; else show list
              if (_selectedAccount != null) {
                return _MobileDetailView(
                  account: _selectedAccount!,
                  onBack: () => setState(() => _selectedAccount = null),
                  onEdit: () => _showAccountDialog(account: _selectedAccount),
                );
              }

              return _MobileListView(
                accounts: accounts,
                totalBalance: totalBalance,
                activeCount: activeCount,
                archivedCount: archivedCount,
                onSelect: (a) => setState(() => _selectedAccount = a),
                onAdd: () => _showAccountDialog(),
              );
            },
            loadingBuilder: (_) => const Center(
              child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()),
            ),
            errorBuilder: (context, message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Failed to load accounts', style: AppTextStyles.h4),
                    const SizedBox(height: 6),
                    Text(message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _controller.loadAccounts(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Desktop Layout ────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final List<Account> accounts;
  final double totalBalance;
  final int activeCount;
  final int archivedCount;
  final Account? selectedAccount;
  final ValueChanged<Account> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<Account> onEdit;

  const _DesktopLayout({
    required this.accounts,
    required this.totalBalance,
    required this.activeCount,
    required this.archivedCount,
    required this.selectedAccount,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final panelBg = isDark ? const Color(0xFF18181B) : AppColors.surface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel — account list (fixed width)
        SizedBox(
          width: 320,
          child: Container(
            decoration: BoxDecoration(
              color: panelBg,
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Accounts', style: AppTextStyles.h4),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'Add Account',
                        onPressed: onAdd,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                          foregroundColor: AppColors.accent,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Summary chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormatter.format(totalBalance, decimalDigits: 2),
                        style: AppTextStyles.h2,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _Chip(label: '$activeCount active', color: AppColors.success),
                          if (archivedCount > 0)
                            _Chip(label: '$archivedCount archived', color: AppColors.textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: borderColor),

                // Account list
                Expanded(
                  child: accounts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined,
                                  size: 40, color: AppColors.textDisabled),
                              const SizedBox(height: 8),
                              Text('No accounts',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: accounts.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                          itemBuilder: (context, i) {
                            final a = accounts[i];
                            final isSelected = selectedAccount?.id == a.id;
                            return _AccountListRow(
                              account: a,
                              isSelected: isSelected,
                              onTap: () => onSelect(a),
                              onEdit: () => onEdit(a),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // Right panel — detail
        Expanded(
          child: selectedAccount == null
              ? _EmptyDetailPanel()
              : _AccountDetailPanel(account: selectedAccount!, onEdit: () => onEdit(selectedAccount!)),
        ),
      ],
    );
  }
}

// ─── Mobile List View ──────────────────────────────────────────────────────────

class _MobileListView extends StatelessWidget {
  final List<Account> accounts;
  final double totalBalance;
  final int activeCount;
  final int archivedCount;
  final ValueChanged<Account> onSelect;
  final VoidCallback onAdd;

  const _MobileListView({
    required this.accounts,
    required this.totalBalance,
    required this.activeCount,
    required this.archivedCount,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final cardBg = isDark ? const Color(0xFF18181B) : AppColors.surface;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Total Balance',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(currencyFormatter.format(totalBalance, decimalDigits: 2),
                        style: AppTextStyles.display),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: [
                        _Chip(label: '$activeCount active', color: AppColors.success),
                        if (archivedCount > 0)
                          _Chip(label: '$archivedCount archived', color: AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Accounts', style: AppTextStyles.h4),
                  Text('${accounts.length} total',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),

              if (accounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            size: 48, color: AppColors.textDisabled),
                        const SizedBox(height: 10),
                        Text('No accounts yet',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Tap + to add your first account',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < accounts.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: borderColor),
                        _AccountListRow(
                          account: accounts[i],
                          isSelected: false,
                          onTap: () => onSelect(accounts[i]),
                          onEdit: null, // mobile: tap goes to detail, edit from there
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),

        // FAB
        Positioned(
          bottom: 20,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Account'),
          ),
        ),
      ],
    );
  }
}

// ─── Mobile Detail View ────────────────────────────────────────────────────────

class _MobileDetailView extends StatelessWidget {
  final Account account;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const _MobileDetailView({required this.account, required this.onBack, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App-bar-like header
        _DetailHeader(account: account, onBack: onBack, onEdit: onEdit),
        Expanded(child: _AccountDetailContent(account: account)),
      ],
    );
  }
}

// ─── Desktop Detail Panel ──────────────────────────────────────────────────────

class _AccountDetailPanel extends StatelessWidget {
  final Account account;
  final VoidCallback onEdit;

  const _AccountDetailPanel({required this.account, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DetailHeader(account: account, onBack: null, onEdit: onEdit),
        Expanded(child: _AccountDetailContent(account: account)),
      ],
    );
  }
}

class _EmptyDetailPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text('Select an account', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Detail Header ─────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final Account account;
  final VoidCallback? onBack;
  final VoidCallback onEdit;

  const _DetailHeader({required this.account, required this.onBack, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final color = _parseColor(account.colorHex);
    final icon = IconHelper.fromString(account.iconCodePoint);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                    style: AppTextStyles.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_formatType(account.accountType),
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(account: account),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Content ────────────────────────────────────────────────────────────

class _AccountDetailContent extends StatefulWidget {
  final Account account;
  const _AccountDetailContent({required this.account});

  @override
  State<_AccountDetailContent> createState() => _AccountDetailContentState();
}

class _AccountDetailContentState extends State<_AccountDetailContent> {
  late TransactionController _txController;

  @override
  void initState() {
    super.initState();
    _txController = locator.get<TransactionController>();
    _txController.loadTransactionsByAccount(widget.account.id!);
  }

  @override
  void didUpdateWidget(_AccountDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account.id != widget.account.id) {
      _txController = locator.get<TransactionController>();
      _txController.loadTransactionsByAccount(widget.account.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final cardBg = isDark ? const Color(0xFF18181B) : AppColors.surface;
    final color = _parseColor(widget.account.colorHex);

    return AsyncStreamBuilder<List<Transaction>>(
      state: _txController,
      loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, msg) => Center(
        child: Text(msg, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ),
      builder: (context, allTx) {
        final transactions = allTx
            .where((t) => t.accountId == widget.account.id || t.toAccountId == widget.account.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        double totalIncome = 0, totalExpense = 0, totalTransfer = 0;
        for (final t in transactions) {
          switch (t.type) {
            case TransactionType.income:
              totalIncome += t.amount;
            case TransactionType.expense:
              totalExpense += t.amount;
            case TransactionType.transfer:
              totalTransfer += t.amount;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Balance',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormatter.format(widget.account.balance, decimalDigits: 2),
                            style: AppTextStyles.display.copyWith(color: color),
                          ),
                          if (widget.account.bankAccountNumber != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.account_balance_outlined,
                                    size: 13, color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text(widget.account.bankAccountNumber!,
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.textTertiary)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Income',
                      amount: totalIncome,
                      color: AppColors.success,
                      icon: Icons.arrow_downward_rounded,
                      borderColor: borderColor,
                      cardBg: cardBg,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Expense',
                      amount: totalExpense,
                      color: AppColors.error,
                      icon: Icons.arrow_upward_rounded,
                      borderColor: borderColor,
                      cardBg: cardBg,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Transfer',
                      amount: totalTransfer,
                      color: AppColors.info,
                      icon: Icons.swap_horiz_rounded,
                      borderColor: borderColor,
                      cardBg: cardBg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transactions', style: AppTextStyles.h4),
                  Text('${transactions.length} total',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),

              if (transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 40, color: AppColors.textDisabled),
                        const SizedBox(height: 8),
                        Text('No transactions yet',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < transactions.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: borderColor),
                        _TransactionRow(
                            transaction: transactions[i],
                            accountId: widget.account.id!),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Account List Row ──────────────────────────────────────────────────────────

class _AccountListRow extends StatelessWidget {
  final Account account;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _AccountListRow({
    required this.account,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(account.colorHex);
    final icon = IconHelper.fromString(account.iconCodePoint);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.accent.withValues(alpha: 0.04);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? selectedBg : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),

            // Icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 10),

            // Name + type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(_formatType(account.accountType),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),

            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(account.balance, decimalDigits: 2),
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                if (account.isArchived)
                  Text('Archived',
                      style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
              ],
            ),

            if (onEdit != null) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                color: AppColors.textTertiary,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: onEdit,
              ),
            ] else
              const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final Color borderColor;
  final Color cardBg;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.borderColor,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currencyFormatter.formatCompact(amount),
            style: AppTextStyles.h4.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Transaction Row ───────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final String accountId;

  const _TransactionRow({required this.transaction, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final (color, icon, prefix) = switch (transaction.type) {
      TransactionType.income => (AppColors.success, Icons.arrow_downward_rounded, '+'),
      TransactionType.expense => (AppColors.error, Icons.arrow_upward_rounded, '-'),
      TransactionType.transfer => (
          AppColors.info,
          Icons.swap_horiz_rounded,
          transaction.accountId == accountId ? '-' : '+',
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? transaction.type.displayName,
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM d, yyyy · h:mm a').format(transaction.date),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$prefix${currencyFormatter.format(transaction.amount, decimalDigits: 2)}',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chips & Badges ────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Account account;
  const _StatusBadge({required this.account});

  @override
  Widget build(BuildContext context) {
    if (account.isArchived) return _Chip(label: 'Archived', color: AppColors.warning);
    if (!account.isActive) return _Chip(label: 'Inactive', color: AppColors.textSecondary);
    return _Chip(label: 'Active', color: AppColors.success);
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

Color _parseColor(String? hex) {
  if (hex == null) return AppColors.accent;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xff')));
  } catch (_) {
    return AppColors.accent;
  }
}

String _formatType(dynamic accountType) {
  return accountType
      .toString()
      .split('.')
      .last
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
      .trim();
}
