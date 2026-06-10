import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';

class TransactionDetailAttachmentList extends StatelessWidget {
  final List<String> imagePaths;
  const TransactionDetailAttachmentList({super.key, required this.imagePaths});

  static void _showViewer(BuildContext context, String path) {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: size.height * 0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            Container(
              color: const Color(0xFF1A1A1A),
              child: InteractiveViewer(
                child: Image.file(File(path), fit: BoxFit.contain, width: double.infinity),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attachments', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        ...imagePaths.map((path) {
          final exists = TransactionImageService.fileExists(path);
          final name = TransactionImageService.displayName(path);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: exists ? () => _showViewer(context, path) : null,
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: exists
                      ? Image.file(File(path), width: 34, height: 34, fit: BoxFit.cover)
                      : Container(
                          width: 34, height: 34,
                          color: AppColors.textTertiary.withValues(alpha: 0.15),
                          child: const Icon(Icons.broken_image_outlined, size: 14, color: AppColors.textTertiary),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }
}

class TransactionDetailAttachmentEditor extends StatefulWidget {
  final List<String> imagePaths;
  final String transactionId;
  final VoidCallback onChanged;

  const TransactionDetailAttachmentEditor({super.key, required this.imagePaths, required this.transactionId, required this.onChanged});

  @override
  State<TransactionDetailAttachmentEditor> createState() => _TransactionDetailAttachmentEditorState();
}

class _TransactionDetailAttachmentEditorState extends State<TransactionDetailAttachmentEditor> {
  Future<void> _pick() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 8),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Camera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
          const SizedBox(height: 8),
        ])),
      ),
    );
    if (source == null || !mounted) return;
    final path = await TransactionImageService.pickImage(widget.transactionId, source: source);
    if (path != null) {
      widget.imagePaths.add(path);
      widget.onChanged();
    }
  }

  void _showViewer(String path) {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: size.height * 0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(children: [
            Container(
              color: const Color(0xFF1A1A1A),
              child: InteractiveViewer(
                child: Image.file(File(path), fit: BoxFit.contain, width: double.infinity),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.imagePaths.map((path) {
          final exists = TransactionImageService.fileExists(path);
          final name = TransactionImageService.displayName(path);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              GestureDetector(
                onTap: exists ? () => _showViewer(path) : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: exists
                      ? Image.file(File(path), width: 34, height: 34, fit: BoxFit.cover)
                      : Container(width: 34, height: 34, color: AppColors.textTertiary.withValues(alpha: 0.15), child: const Icon(Icons.broken_image_outlined, size: 14, color: AppColors.textTertiary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: exists ? () => _showViewer(path) : null,
                  child: Text(name, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              GestureDetector(
                onTap: () {
                  TransactionImageService.deleteImage(path).ignore();
                  widget.imagePaths.remove(path);
                  widget.onChanged();
                },
                child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 14, color: AppColors.textTertiary)),
              ),
            ]),
          );
        }),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _pick,
          child: Row(children: [
            Icon(Icons.attach_file_rounded, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Text('Add attachment', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary)),
          ]),
        ),
      ],
    );
  }
}
