import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class DesktopSettingsHeader extends StatelessWidget {
  final bool isDark;
  final bool isDialog;
  const DesktopSettingsHeader({super.key, required this.isDark, this.isDialog = false});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.25)
        : AppColors.border.withValues(alpha: 0.5);
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!isDialog)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.arrow_back_rounded, size: 18, color: fg),
                ),
              ),
            ),
          Text('Settings', style: AppTextStyles.h4.copyWith(color: fg)),
          if (isDialog) ...[
            const Spacer(),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
