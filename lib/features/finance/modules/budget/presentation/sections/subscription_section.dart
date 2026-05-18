import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import '../widgets/ghost_add_row.dart';

class SubscriptionSection extends StatelessWidget {
  final List<Subscription> subscriptions;
  final VoidCallback onAdd;
  final Future<void> Function(Subscription) onPay;
  final int? dragIndex;

  const SubscriptionSection({
    super.key,
    required this.subscriptions,
    required this.onAdd,
    required this.onPay,
    this.dragIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleRow = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            'SUBSCRIPTIONS',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (dragIndex != null)
            ReorderableDragStartListener(
              index: dragIndex!,
              child: const MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Icon(Icons.drag_handle, size: 18, color: AppColors.textTertiary),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRow,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Name', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
              ),
              SizedBox(
                width: 80,
                child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
              ),
              SizedBox(
                width: 70,
                child: Text('Cycle', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
              ),
              SizedBox(
                width: 70,
                child: Text('Next Bill', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
              ),
              SizedBox(width: 56), // Pay button column
            ],
          ),
        ),
        ...subscriptions.map((s) => _SubscriptionRow(subscription: s, onPay: () => onPay(s))),
        GhostAddRow(label: 'Add Subscription', onTap: onAdd),
      ],
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onPay;

  const _SubscriptionRow({required this.subscription, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final s = subscription;
    final isOverdue = s.isOverdue;
    final isUpcoming = s.isUpcoming;
    final dateColor = isOverdue
        ? AppColors.error
        : isUpcoming
        ? AppColors.warning
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (s.provider != null)
                  Text(
                    s.provider!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              currencyFormatter.format(s.amount, decimalDigits: 2),
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              s.billingCycle.displayName,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              DateFormat('MMM d').format(s.nextBillingDate),
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                color: dateColor,
                fontWeight: (isOverdue || isUpcoming) ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: s.status == SubscriptionStatus.active
                ? TextButton(
                    onPressed: onPay,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(48, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Pay', style: TextStyle(fontSize: 12)),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
