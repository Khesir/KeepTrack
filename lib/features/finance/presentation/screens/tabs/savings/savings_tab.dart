import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';
import 'package:keep_track/features/finance/presentation/screens/configuration/savings/widget/savings_management_dialog.dart';
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';

class SavingsTab extends StatefulWidget {
  const SavingsTab({super.key});

  @override
  State<SavingsTab> createState() => _SavingsTabState();
}

class _SavingsTabState extends State<SavingsTab> {
  late final SavingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<SavingsController>();
  }

  void _showDialog({SavingsBucket? bucket}) {
    final userId = locator.get<AuthController>().currentUser?.id ?? '';
    showDialog(
      context: context,
      builder: (_) => SavingsManagementDialog(
        bucket: bucket,
        userId: userId,
        onSave: (b) async {
          if (bucket != null) {
            await _controller.updateSavingsBucket(b);
          } else {
            await _controller.createSavingsBucket(b);
          }
        },
        onDelete: bucket != null
            ? () => _controller.deleteSavingsBucket(bucket.id!)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      title: 'Savings',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
      child: StreamStateBuilder<List<SavingsBucket>>(
        stream: _controller.stream,
        initialData: _controller.state,
        onData: (buckets) => buckets.isEmpty
            ? _buildEmpty()
            : _buildList(buckets),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.savings_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('No savings buckets yet', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first savings bucket',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<SavingsBucket> buckets) {
    final total = buckets.fold<double>(0, (sum, b) => sum + b.balance);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _TotalCard(total: total),
        const SizedBox(height: AppSpacing.md),
        ...buckets.map((b) => _BucketCard(
              bucket: b,
              onTap: () => _showDialog(bucket: b),
            )),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;

  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.savings, color: theme.colorScheme.primary, size: 32),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Savings', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                Text(
                  '₱ ${total.toStringAsFixed(2)}',
                  style: AppTextStyles.h3.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketCard extends StatelessWidget {
  final SavingsBucket bucket;
  final VoidCallback onTap;

  const _BucketCard({required this.bucket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = bucket.colorHex != null
        ? Color(int.parse(bucket.colorHex!.replaceFirst('#', '0xff')))
        : AppColors.primary;
    final icon = IconHelper.fromString(bucket.iconCodePoint);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(bucket.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        trailing: Text(
          '₱ ${bucket.balance.toStringAsFixed(2)}',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
