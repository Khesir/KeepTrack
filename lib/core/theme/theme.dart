import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/theme/brand_theme.dart' show getLightTheme, getDarkTheme;

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => getLightTheme();
  static ThemeData get darkTheme => getDarkTheme();

  static Color getPriorityColor(String priority) => switch (priority.toLowerCase()) {
    'urgent' => AppColors.error,
    'high' => AppColors.warning,
    'medium' => AppColors.accent,
    _ => AppColors.mutedForeground,
  };

  static Color getStatusColor(String status) => switch (status.toLowerCase()) {
    'completed' => AppColors.success,
    'in_progress' || 'inprogress' => AppColors.info,
    'todo' => AppColors.warning,
    _ => AppColors.textSecondary,
  };
}
