import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';

class SavingsSection extends StatelessWidget {
  final List<SavingsBucket> buckets;
  final Map<String, double> plannedAmounts;
  final VoidCallback onManage;
  final void Function(SavingsBucket) onDeposit;
  final void Function(SavingsBucket, double) onSetPlanned;
  final int? dragIndex;

  const SavingsSection({
    super.key,
    required this.buckets,
    required this.plannedAmounts,
    required this.onManage,
    required this.onDeposit,
    required this.onSetPlanned,
    this.dragIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(
                'SAVINGS',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onManage,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 14, color: AppColors.textTertiary),
                ),
              ),
              const Spacer(),
              if (dragIndex != null)
                ReorderableDragStartListener(
                  index: dragIndex!,
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle, size: 18, color: AppColors.textTertiary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Name', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
              ),
              SizedBox(
                width: 90,
                child: Text('Planned', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
              ),
              SizedBox(
                width: 90,
                child: Text('Balance', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
              ),
              SizedBox(width: 60),
            ],
          ),
        ),
        ...buckets.map((b) => _SavingsRow(
              bucket: b,
              planned: plannedAmounts[b.id] ?? 0,
              onDeposit: () => onDeposit(b),
              onSetPlanned: (amount) => onSetPlanned(b, amount),
            )),
      ],
    );
  }
}

class _SavingsRow extends StatelessWidget {
  final SavingsBucket bucket;
  final double planned;
  final VoidCallback onDeposit;
  final void Function(double) onSetPlanned;

  const _SavingsRow({
    required this.bucket,
    required this.planned,
    required this.onDeposit,
    required this.onSetPlanned,
  });

  void _showPlannedDialog(BuildContext context) {
    final ctrl = TextEditingController(
      text: planned > 0 ? planned.toStringAsFixed(2) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Planned deposit — ${bucket.name}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v >= 0) onSetPlanned(v);
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              bucket.name,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => _showPlannedDialog(context),
            child: SizedBox(
              width: 90,
              child: Text(
                planned > 0
                    ? currencyFormatter.format(planned, decimalDigits: 2)
                    : '—',
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySmall.copyWith(
                  color: planned > 0 ? AppColors.textSecondary : AppColors.textDisabled,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              currencyFormatter.format(bucket.balance, decimalDigits: 2),
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: TextButton(
              onPressed: onDeposit,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(48, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Deposit', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}
