import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.add_rounded, size: 12, color: AppColors.accent),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
