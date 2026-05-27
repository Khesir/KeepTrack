import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../../domain/entities/budget.dart';
import 'budget_progress_card.dart';

class BudgetTypeSection extends StatelessWidget {
  final String title;
  final List<Budget> budgets;
  final Color color;
  final IconData icon;
  final bool isDesktop;
  final void Function(Budget) onBudgetTap;

  const BudgetTypeSection({
    super.key,
    required this.title,
    required this.budgets,
    required this.color,
    required this.icon,
    required this.isDesktop,
    required this.onBudgetTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, color: color, icon: icon, count: budgets.length),
        const SizedBox(height: AppSpacing.md),
        ...budgets.map(
          (budget) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: BudgetProgressCard(
              budget: budget,
              color: color,
              isDesktop: isDesktop,
              onTap: () => onBudgetTap(budget),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.color,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(
          child: Text(title, style: AppTextStyles.h3),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
