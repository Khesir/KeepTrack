import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

Future<void> showWipeDataDialog(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Wipe all data?', style: AppTextStyles.h4),
      content: Text(
        'This will permanently delete all your transactions, budgets, goals, debts, and other financial data. Default categories will be restored. This cannot be undone.',
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
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Wipe All Data'),
        ),
      ],
    ),
  );
}
