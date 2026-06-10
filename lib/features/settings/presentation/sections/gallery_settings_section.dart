import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/transaction_detail_sheet.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

class GallerySettingsSection extends StatefulWidget {
  final bool isDark;
  final VoidCallback onBack;

  const GallerySettingsSection({super.key, required this.isDark, required this.onBack});

  @override
  State<GallerySettingsSection> createState() => _GallerySettingsSectionState();
}

class _GallerySettingsSectionState extends State<GallerySettingsSection> {
  late final TransactionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TransactionController>();
    if (_controller.data == null) _controller.loadAllTransactions();
  }

  List<({Transaction transaction, String path})> _buildEntries(
    List<Transaction> transactions,
  ) {
    final entries = <({Transaction transaction, String path})>[];
    for (final tx in transactions) {
      for (final path in tx.imagePaths) {
        if (TransactionImageService.fileExists(path)) {
          entries.add((transaction: tx, path: path));
        }
      }
    }
    entries.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
    return entries;
  }

  void _openViewer(String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: InteractiveViewer(
                child: Image.file(File(path), fit: BoxFit.contain, width: double.infinity),
              ),
            ),
            Positioned(
              top: 48,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final borderColor = widget.isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Budget',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                'Attachment Gallery',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: borderColor),
        Expanded(
          child: AsyncStreamBuilder<List<Transaction>>(
            state: _controller,
            loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, msg) => Center(
              child: Text(msg, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
            ),
            builder: (context, transactions) {
              final entries = _buildEntries(transactions);
              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 40, color: AppColors.textTertiary),
                      const SizedBox(height: 10),
                      Text(
                        'No attachments yet',
                        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add images when creating a transaction',
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final tx = entry.transaction;
                  final isIncome = tx.type == TransactionType.income;
                  final isTransfer = tx.type == TransactionType.transfer;
                  final amountColor = isTransfer
                      ? AppColors.info
                      : (isIncome ? AppColors.success : AppColors.error);
                  final sign = isTransfer ? '↔' : (isIncome ? '+' : '-');
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _openViewer(entry.path),
                      onSecondaryTap: () => TransactionDetailSheet.show(context, transaction: tx),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(entry.path), fit: BoxFit.cover),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.65),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tx.description ?? DateFormat('MMM d').format(tx.date),
                                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$sign${currencyFormatter.format(tx.amount)}',
                                    style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w700, color: amountColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
