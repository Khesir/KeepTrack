import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../transaction/domain/entities/transaction.dart';
import '../../domain/entities/budget_category.dart';
import '../widget/category_detail_content.dart';

class CategoryDetailSheet extends StatelessWidget {
  final BudgetCategory category;
  final List<Transaction> transactions;
  final bool isIncomeGroup;

  const CategoryDetailSheet({
    required this.category,
    required this.transactions,
    this.isIncomeGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: CategoryDetailContent(
              category: category,
              transactions: transactions,
              isIncomeGroup: isIncomeGroup,
              scrollController: scrollCtrl,
            ),
          ),
        ],
      ),
    );
  }
}
