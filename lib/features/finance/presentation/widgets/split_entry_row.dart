import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/helpers/split_entry.dart';
import 'package:keep_track/features/finance/presentation/sheets/split_entry_picker_sheets.dart';
import 'package:keep_track/features/finance/presentation/sheets/transaction_create_entity_link_sheet.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import 'package:keep_track/features/finance/presentation/widgets/create_transaction_chips.dart';
import 'package:keep_track/features/finance/presentation/widgets/split_entry_header_row.dart';
import 'package:keep_track/features/finance/presentation/widgets/transaction_create_attachments.dart';

class SplitEntryRow extends StatefulWidget {
  final SplitEntry entry;
  final bool isDark;
  final Color borderColor;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onPickCategory;
  final VoidCallback onRemove;
  final VoidCallback onPickImage;

  const SplitEntryRow({
    super.key,
    required this.entry,
    required this.isDark,
    required this.borderColor,
    required this.canRemove,
    required this.onChanged,
    required this.onPickCategory,
    required this.onRemove,
    required this.onPickImage,
  });

  @override
  State<SplitEntryRow> createState() => _SplitEntryRowState();
}

class _SplitEntryRowState extends State<SplitEntryRow> {
  late final WalletController _walletController;
  late final BudgetProfileController _profileController;
  late final MonthPlanController _monthPlanController;
  late final DebtController _debtController;
  late final GoalController _goalController;
  late final SubscriptionController _subController;

  @override
  void initState() {
    super.initState();
    _walletController = locator.get<WalletController>();
    _profileController = locator.get<BudgetProfileController>();
    _monthPlanController = locator.get<MonthPlanController>();
    _debtController = locator.get<DebtController>();
    _goalController = locator.get<GoalController>();
    _subController = locator.get<SubscriptionController>();
  }

