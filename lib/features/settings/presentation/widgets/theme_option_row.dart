import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class ThemeOptionRow extends StatefulWidget {
  final AppThemeMode mode;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const ThemeOptionRow({
    super.key,
    required this.mode,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<ThemeOptionRow> createState() => ThemeOptionRowState();
}

class ThemeOptionRowState extends State<ThemeOptionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fg =
        widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _hovered ? hoverBg : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              Icon(widget.mode.icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 14),
              Text(
                widget.mode.displayName,
                style: GoogleFonts.dmSans(fontSize: 14, color: fg),
              ),
              const Spacer(),
              if (widget.selected)
                Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
