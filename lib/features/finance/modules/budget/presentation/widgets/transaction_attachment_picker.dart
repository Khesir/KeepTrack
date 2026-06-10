import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';
import '../sheets/sheet_chip.dart';

class TransactionAttachmentPicker extends StatefulWidget {
  final String pendingTxId;
  final List<String> imagePaths;
  final bool isDark;

  const TransactionAttachmentPicker({
    super.key,
    required this.pendingTxId,
    required this.imagePaths,
    required this.isDark,
  });

  @override
  State<TransactionAttachmentPicker> createState() => _TransactionAttachmentPickerState();
}

class _TransactionAttachmentPickerState extends State<TransactionAttachmentPicker> {
  Color get _bg => widget.isDark ? AppColors.cardDark : AppColors.card;

  Future<void> _pickImage() async {
    if (widget.imagePaths.isNotEmpty) {
      await _showImageManager();
      return;
    }
    final source = await _showImageSourcePicker();
    if (source == null || !mounted) return;
    final path = await TransactionImageService.pickImage(widget.pendingTxId, source: source);
    if (path != null && mounted) setState(() => widget.imagePaths.add(path));
  }

  Future<ImageSource?> _showImageSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('Gallery', style: GoogleFonts.dmSans(fontSize: 14)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text('Camera', style: GoogleFonts.dmSans(fontSize: 14)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImageManager() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSS) => Container(
          decoration: BoxDecoration(
            color: _bg,
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.imagePaths
                      .map((path) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(path),
                                    width: 72, height: 72, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    TransactionImageService.deleteImage(path).ignore();
                                    setSS(() => widget.imagePaths.remove(path));
                                    setState(() {});
                                  },
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final source = await _showImageSourcePicker();
                      if (source == null || !mounted) return;
                      final path = await TransactionImageService.pickImage(
                          widget.pendingTxId, source: source);
                      if (path != null && mounted) {
                        setState(() => widget.imagePaths.add(path));
                      }
                    },
                    icon: const Icon(Icons.attach_file_rounded, size: 15),
                    label: const Text('Add attachment'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(
                          color: AppColors.textTertiary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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

  @override
  Widget build(BuildContext context) {
    return SheetChip(
      icon: Icons.attach_file_rounded,
      label: widget.imagePaths.isEmpty ? 'Attach' : 'Files (${widget.imagePaths.length})',
      active: widget.imagePaths.isNotEmpty,
      isDark: widget.isDark,
      onTap: _pickImage,
    );
  }
}