  void _pickWallet() {
    final wallets = _walletController.data ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SplitEntryWalletPickerSheet(
        isDark: widget.isDark,
        wallets: wallets,
        selectedWalletId: widget.entry.walletId,
        onSelect: (w) {
          setState(() {
            widget.entry.walletId = w.id;
            widget.entry.walletName = w.name;
          });
        },
      ),
    );
  }

  void _pickProfile() {
    final profiles = _profileController.data ?? [];
    final plans = _monthPlanController.data ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SplitEntryProfilePickerSheet(
        isDark: widget.isDark,
        profiles: profiles,
        plans: plans,
        selectedProfileId: widget.entry.profileId,
        onSelect: (profileId, label) {
          setState(() {
            widget.entry.profileId = profileId;
            widget.entry.profileName = label;
          });
        },
      ),
    );
  }

  void _pickEntity() {
    final isIncome = widget.entry.type == TransactionType.income;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionCreateEntityTypeSheet(
        isIncome: isIncome,
        currentEntityType: widget.entry.entityType,
        onSelectNone: () {
          setState(() {
            widget.entry.entityType = null;
            widget.entry.entityLabel = null;
            widget.entry.debtId = null;
            widget.entry.goalId = null;
            widget.entry.subscriptionId = null;
          });
        },
        onSelectType: (type) {
          setState(() {
            widget.entry.entityType = type;
            widget.entry.entityLabel = null;
            widget.entry.debtId = null;
            widget.entry.goalId = null;
            widget.entry.subscriptionId = null;
            widget.entry.category = null;
          });
          _pickEntityItem(type);
        },
      ),
    );
  }

  void _pickEntityItem(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => TransactionCreateEntityItemSheet(
        entityType: type,
        debtController: _debtController,
        goalController: _goalController,
        subController: _subController,
        currentDebtId: widget.entry.debtId,
        currentGoalId: widget.entry.goalId,
        currentSubscriptionId: widget.entry.subscriptionId,
        onSelect: (id, label) {
          setState(() {
            widget.entry.entityLabel = label;
            if (type == 'debt_payment' ||
                type == 'debt_received' ||
                type == 'lending')
              widget.entry.debtId = id;
            if (type == 'goal') widget.entry.goalId = id;
            if (type == 'subscription') {
              widget.entry.subscriptionId = id;
              final sub = _subController.data
                  ?.where((s) => s.id == id)
                  .firstOrNull;
              if (sub != null)
                widget.entry.amountCtrl.text = sub.amount.toStringAsFixed(2);
              widget.onChanged();
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(widget.entry.date, now);
    final dateLabel = isToday
        ? 'Today'
        : DateFormat('MMM d').format(widget.entry.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SplitEntryHeaderRow(
            entry: widget.entry,
            isDark: widget.isDark,
            canRemove: widget.canRemove,
            onTypeToggle: () => setState(() {
              widget.entry.type = widget.entry.type == TransactionType.expense
                  ? TransactionType.income
                  : TransactionType.expense;
              widget.entry.category = null;
              widget.entry.entityType = null;
              widget.entry.entityLabel = null;
              widget.entry.debtId = null;
              widget.entry.goalId = null;
              widget.entry.subscriptionId = null;
              widget.onChanged();
            }),
            onNoteChanged: () => setState(() {}),
            onPickImage: widget.onPickImage,
            onRemove: widget.onRemove,
          ),
          const SizedBox(height: 8),
          // Chips row
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              SplitEntryChip(
                icon: Icons.calendar_month_outlined,
                label: 'Plan',
                color: widget.entry.isPlan
                    ? AppColors.accent
                    : AppColors.textSecondary,
                isDark: widget.isDark,
                onTap: () => setState(() {
                  widget.entry.isPlan = !widget.entry.isPlan;
                  if (widget.entry.isPlan) widget.entry.category = null;
                  widget.onChanged();
                }),
              ),
              SplitEntryChip(
                icon: Icons.account_balance_wallet_outlined,
                label: widget.entry.profileName ?? 'Budget',
                color: widget.entry.profileName != null
                    ? AppColors.accent
                    : AppColors.textSecondary,
                isDark: widget.isDark,
                onTap: _pickProfile,
              ),
              if (!widget.entry.isPlan && widget.entry.entityType == null)
                SplitEntryChip(
                  icon: Icons.category_outlined,
                  label: widget.entry.category?.name ?? 'Category',
                  color: widget.entry.category != null
                      ? AppColors.textSecondary
                      : AppColors.textTertiary,
                  isDark: widget.isDark,
                  onTap: widget.onPickCategory,
                ),
              SplitEntryChip(
                icon: Icons.account_balance_wallet_outlined,
                label: widget.entry.walletName ?? 'Wallet',
                color: widget.entry.walletName != null
                    ? AppColors.accent
                    : AppColors.textSecondary,
                isDark: widget.isDark,
                onTap: _pickWallet,
              ),
              SplitEntryChip(
                icon: Icons.calendar_today_outlined,
                label: dateLabel,
                color: isToday ? AppColors.textSecondary : AppColors.accent,
                isDark: widget.isDark,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.entry.date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null)
                    setState(() => widget.entry.date = picked);
                },
              ),
              if (!widget.entry.isPlan)
                SplitEntryChip(
                  icon: widget.entry.entityType != null
                      ? Icons.link_rounded
                      : Icons.link_off_rounded,
                  label:
                      widget.entry.entityLabel ??
                      (widget.entry.entityType != null
                          ? entityLinkTypeLabel(widget.entry.entityType!)
                          : 'Link'),
                  color: widget.entry.entityLabel != null
                      ? AppColors.success
                      : AppColors.textSecondary,
                  isDark: widget.isDark,
                  onTap: _pickEntity,
                ),
              SplitEntryChip(
                icon: Icons.attach_file_rounded,
                label: widget.entry.imagePaths.isEmpty
                    ? 'Attach'
                    : 'Files (${widget.entry.imagePaths.length})',
                color: widget.entry.imagePaths.isNotEmpty
                    ? AppColors.accent
                    : AppColors.textSecondary,
                isDark: widget.isDark,
                onTap: widget.onPickImage,
              ),
            ],
          ),
          if (widget.entry.imagePaths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TransactionCreateAttachmentList(
                imagePaths: widget.entry.imagePaths,
                onRemove: (path) {
                  TransactionImageService.deleteImage(path).ignore();
                  setState(() => widget.entry.imagePaths.remove(path));
                  widget.onChanged();
                },
                onView: (path) =>
                    TransactionCreateImageViewerDialog.show(context, path),
              ),
            ),
          // Entity metadata banner
          Builder(
            builder: (_) {
              final meta = _buildMeta();
              if (meta == null) return const SizedBox.shrink();
              final typeColor = widget.entry.type == TransactionType.income
                  ? AppColors.success
                  : AppColors.error;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(
                      alpha: widget.isDark ? 0.1 : 0.06,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: typeColor.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: typeColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          meta,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String? _buildMeta() {
    final e = widget.entry;
    if (e.entityType == null) return null;
    if (e.debtId != null) {
      final debt = _debtController.data
          ?.where((d) => d.id == e.debtId)
          .firstOrNull;
      if (debt == null) return null;
      return e.entityType == 'debt_payment'
          ? 'Still owe ${currencyFormatter.format(debt.remainingAmount)} to ${debt.personName}'
          : 'Expecting ${currencyFormatter.format(debt.remainingAmount)} from ${debt.personName}';
    }
    if (e.goalId != null) {
      final goal = _goalController.data
          ?.where((g) => g.id == e.goalId)
          .firstOrNull;
      if (goal == null) return null;
      final remaining = (goal.targetAmount - goal.currentAmount).clamp(
        0.0,
        double.infinity,
      );
      return '${currencyFormatter.format(goal.currentAmount)} of ${currencyFormatter.format(goal.targetAmount)} saved · ${currencyFormatter.format(remaining)} to go';
    }
    if (e.subscriptionId != null) {
      final sub = _subController.data
          ?.where((s) => s.id == e.subscriptionId)
          .firstOrNull;
      if (sub == null) return null;
      return '${currencyFormatter.format(sub.amount)} recurring';
    }
    return null;
  }
}
