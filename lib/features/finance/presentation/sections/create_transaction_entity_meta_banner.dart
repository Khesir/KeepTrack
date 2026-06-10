import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateTransactionEntityMetaBanner extends StatelessWidget {
  final String? meta;
  final Color typeColor;
  final bool isDark;

  const CreateTransactionEntityMetaBanner({
    super.key,
    required this.meta,
    required this.typeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (meta == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: typeColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 13, color: typeColor),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                meta!,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: typeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
