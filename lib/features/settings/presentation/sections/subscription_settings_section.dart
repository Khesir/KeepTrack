import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class SubscriptionSettingsSection extends StatelessWidget {
  final bool isDark;
  const SubscriptionSettingsSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.backgroundSecondary;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.15)
        : AppColors.border.withValues(alpha: 0.4);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.star_outline_rounded, size: 26, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              'Keep Track Plus',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coming soon – cloud sync, AI insights,\nand more. Stay tuned.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: Text(
                'You\'re on the free plan – all features unlocked.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
