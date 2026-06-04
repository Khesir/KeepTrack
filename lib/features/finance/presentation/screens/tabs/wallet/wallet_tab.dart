import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/screens/configuration/wallet/widget/wallet_management_dialog.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/wallet/wallet_detail_view.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';


class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  late final WalletController _controller;
  late final TransactionController _txController;
  Wallet? _selectedWallet;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<WalletController>();
    _txController = locator.get<TransactionController>();
    _txController.loadAllTransactions();
  }

  void _openCreate(BuildContext context) {
    final userId = locator.get<AuthController>().currentUser?.id ?? '';
    WalletManagementDialog.show(
      context,
      userId: userId,
      onSave: (w) => _controller.createWallet(w),
    );
  }

  void _openEdit(BuildContext context, Wallet wallet) {
    final userId = locator.get<AuthController>().currentUser?.id ?? '';
    WalletManagementDialog.show(
      context,
      wallet: wallet,
      userId: userId,
      onSave: (w) => _controller.updateWallet(w),
      onDelete: () => _controller.deleteWallet(wallet.id!),
    );
  }

  void _openAddEntry(BuildContext context, Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntrySheet(
        wallet: wallet,
        txController: _txController,
        walletController: _controller,
        onDone: () => _txController.loadAllTransactions(),
        onViewHistory: () {
          Navigator.pop(context);
          setState(() => _selectedWallet = wallet);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= ResponsiveBreakpoints.desktop;
        return AsyncStreamBuilder<List<Wallet>>(
          state: _controller,
          loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load wallets', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _controller.loadWallets,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
          builder: (context, wallets) {
            final current = _selectedWallet != null
                ? wallets.where((w) => w.id == _selectedWallet!.id).firstOrNull
                    ?? _selectedWallet!
                : null;

            if (current != null) {
              return WalletDetailView(
                key: ValueKey(current.id),
                wallet: current,
                txController: _txController,
                onBack: () => setState(() => _selectedWallet = null),
                onAddEntry: () => _openAddEntry(context, current),
                onEdit: () => _openEdit(context, current),
              );
            }

            return _buildList(context, wallets, isDesktop);
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<Wallet> wallets, bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const h = 12.0;
    final pad = isDesktop ? 24.0 : 16.0;

    final standardWallets = wallets.where((w) => w.type == WalletType.standard).toList();
    final creditWallets = wallets.where((w) => w.type == WalletType.creditCard).toList();
    final totalBalance = standardWallets.fold(0.0, (s, w) => s + w.balance);
    final totalOwed = creditWallets.fold(0.0, (s, w) => s + w.balance);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _WalletHero(
            totalBalance: totalBalance,
            totalOwed: totalOwed,
            count: wallets.length,
            isDark: isDark,
            onAdd: () => _openCreate(context),
          ),
        ),
        if (wallets.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(onAdd: () => _openCreate(context)),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (standardWallets.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Standard',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: h,
                      runSpacing: h,
                      children: [
                        ...standardWallets.asMap().entries.map((e) {
                          final i = e.key;
                          final w = e.value;
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(w.id),
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 450),
                            curve: Interval(
                              (i * 0.08).clamp(0.0, 0.6),
                              ((i * 0.08) + 0.4).clamp(0.0, 1.0),
                              curve: Curves.easeOut,
                            ),
                            builder: (_, v, child) => Opacity(
                              opacity: v,
                              child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
                            ),
                            child: SizedBox(
                              width: 200,
                              height: 185,
                              child: _WalletCard(
                                wallet: w,
                                isDark: isDark,
                                onTap: () => _openAddEntry(context, w),
                                onEdit: () => _openEdit(context, w),
                                onViewHistory: () => setState(() => _selectedWallet = w),
                              ),
                            ),
                          );
                        }),
                        if (creditWallets.isEmpty)
                          SizedBox(
                            width: 200,
                            height: 185,
                            child: _AddWalletCard(isDark: isDark, onTap: () => _openCreate(context)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (creditWallets.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Credit Cards',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: h,
                      runSpacing: h,
                      children: [
                        ...creditWallets.asMap().entries.map((e) {
                          final i = standardWallets.length + e.key;
                          final w = e.value;
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(w.id),
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 450),
                            curve: Interval(
                              (i * 0.08).clamp(0.0, 0.6),
                              ((i * 0.08) + 0.4).clamp(0.0, 1.0),
                              curve: Curves.easeOut,
                            ),
                            builder: (_, v, child) => Opacity(
                              opacity: v,
                              child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
                            ),
                            child: SizedBox(
                              width: 200,
                              height: 185,
                              child: _WalletCard(
                                wallet: w,
                                isDark: isDark,
                                onTap: () => _openAddEntry(context, w),
                                onEdit: () => _openEdit(context, w),
                                onViewHistory: () => setState(() => _selectedWallet = w),
                              ),
                            ),
                          );
                        }),
                        SizedBox(
                          width: 200,
                          height: 185,
                          child: _AddWalletCard(isDark: isDark, onTap: () => _openCreate(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}


class _WalletHero extends StatelessWidget {
  final double totalBalance;
  final double totalOwed;
  final int count;
  final bool isDark;
  final VoidCallback onAdd;

  const _WalletHero({
    required this.totalBalance,
    required this.totalOwed,
    required this.count,
    required this.isDark,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.18)
        : AppColors.border.withValues(alpha: 0.45);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: totalBalance),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        currencyFormatter.format(v),
                        style: GoogleFonts.dmMono(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          letterSpacing: -0.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '$count wallet${count == 1 ? '' : 's'}',
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary),
                        ),
                        if (totalOwed > 0) ...[
                          Text('  •  ', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
                          Text(
                            '${currencyFormatter.format(totalOwed)} owed',
                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.error),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.account_balance_wallet_outlined, size: 28, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text('No wallets yet', style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text(
            'Create a wallet to track your money',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 15, color: AppColors.accent),
            label: Text(
              'Create your first wallet',
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}


class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onViewHistory;

  const _WalletCard({
    required this.wallet,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onViewHistory,
  });

  Color get _color => wallet.colorHex != null
      ? Color(int.parse(wallet.colorHex!.replaceFirst('#', '0xff')))
      : AppColors.accent;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.12)
        : AppColors.border.withValues(alpha: 0.4);
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final icon = IconHelper.fromString(wallet.iconCodePoint);
    final isCreditCard = wallet.type == WalletType.creditCard;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: _color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(icon, color: _color, size: 18),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.more_horiz, color: AppColors.textTertiary, size: 16),
                            onSelected: (v) {
                              if (v == 'edit') onEdit();
                              if (v == 'history') onViewHistory();
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  const Icon(Icons.edit_outlined, size: 14),
                                  const SizedBox(width: 10),
                                  Text('Edit', style: GoogleFonts.dmSans(fontSize: 13)),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'history',
                                child: Row(children: [
                                  const Icon(Icons.history_rounded, size: 14),
                                  const SizedBox(width: 10),
                                  Text('History', style: GoogleFonts.dmSans(fontSize: 13)),
                                ]),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        currencyFormatter.format(wallet.balance, decimalDigits: 2),
                        style: GoogleFonts.dmMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _color,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wallet.name,
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: fg),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isCreditCard ? Icons.credit_card_outlined : Icons.account_balance_wallet_outlined,
                            size: 10,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            wallet.type.displayName,
                            style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                      if (wallet.labels.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: wallet.labels.take(2).map((label) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _color.withValues(alpha: 0.25), width: 1),
                            ),
                            child: Text(
                              label,
                              style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: _color.withValues(alpha: 0.85)),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _AddWalletCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AddWalletCard({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: AppColors.accent, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'New Wallet',
                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _EntrySheet extends StatelessWidget {
  final Wallet wallet;
  final TransactionController txController;
  final WalletController walletController;
  final VoidCallback onDone;
  final VoidCallback onViewHistory;

  const _EntrySheet({
    required this.wallet,
    required this.txController,
    required this.walletController,
    required this.onDone,
    required this.onViewHistory,
  });

  Color get _color => wallet.colorHex != null
      ? Color(int.parse(wallet.colorHex!.replaceFirst('#', '0xff')))
      : AppColors.accent;

  void _openForm(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionFormSheet(
        wallet: wallet,
        txController: txController,
        walletController: walletController,
        onDone: onDone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.void_ : Colors.white;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.12)
        : AppColors.border.withValues(alpha: 0.35);
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final icon = IconHelper.fromString(wallet.iconCodePoint);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: _color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.name, style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: fg)),
                    Text(currencyFormatter.format(wallet.balance), style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: _color)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ActionTile(
            icon: Icons.swap_vert_rounded,
            iconColor: AppColors.accent,
            title: 'New Transaction',
            subtitle: 'Deposit, withdraw or transfer',
            isDark: isDark,
            borderColor: borderColor,
            onTap: () => _openForm(context),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.history_rounded,
            iconColor: AppColors.textSecondary,
            title: 'View Full History',
            subtitle: 'Browse all past entries',
            isDark: isDark,
            borderColor: borderColor,
            onTap: onViewHistory,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2A2A28) : const Color(0xFFFAFAFA);
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}


class _TransactionFormSheet extends StatefulWidget {
  final Wallet wallet;
  final TransactionController txController;
  final WalletController walletController;
  final VoidCallback onDone;

  const _TransactionFormSheet({
    required this.wallet,
    required this.txController,
    required this.walletController,
    required this.onDone,
  });

  @override
  State<_TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<_TransactionFormSheet> {
  final _amountCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TransactionType _type = TransactionType.income;
  Wallet? _toWallet;
  bool _saving = false;

  double _fromDelta(double amount, double fee) {
    if (widget.wallet.type == WalletType.creditCard) {
      if (_type == TransactionType.income) return -(amount + fee);
      return amount + fee;
    }
    if (_type == TransactionType.income) return amount - fee;
    return -(amount + fee);
  }

  double _toDelta(Wallet toWallet, double amount) {
    return toWallet.type == WalletType.creditCard ? -amount : amount;
  }

  Color get _typeColor {
    switch (_type) {
      case TransactionType.income:
        return AppColors.success;
      case TransactionType.expense:
        return AppColors.error;
      case TransactionType.transfer:
        return AppColors.info;
    }
  }

  bool get _canSave {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return false;
    if (_type == TransactionType.transfer && _toWallet == null) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    if (_type == TransactionType.transfer && _toWallet == null) return;
    final fee = double.tryParse(_feeCtrl.text) ?? 0;
    setState(() => _saving = true);
    try {
      await widget.txController.createTransaction(Transaction(
        amount: amount,
        fee: fee,
        type: _type,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        date: DateTime.now(),
        walletId: widget.wallet.id,
        toWalletId: _type == TransactionType.transfer ? _toWallet!.id : null,
      ));
      // Update source wallet balance (fee always reduces source)
      await widget.walletController.updateWallet(
        widget.wallet.copyWith(balance: widget.wallet.balance + _fromDelta(amount, fee)),
      );
      // Update destination wallet balance for transfers (destination gets amount only, not fee)
      if (_type == TransactionType.transfer && _toWallet != null) {
        final wallets = widget.walletController.wallets;
        final fresh = wallets.where((w) => w.id == _toWallet!.id).firstOrNull ?? _toWallet!;
        await widget.walletController.updateWallet(
          fresh.copyWith(balance: fresh.balance + _toDelta(fresh, amount)),
        );
      }
      widget.onDone();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: $e');
        setState(() => _saving = false);
      }
    }
  }

  String get _confirmLabel {
    switch (_type) {
      case TransactionType.income:
        return 'Confirm Deposit';
      case TransactionType.expense:
        return 'Confirm Withdraw';
      case TransactionType.transfer:
        return 'Confirm Transfer';
    }
  }

  void _showToWalletPicker(BuildContext context, bool isDark) {
    final wallets = (widget.walletController.data ?? [])
        .where((w) => w.id != widget.wallet.id)
        .toList();
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
                child: Row(children: [
                  Text('Transfer To', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ]),
              ),
              Divider(height: 1, color: borderColor),
              if (wallets.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 8),
                    Text('No other wallets', style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Create another wallet to transfer to', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary), textAlign: TextAlign.center),
                  ]),
                )
              else
                ...wallets.map((w) {
                  final isSelected = _toWallet?.id == w.id;
                  final wColor = w.colorHex != null
                      ? Color(int.parse(w.colorHex!.replaceFirst('#', '0xff')))
                      : AppColors.accent;
                  return Column(children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: wColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          w.type == WalletType.creditCard
                              ? Icons.credit_card_outlined
                              : Icons.account_balance_wallet_outlined,
                          size: 20,
                          color: wColor,
                        ),
                      ),
                      title: Text(w.name, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: textPrimary)),
                      subtitle: Text(
                        '${currencyFormatter.format(w.balance, decimalDigits: 2)} • ${w.type.displayName}',
                        style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: isSelected ? Icon(Icons.check_rounded, size: 20, color: AppColors.accent) : null,
                      onTap: () {
                        setState(() => _toWallet = w);
                        Navigator.pop(context);
                      },
                    ),
                    Divider(height: 1, color: borderColor, indent: 20, endIndent: 20),
                  ]);
                }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.void_ : Colors.white;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.15)
        : AppColors.border.withValues(alpha: 0.4);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Text('New Transaction', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
                const Spacer(),
                Text(widget.wallet.name, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 24),
            // Type selector – Deposit / Withdraw / Transfer
            Row(
              children: [
                Expanded(child: _TypeButton(
                  label: 'Deposit',
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.success,
                  selected: _type == TransactionType.income,
                  onTap: () => setState(() { _type = TransactionType.income; _toWallet = null; }),
                )),
                const SizedBox(width: 8),
                Expanded(child: _TypeButton(
                  label: 'Withdraw',
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.error,
                  selected: _type == TransactionType.expense,
                  onTap: () => setState(() { _type = TransactionType.expense; _toWallet = null; }),
                )),
                const SizedBox(width: 8),
                Expanded(child: _TypeButton(
                  label: 'Transfer',
                  icon: Icons.swap_horiz_rounded,
                  color: AppColors.info,
                  selected: _type == TransactionType.transfer,
                  onTap: () => setState(() => _type = TransactionType.transfer),
                )),
              ],
            ),
            // Transfer from/to row
            if (_type == TransactionType.transfer) ...[
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _WalletChip(
                        label: 'From',
                        wallet: widget.wallet,
                        isDark: isDark,
                        borderColor: borderColor,
                        locked: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.info),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showToWalletPicker(context, isDark),
                        child: _WalletChip(
                          label: 'To',
                          wallet: _toWallet,
                          isDark: isDark,
                          borderColor: _toWallet == null
                              ? AppColors.info.withValues(alpha: 0.5)
                              : borderColor,
                          placeholder: 'Select wallet',
                          accentColor: _toWallet == null ? AppColors.info : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: GoogleFonts.dmMono(fontSize: 15, color: fg),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${currencyFormatter.currencySymbol} ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _typeColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.dmMono(fontSize: 15, color: fg),
              decoration: InputDecoration(
                labelText: 'Fee (optional)',
                prefixText: '${currencyFormatter.currencySymbol} ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _typeColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              style: GoogleFonts.dmSans(fontSize: 14, color: fg),
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _typeColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving || !_canSave ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _typeColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_confirmLabel, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _WalletChip extends StatelessWidget {
  final String label;
  final Wallet? wallet;
  final bool isDark;
  final Color borderColor;
  final bool locked;
  final String? placeholder;
  final Color? accentColor;

  const _WalletChip({
    required this.label,
    required this.wallet,
    required this.isDark,
    required this.borderColor,
    this.locked = false,
    this.placeholder,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2A2A28) : const Color(0xFFF8F8F8);
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final accent = accentColor ?? AppColors.accent;
    final wColor = wallet?.colorHex != null
        ? Color(int.parse(wallet!.colorHex!.replaceFirst('#', '0xff')))
        : accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          if (wallet != null) ...[
            Row(
              children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: wColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    wallet!.type == WalletType.creditCard
                        ? Icons.credit_card_outlined
                        : Icons.account_balance_wallet_outlined,
                    size: 12,
                    color: wColor,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    wallet!.name,
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (locked)
                  Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textTertiary),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(placeholder ?? 'Select', style: GoogleFonts.dmSans(fontSize: 13, color: accent)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : (isDark ? const Color(0xFF2A2A28) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? color : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
