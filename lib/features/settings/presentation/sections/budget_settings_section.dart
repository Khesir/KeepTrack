import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../widgets/pane_widgets.dart';
import 'gallery_settings_section.dart';

class BudgetSettingsSection extends StatefulWidget {
  final bool isDark;
  final AppSettings settings;
  final SettingsController controller;

  const BudgetSettingsSection({
    super.key,
    required this.isDark,
    required this.settings,
    required this.controller,
  });

  @override
  State<BudgetSettingsSection> createState() => _BudgetSettingsSectionState();
}

class _BudgetSettingsSectionState extends State<BudgetSettingsSection> {
  bool _showGallery = false;

  @override
  Widget build(BuildContext context) {
    return _showGallery
        ? GallerySettingsSection(
            isDark: widget.isDark,
            onBack: () => setState(() => _showGallery = false),
          )
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              PaneRow(
                isDark: widget.isDark,
                icon: widget.settings.budgetSheetMode
                    ? Icons.table_rows_outlined
                    : Icons.view_stream_outlined,
                iconColor: AppColors.info,
                label: 'Budget View',
                subtitle: widget.settings.budgetSheetMode
                    ? 'Sheet mode – full budget sheet'
                    : 'Simple mode – overview with tabs',
                trailing: Switch(
                  value: widget.settings.budgetSheetMode,
                  onChanged: widget.controller.updateBudgetSheetMode,
                  activeThumbColor: AppColors.accent,
                ),
              ),
              PaneRow(
                isDark: widget.isDark,
                icon: Icons.photo_library_outlined,
                iconColor: AppColors.accent,
                label: 'Attachment Gallery',
                subtitle: 'Browse all transaction receipt photos',
                onTap: () => setState(() => _showGallery = true),
              ),
            ],
          );
  }
}
