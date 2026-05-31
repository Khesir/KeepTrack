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
    SavingsManagementDialog.show(
      context,
      userId: userId,
      onSave: (b) => _controller.createSavingsBucket(b),
    );
  }

  void _openEdit(BuildContext context, SavingsBucket bucket) {
    final userId = locator.get<AuthController>().currentUser?.id ?? '';
    SavingsManagementDialog.show(
      context,
      bucket: bucket,
      userId: userId,
      onSave: (b) => _controller.updateSavingsBucket(b),
      onDelete: () => _controller.deleteSavingsBucket(bucket.id!),
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
    const h = 12.0;
    final pad = isDesktop ? 24.0 : 16.0;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _SavingsHero(
            total: total,
            count: buckets.length,
            isDark: isDark,
            onAdd: () => _openCreate(context),
          ),
        ),
        if (buckets.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(onAdd: () => _openCreate(context)),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 100),
              child: Wrap(
                spacing: h,
                runSpacing: h,
                children: [
                  ...buckets.asMap().entries.map((e) {
                    final i = e.key;
                    final b = e.value;
                    return TweenAnimationBuilder<double>(
                      key: ValueKey(b.id),
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
                        height: 160,
                        child: _BucketCard(
                          bucket: b,
                          isDark: isDark,
                          total: total,
                          onTap: () => _openAddEntry(context, b),
                          onEdit: () => _openEdit(context, b),
                          onViewHistory: () => setState(() => _selectedBucket = b),
                        ),
                      ),
                    );
                  }),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 450),
                    curve: Interval(
                      (buckets.length * 0.08).clamp(0.0, 0.6),
                      ((buckets.length * 0.08) + 0.4).clamp(0.0, 1.0),
                      curve: Curves.easeOut,
                    ),
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
                    ),
                    child: SizedBox(
                      width: 200,
                      height: 160,
                      child: _AddBucketCard(
                        isDark: isDark,
                        onTap: () => _openCreate(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Hero header ──────────────────────────────────────────────────────────────

class _SavingsHero extends StatelessWidget {
  final double total;
  final int count;
  final bool isDark;
  final VoidCallback onAdd;

  const _SavingsHero({
    required this.total,
    required this.count,
    required this.isDark,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.savings_rounded, color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Savings',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: total),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text(
                      currencyFormatter.format(v),
                      style: GoogleFonts.dmMono(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: -0.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count bucket${count == 1 ? '' : 's'}',
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary),
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
  final double total;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onViewHistory;

  const _BucketCard({
    required this.bucket,
    required this.isDark,
    required this.total,
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
    final share = total > 0 ? (bucket.balance / total).clamp(0.0, 1.0) : 0.0;

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
              // ── Top band ──────────────────────────────────────────────
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
                      // Icon + menu row
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
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
                      // Balance
                      Text(
                        currencyFormatter.format(bucket.balance, decimalDigits: 0),
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
                        bucket.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: fg,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Share bar
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: share),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: v,
                            minHeight: 3,
                            backgroundColor: _color.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(_color),
                          ),
                        ),
                      ),
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

// ─── Add bucket ghost card ────────────────────────────────────────────────────

class _AddBucketCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AddBucketCard({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.25)
        : AppColors.border.withValues(alpha: 0.5);

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
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: AppColors.accent, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'New Bucket',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
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
        AppToast.error(context, 'Error: $e');
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
