import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';

class TransactionCategoryPicker extends StatelessWidget {
  final TransactionType type;
  final String? selectedId;
  final FinanceCategoryController controller;
  final Set<String>? allowedIds;
  final bool isDark;
  final void Function(FinanceCategory) onSelect;
  const TransactionCategoryPicker({
    super.key,
    required this.type,
    required this.selectedId,
    required this.controller,
    this.allowedIds,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final divColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;
    final targetType = type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Text(
                    'Select Category',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: divColor),
            Expanded(
              child: AsyncStreamBuilder<List<FinanceCategory>>(
                state: controller,
                builder: (_, cats) {
                  var filtered =
                      cats
                          .where((c) => c.type == targetType && !c.isArchive)
                          .where(
                            (c) =>
                                allowedIds == null ||
                                (c.id != null && allowedIds!.contains(c.id)),
                          )
                          .toList()
                        ..sort((a, b) => a.name.compareTo(b.name));
                  if (filtered.isEmpty)
                    return Center(
                      child: Text(
                        'No categories found',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  final color = targetType == CategoryType.income
                      ? AppColors.success
                      : AppColors.error;
                  return ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: divColor,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (_, i) {
                      final cat = filtered[i];
                      final isSel = cat.id == selectedId;
                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            targetType == CategoryType.income
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 15,
                            color: color,
                          ),
                        ),
                        title: Text(
                          cat.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: isSel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: textPrimary,
                          ),
                        ),
                        trailing: isSel
                            ? Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppColors.accent,
                              )
                            : null,
                        onTap: () => onSelect(cat),
                      );
                    },
                  );
                },
                loadingBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
