import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'scan_widgets.dart';

class ScanPickStep extends StatelessWidget {
  final bool isDark;
  final bool textMode;
  final bool isDesktop;
  final TextEditingController textController;
  final ValueChanged<ImageSource> onPickImage;
  final ValueChanged<bool> onSetTextMode;
  final VoidCallback onParseText;

  const ScanPickStep({
    super.key,
    required this.isDark,
    required this.textMode,
    required this.isDesktop,
    required this.textController,
    required this.onPickImage,
    required this.onSetTextMode,
    required this.onParseText,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.void_ : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + 24;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPad),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const ScanHandle(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    textMode ? Icons.edit_note_rounded : Icons.document_scanner_outlined,
                    size: 22, color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    textMode ? 'Describe your expenses' : 'Add Expenses',
                    style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  Text(
                    textMode ? 'Type naturally, AI will parse it' : 'Scan an image or type it out',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ])),
                if (textMode)
                  GestureDetector(
                    onTap: () {
                      textController.clear();
                      onSetTextMode(false);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: textMode
                    ? _buildTextInput(textPrimary)
                    : _buildImageOptions(),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildImageOptions() {
    return Column(
      key: const ValueKey('image'),
      children: [
        if (!isDesktop) ...[
          ScanSourceCard(isDark: isDark, icon: Icons.camera_alt_outlined,
              label: 'Camera', sublabel: 'Take a photo now',
              onTap: () => onPickImage(ImageSource.camera)),
          const SizedBox(height: 10),
        ],
        ScanSourceCard(isDark: isDark, icon: Icons.photo_library_outlined,
            label: isDesktop ? 'Choose from Files' : 'Gallery',
            sublabel: isDesktop ? 'JPG, PNG or WebP' : 'Pick from files',
            onTap: () => onPickImage(ImageSource.gallery)),
        const SizedBox(height: 10),
        ScanSourceCard(
          isDark: isDark,
          icon: Icons.edit_note_rounded,
          label: 'Type it out',
          sublabel: 'e.g. "500 groceries from GCash yesterday"',
          color: AppColors.success,
          onTap: () => onSetTextMode(true),
        ),
      ],
    );
  }

  Widget _buildTextInput(Color textPrimary) {
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.25) : AppColors.border.withValues(alpha: 0.5);
    return Column(
      key: const ValueKey('text'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: textController,
          autofocus: true,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. "spent 500 on groceries from GCash, paid 1200 electricity from BDO yesterday"',
            hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary, height: 1.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.success, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: textController.text.trim().isEmpty ? null : onParseText,
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: Text('Parse with AI', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              disabledBackgroundColor: AppColors.textTertiary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
