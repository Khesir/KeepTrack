import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

Future<void> showResetSettingsDialog(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Reset settings?', style: AppTextStyles.h4),
      content: Text(
        'All settings will return to defaults. This cannot be undone.',
        style: AppTextStyles.bodySmall,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
          child: const Text('Reset'),
        ),
      ],
    ),
  );
}
