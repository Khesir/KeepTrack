import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import '../../domain/entities/budget_category.dart';

/// What a Budget Category row/detail sheet should display: its name, and —
/// for a Category Link — the linked entity's current status as a tag (never
/// as a reason to hide the row). See CONTEXT.md ("Linked entity status tag").
class LinkedCategoryDisplay {
  final String name;
  final String? statusLabel;
  final Color? statusColor;

  /// What kind of thing this category is linked to — "Subscription", "Goal",
  /// "Debt" (borrowing), or "Receivable" (lending) — or `null` when unlinked.
  /// Unlike [statusLabel]/[statusColor], this is shown regardless of the
  /// linked entity's current status, and falls back to a generic "Debt"
  /// label if the linked Debt itself can no longer be found (hard-deleted),
  /// since a Subscription/Goal link is unambiguous but a Debt link alone
  /// can't tell borrowing from lending without the live entity.
  final String? typeLabel;

  const LinkedCategoryDisplay({required this.name, this.statusLabel, this.statusColor, this.typeLabel});
}

/// Resolves display info for a [BudgetCategory]. For an unlinked category,
/// this is just its [FinanceCategory] name. For a linked category, this
/// looks up the live Subscription/Debt/Goal by id: if found, uses its
/// current name and (when not in its "normal active" state) a status tag;
/// if the entity was hard-deleted, falls back to the snapshotted
/// [BudgetCategory.linkedEntityLabel] with no status tag.
LinkedCategoryDisplay resolveLinkedCategoryDisplay(BudgetCategory cat) {
  if (!cat.isLinked) {
    return LinkedCategoryDisplay(name: cat.financeCategory?.name ?? 'Category');
  }

  if (cat.subscriptionId != null) {
    final sub = (locator.get<SubscriptionController>().data ?? [])
        .where((s) => s.id == cat.subscriptionId)
        .firstOrNull;
    if (sub == null) {
      return LinkedCategoryDisplay(name: cat.linkedEntityLabel ?? 'Category', typeLabel: 'Subscription');
    }
    final (label, color) = switch (sub.status) {
      SubscriptionStatus.active => (null, null),
      SubscriptionStatus.paused => ('Paused', AppColors.warning),
      SubscriptionStatus.cancelled => ('Cancelled', AppColors.textTertiary),
    };
    return LinkedCategoryDisplay(name: sub.name, statusLabel: label, statusColor: color, typeLabel: 'Subscription');
  }

  if (cat.debtId != null) {
    final debt = (locator.get<DebtController>().data ?? [])
        .where((d) => d.id == cat.debtId)
        .firstOrNull;
    if (debt == null) {
      return LinkedCategoryDisplay(name: cat.linkedEntityLabel ?? 'Category', typeLabel: 'Debt');
    }
    final (label, color) = switch (debt.status) {
      DebtStatus.active => (null, null),
      DebtStatus.settled => ('Settled', AppColors.success),
      DebtStatus.overdue => ('Overdue', AppColors.error),
    };
    final typeLabel = debt.type == DebtType.lending ? 'Receivable' : 'Debt';
    return LinkedCategoryDisplay(name: debt.personName, statusLabel: label, statusColor: color, typeLabel: typeLabel);
  }

  if (cat.goalId != null) {
    final goal = (locator.get<GoalController>().data ?? [])
        .where((g) => g.id == cat.goalId)
        .firstOrNull;
    if (goal == null) {
      return LinkedCategoryDisplay(name: cat.linkedEntityLabel ?? 'Category', typeLabel: 'Goal');
    }
    final (label, color) = switch (goal.status) {
      GoalStatus.active => (null, null),
      GoalStatus.completed => ('Completed', AppColors.success),
      GoalStatus.paused => ('Paused', AppColors.warning),
    };
    return LinkedCategoryDisplay(name: goal.name, statusLabel: label, statusColor: color, typeLabel: 'Goal');
  }

  return LinkedCategoryDisplay(name: cat.linkedEntityLabel ?? 'Category');
}
