import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';
import 'package:keep_track/features/finance/presentation/helpers/split_entry.dart';
import 'package:keep_track/features/finance/presentation/helpers/transaction_image_picker.dart';
import 'package:keep_track/features/finance/presentation/widgets/transaction_create_attachments.dart';

Future<void> showSplitEntryAttachmentsSheet(
  BuildContext context,
  SplitEntry entry,
  VoidCallback onUpdate,
) async {
  if (entry.imagePaths.isEmpty) {
    return pickTransactionImage(context, entry.id, entry.imagePaths, onUpdate);
  }
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? AppColors.cardDark : AppColors.card;
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setSS) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TransactionCreateAttachmentList(
                imagePaths: entry.imagePaths,
                onRemove: (path) {
                  TransactionImageService.deleteImage(path).ignore();
                  setSS(() => entry.imagePaths.remove(path));
                  onUpdate();
                },
                onView: (path) =>
                    TransactionCreateImageViewerDialog.show(ctx, path),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await pickTransactionImage(
                      context,
                      entry.id,
                      entry.imagePaths,
                      onUpdate,
                    );
                  },
                  icon: const Icon(Icons.attach_file_rounded, size: 15),
                  label: const Text('Add attachment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(
                      color: AppColors.textTertiary.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
