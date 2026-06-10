import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../helpers/editable_scan_item.dart';
import '../widgets/scan_review_item_tile.dart';
import '../widgets/scan_widgets.dart';

class ScanReviewSection extends StatelessWidget {
  final bool isDark;
  final bool textMode;
  final List<EditableScanItem> items;
  final String? errorMessage;
  final String currencySymbol;
  final VoidCallback onRescan;
  final VoidCallback onItemChanged;
  final ValueChanged<EditableScanItem> onPickProfile;
  final ValueChanged<EditableScanItem> onPickCategory;
  final ValueChanged<EditableScanItem> onPickWallet;
  final ValueChanged<EditableScanItem> onPickEntity;
  final VoidCallback? onConfirm;

  const ScanReviewSection({
    super.key,
    required this.isDark,
    required this.textMode,
    required this.items,
    required this.errorMessage,
    required this.currencySymbol,
    required this.onRescan,
    required this.onItemChanged,
    required this.onPickProfile,
    required this.onPickCategory,
    required this.onPickWallet,
    required this.onPickEntity,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.void_ : AppColors.background;
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final includedCount = items.where((i) => i.included).length;

    return DraggableScrollableSheet(
      initialChildSize: errorMessage != null || items.isEmpty ? 0.45 : 0.88,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: isDark ? 0.15 : 0.3))),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const ScanHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      errorMessage != null
                          ? (textMode ? 'Couldn\'t parse input' : 'Couldn\'t read document')
                          : items.isEmpty
                              ? (textMode ? 'Nothing found' : 'Nothing detected')
                              : '${items.length} transaction${items.length == 1 ? '' : 's'} found',
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    Text(
                      errorMessage != null
                          ? (textMode ? 'Try rephrasing your input' : 'See tips below and try again')
                          : items.isEmpty
                              ? (textMode ? 'Try describing your expenses more clearly' : 'Try a clearer photo of your document')
                              : 'Review and edit before saving',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ])),
                  TextButton.icon(
                    onPressed: onRescan,
                    icon: Icon(textMode ? Icons.edit_note_rounded : Icons.camera_alt_outlined, size: 14),
                    label: Text(textMode ? 'Re-type' : 'Re-scan'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
            ]),
          ),

          // Error state
          if (errorMessage != null)
            Expanded(child: SingleChildScrollView(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(Icons.error_outline_rounded, size: 17, color: AppColors.error),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(errorMessage!, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.error, height: 1.45))),
                  ]),
                ),
                const SizedBox(height: 20),
                Text(
                  textMode ? 'Tips for better results' : 'Tips for a better scan',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: 0.3),
                ),
                const SizedBox(height: 10),
                ...(textMode ? [
                  (Icons.format_list_numbered_rounded, 'List one expense per line for clarity'),
                  (Icons.place_rounded, 'Mention the wallet name, e.g. "from GCash" or "BDO"'),
                  (Icons.calendar_today_outlined, 'Include dates like "yesterday" or "last Monday"'),
                  (Icons.translate_rounded, 'Filipino-English mixing is fine – be natural'),
                ] : [
                  (Icons.light_mode_outlined, 'Use good lighting – avoid shadows and glare'),
                  (Icons.crop_free_rounded, 'Fit the full document in the frame'),
                  (Icons.blur_off_rounded, 'Hold your camera steady for a sharp photo'),
                  (Icons.text_fields_rounded, 'Make sure all text is clearly readable'),
                  (Icons.rotate_right_rounded, 'Try a different angle if text is skewed'),
                ]).map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(tip.$2, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, height: 1.4))),
                  ]),
                )),
              ]),
            ))),

          // Empty state
          if (items.isEmpty && errorMessage == null)
            Expanded(child: Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.image_search_rounded, size: 28, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 14),
                Text('No transactions found', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 6),
                Text(
                  textMode
                      ? 'Nothing recognisable was found. Try describing amounts, what they were for, and which wallet.'
                      : 'The document may not contain recognisable expense data, or the image quality is too low. Try a clearer photo.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ]),
            ))),

          // Entity link legend – shown when any item has an unlinked entity chip
          if (items.isNotEmpty && items.any((i) => i.entityType != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4), width: 0.5),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(child: RichText(text: TextSpan(children: [
                    TextSpan(text: 'Entity chip: ', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    WidgetSpan(alignment: PlaceholderAlignment.middle, child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    )),
                    TextSpan(text: 'red = tap to link  ', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                    WidgetSpan(alignment: PlaceholderAlignment.middle, child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    )),
                    TextSpan(text: 'green = linked', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                  ]))),
                ]),
              ),
            ),

          // Item list
          if (items.isNotEmpty)
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => ScanReviewItemTile(
                  key: ValueKey(items[i].id),
                  item: items[i],
                  isDark: isDark,
                  currencySymbol: currencySymbol,
                  onChanged: onItemChanged,
                  onPickProfile: () => onPickProfile(items[i]),
                  onPickCategory: () => onPickCategory(items[i]),
                  onPickWallet: () => onPickWallet(items[i]),
                  onPickEntity: () => onPickEntity(items[i]),
                ),
              ),
            ),

          // Confirm bar
          if (items.isNotEmpty)
            ScanConfirmBar(isDark: isDark, count: includedCount, onConfirm: onConfirm),
        ]),
      ),
    );
  }
}
