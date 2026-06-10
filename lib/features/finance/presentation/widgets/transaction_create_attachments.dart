import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';

class TransactionCreateAttachmentList extends StatelessWidget {
  final List<String> imagePaths;
  final void Function(String) onRemove;
  final void Function(String) onView;

  const TransactionCreateAttachmentList({
    super.key,
    required this.imagePaths,
    required this.onRemove,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: imagePaths
          .map(
            (path) => _AttachmentItem(
              path: path,
              onRemove: () => onRemove(path),
              onView: () => onView(path),
            ),
          )
          .toList(),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  final VoidCallback onView;

  const _AttachmentItem({
    required this.path,
    required this.onRemove,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final exists = TransactionImageService.fileExists(path);
    final name = TransactionImageService.displayName(path);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: exists ? onView : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: exists
                  ? Image.file(
                      File(path),
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 34,
                      height: 34,
                      color: AppColors.textTertiary.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: exists ? onView : null,
              child: Text(
                name,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionCreateImageViewerDialog extends StatelessWidget {
  final String path;
  const TransactionCreateImageViewerDialog({super.key, required this.path});

  static void show(BuildContext context, String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => TransactionCreateImageViewerDialog(path: path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: size.height * 0.1,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              color: const Color(0xFF1A1A1A),
              child: InteractiveViewer(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
