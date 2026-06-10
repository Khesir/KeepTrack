import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class OutlineButton extends StatefulWidget {
  final String label;
  final bool isDark;
  final bool primary;
  final VoidCallback onTap;

  const OutlineButton({
    super.key,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.primary = false,
  });

  @override
  State<OutlineButton> createState() => OutlineButtonState();
}

class OutlineButtonState extends State<OutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.primary
        ? AppColors.accent
        : (widget.isDark
            ? Colors.white.withValues(alpha: _hovered ? 0.1 : 0.06)
            : AppColors.textPrimary.withValues(alpha: _hovered ? 0.08 : 0.05));
    final fg = widget.primary ? Colors.white : (widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
