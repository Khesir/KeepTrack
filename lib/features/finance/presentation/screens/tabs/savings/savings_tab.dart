import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/screens/configuration/savings/widget/savings_management_dialog.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/savings/savings_bucket_detail_view.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

// ─── Main tab ─────────────────────────────────────────────────────────────────

class SavingsTab extends StatefulWidget {
  const SavingsTab({super.key});

  @override
  State<SavingsTab> createState() => _SavingsTabState();
}

class _SavingsTabState extends State<SavingsTab> {
  late final SavingsController _controller;
  late final TransactionController _txController;
  SavingsBucket? _selectedBucket;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<SavingsController>();
    _txController = locator.get<TransactionController>();
    _txController.loadAllTransactions();
  }

  void _openCreate(BuildContext context) {
    final userId = locator.get<AuthController>().currentUser?.id ?? '';
    showDialog(
      context: context,
      builder: (_) => SavingsManagementDialog(
        userId: userId,
        onSave: (b) => _controller.createSavingsBucket(b),
      ),
    );
  }

  void _openEdit(BuildContext context, SavingsBucket bucket) {
    final userId = locator.get<AuthController>().currentUser?.id ?? '';
    showDialog(
      context: context,
      builder: (_) => SavingsManagementDialog(
        bucket: bucket,
        userId: userId,
        onSave: (b) => _controller.updateSavingsBucket(b),
        onDelete: () => _controller.deleteSavingsBucket(bucket.id!),
      ),
    );
  }

  void _openAddEntry(BuildContext context, SavingsBucket bucket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntrySheet(
        bucket: bucket,
        txController: _txController,
        savingsController: _controller,
        onDone: () => _txController.loadAllTransactions(),
        onViewHistory: () {
          Navigator.pop(context);
          setState(() => _selectedBucket = bucket);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= ResponsiveBreakpoints.desktop;
        return AsyncStreamBuilder<List<SavingsBucket>>(
          state: _controller,
          loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load savings', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _controller.loadSavings,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
          builder: (context, buckets) {
            final total = buckets.fold(0.0, (s, b) => s + b.balance);
            final current = _selectedBucket != null
                ? buckets.where((b) => b.id == _selectedBucket!.id).firstOrNull
                    ?? _selectedBucket!
                : null;

            if (current != null) {
              return SavingsBucketDetailView(
                key: ValueKey(current.id),
                bucket: current,
                txController: _txController,
                onBack: () => setState(() => _selectedBucket = null),
                onAddEntry: () => _openAddEntry(context, current),
                onEdit: () => _openEdit(context, current),
              );
            }

            return _buildList(context, buckets, total, isDesktop);
          },
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<SavingsBucket> buckets,
    double total,
    bool isDesktop,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _SavingsHeader(
                total: total,
                count: buckets.length,
                isDark: isDark,
                isDesktop: isDesktop,
                onAdd: () => _openCreate(context),
              ),
            ),
            if (buckets.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onAdd: () => _openCreate(context)),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 24 : 16,
                  0,
                  isDesktop ? 24 : 16,
                  100,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BucketCard(
                        bucket: buckets[i],
                        isDark: isDark,
                        onTap: () => _openAddEntry(context, buckets[i]),
                        onEdit: () => _openEdit(context, buckets[i]),
                        onViewHistory: () =>
                            setState(() => _selectedBucket = buckets[i]),
                      ),
                    ),
                    childCount: buckets.length,
                  ),
                ),
              ),
          ],
        ),
        if (!isDesktop)
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _openCreate(context),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(
                'New Bucket',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _SavingsHeader extends StatelessWidget {
  final double total;
  final int count;
  final bool isDark;
  final bool isDesktop;
  final VoidCallback onAdd;

  const _SavingsHeader({
    required this.total,
    required this.count,
    required this.isDark,
    required this.isDesktop,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final padding = isDesktop
        ? const EdgeInsets.fromLTRB(24, 28, 24, 20)
        : const EdgeInsets.fromLTRB(16, 24, 16, 16);

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL SAVED',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currencyFormatter.format(total),
                  style: GoogleFonts.dmMono(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count bucket${count == 1 ? '' : 's'}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 15, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'New Bucket',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.savings_outlined,
                size: 28, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text('No savings buckets yet', style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text(
            'Tap a bucket to add a deposit or withdrawal',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 15, color: AppColors.accent),
            label: Text(
              'Create your first bucket',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bucket card ──────────────────────────────────────────────────────────────

class _BucketCard extends StatelessWidget {
  final SavingsBucket bucket;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onViewHistory;

  const _BucketCard({
    required this.bucket,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onViewHistory,
  });

  Color get _color => bucket.colorHex != null
      ? Color(int.parse(bucket.colorHex!.replaceFirst('#', '0xff')))
      : AppColors.accent;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.12)
        : AppColors.border.withValues(alpha: 0.4);
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final icon = IconHelper.fromString(bucket.iconCodePoint);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Icon(icon, color: _color, size: 17),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bucket.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: fg,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          currencyFormatter.format(bucket.balance),
                          style: GoogleFonts.dmMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: fg,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 2),
                        _CardMenu(onEdit: onEdit, onViewHistory: onViewHistory),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onViewHistory;

  const _CardMenu({required this.onEdit, required this.onViewHistory});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      iconSize: 17,
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_horiz, color: AppColors.textTertiary),
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
            Text('Edit bucket', style: GoogleFonts.dmSans(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'history',
          child: Row(children: [
            const Icon(Icons.history_rounded, size: 14),
            const SizedBox(width: 10),
            Text('View history', style: GoogleFonts.dmSans(fontSize: 13)),
          ]),
        ),
      ],
    );
  }
}

// ─── Entry sheet ──────────────────────────────────────────────────────────────

class _EntrySheet extends StatelessWidget {
  final SavingsBucket bucket;
  final TransactionController txController;
  final SavingsController savingsController;
  final VoidCallback onDone;
  final VoidCallback onViewHistory;

  const _EntrySheet({
    required this.bucket,
    required this.txController,
    required this.savingsController,
    required this.onDone,
    required this.onViewHistory,
  });

  Color get _color => bucket.colorHex != null
      ? Color(int.parse(bucket.colorHex!.replaceFirst('#', '0xff')))
      : AppColors.accent;

  void _openForm(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionFormSheet(
        bucket: bucket,
        txController: txController,
        savingsController: savingsController,
        onDone: onDone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.12)
        : AppColors.border.withValues(alpha: 0.35);
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final icon = IconHelper.fromString(bucket.iconCodePoint);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
          // Bucket header
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
                    Text(bucket.name,
                        style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: fg)),
                    Text(currencyFormatter.format(bucket.balance),
                        style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: _color)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // New Transaction button
          _ActionTile(
            icon: Icons.swap_vert_rounded,
            iconColor: AppColors.accent,
            title: 'New Transaction',
            subtitle: 'Record a deposit or withdrawal',
            isDark: isDark,
            borderColor: borderColor,
            onTap: () => _openForm(context),
          ),
          const SizedBox(height: 10),
          // View History button
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
                    Text(title,
                        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
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

// ─── Transaction form sheet ───────────────────────────────────────────────────

class _TransactionFormSheet extends StatefulWidget {
  final SavingsBucket bucket;
  final TransactionController txController;
  final SavingsController savingsController;
  final VoidCallback onDone;

  const _TransactionFormSheet({
    required this.bucket,
    required this.txController,
    required this.savingsController,
    required this.onDone,
  });

  @override
  State<_TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<_TransactionFormSheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TransactionType _type = TransactionType.income;
  bool _saving = false;

  Color get _color => widget.bucket.colorHex != null
      ? Color(int.parse(widget.bucket.colorHex!.replaceFirst('#', '0xff')))
      : AppColors.accent;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    try {
      final userId = locator.get<AuthController>().currentUser?.id ?? '';
      final categoryId = await locator
          .get<FinanceCategoryController>()
          .findOrCreateSavingsCategory(userId);
      await widget.txController.createTransaction(Transaction(
        amount: amount,
        type: _type,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        date: DateTime.now(),
        savingsId: widget.bucket.id,
        financeCategoryId: categoryId,
      ));
      final delta = _type == TransactionType.income ? amount : -amount;
      await widget.savingsController.updateSavingsBucket(
        widget.bucket.copyWith(balance: widget.bucket.balance + delta),
      );
      widget.onDone();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final isDeposit = _type == TransactionType.income;
    final typeColor = isDeposit ? AppColors.success : AppColors.error;

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
                Text(widget.bucket.name,
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 24),
            // Type selector
            Row(
              children: [
                Expanded(child: _TypeButton(
                  label: 'Deposit',
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.success,
                  selected: isDeposit,
                  onTap: () => setState(() => _type = TransactionType.income),
                )),
                const SizedBox(width: 10),
                Expanded(child: _TypeButton(
                  label: 'Withdrawal',
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.error,
                  selected: !isDeposit,
                  onTap: () => setState(() => _type = TransactionType.expense),
                )),
              ],
            ),
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
                  borderSide: BorderSide(color: typeColor, width: 1.5),
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
                  borderSide: BorderSide(color: typeColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: typeColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        isDeposit ? 'Confirm Deposit' : 'Confirm Withdrawal',
                        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : (isDark ? const Color(0xFF2A2A28) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? color : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? color : AppColors.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}
