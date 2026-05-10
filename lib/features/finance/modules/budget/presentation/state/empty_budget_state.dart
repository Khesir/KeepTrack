import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class EmptyBudgetState extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onStart;

  const EmptyBudgetState({
    super.key,
    required this.monthLabel,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 72,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No budget for $monthLabel',
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start planning your monthly budget.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.add),
                label: Text('Start Planning for $monthLabel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
