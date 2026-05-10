import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class GhostAddRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const GhostAddRow({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
