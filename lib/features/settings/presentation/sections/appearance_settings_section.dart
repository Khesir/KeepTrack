import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../widgets/pane_widgets.dart';
import '../widgets/theme_option_row.dart';

class AppearanceSettingsSection extends StatefulWidget {
  final bool isDark;
  final AppSettings settings;
  final SettingsController controller;

  const AppearanceSettingsSection({
    super.key,
    required this.isDark,
    required this.settings,
    required this.controller,
  });

  @override
  State<AppearanceSettingsSection> createState() => _AppearanceSettingsSectionState();
}

class _AppearanceSettingsSectionState extends State<AppearanceSettingsSection> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = AppCurrency.values
        .where((c) =>
            c.displayName.toLowerCase().contains(_search.toLowerCase()) ||
            c.code.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final borderColor = widget.isDark
        ? AppColors.border.withValues(alpha: 0.15)
        : AppColors.border.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PaneLabel('Theme'),
        ...AppThemeMode.values.map((mode) => ThemeOptionRow(
              mode: mode,
              selected: widget.settings.themeMode == mode,
              isDark: widget.isDark,
              onTap: () => widget.controller.updateThemeMode(mode),
            )),
        Divider(height: 24, indent: 24, endIndent: 24, color: borderColor),
        PaneLabel('Currency'),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: GoogleFonts.dmSans(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search currency…',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 16),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: borderColor),
            itemBuilder: (_, i) {
              final c = filtered[i];
              final isSel = c == widget.settings.currency;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.controller.updateCurrency(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            c.symbol,
                            style: GoogleFonts.dmMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.displayName,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: isSel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSel
                                  ? AppColors.accent
                                  : (widget.isDark
                                        ? AppColors.primaryForeground
                                        : AppColors.textPrimary),
                            ),
                          ),
                        ),
                        Text(
                          c.code,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (isSel) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_rounded,
                              size: 16, color: AppColors.accent),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
