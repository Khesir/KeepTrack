import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';

class EntitySelection {
  final String type;
  final String? subscriptionId;
  final String? debtId;
  final String? goalId;
  final String label;
  const EntitySelection({required this.type, this.subscriptionId, this.debtId, this.goalId, required this.label});
}

class EntityLinkPickerSheet {
  static IconData entityIcon(String type) => switch (type) {
    'subscription' => Icons.autorenew_rounded,
    'debt_payment' => Icons.arrow_upward_rounded,
    'lending'      => Icons.arrow_downward_rounded,
    'goal'         => Icons.flag_outlined,
    _              => Icons.link_rounded,
  };

  static void showTypePicker(
    BuildContext context, {
    required bool isDark,
    required String? linkedLabel,
    required String? selectedId,
    required VoidCallback onRemoveLink,
    required ValueChanged<EntitySelection> onSelect,
    bool? isIncome,
    Set<String> excludeIds = const {},
  }) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);

    final allTypes = [
      (icon: Icons.autorenew_rounded, label: 'Subscription', sub: 'Recurring service payment', type: 'subscription', color: AppColors.warning),
      (icon: Icons.arrow_upward_rounded, label: 'Debt', sub: 'Money you owe', type: 'debt_payment', color: AppColors.error),
      (icon: Icons.arrow_downward_rounded, label: 'Receivable', sub: 'Money owed to you', type: 'lending', color: AppColors.success),
      (icon: Icons.flag_outlined, label: 'Goal', sub: 'Savings contribution', type: 'goal', color: AppColors.accent),
    ];
    // isIncome == null: no filtering (existing transaction-editing behavior).
    // isIncome == true: Income groups only offer the Receivable (lending) link.
    // isIncome == false: Expense groups offer Subscription/Debt/Goal.
    final types = switch (isIncome) {
      true => allTypes.where((t) => t.type == 'lending').toList(),
      false => allTypes.where((t) => t.type != 'lending').toList(),
      null => allTypes,
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
            child: Row(children: [
              Expanded(child: Text('Link to…', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary))),
              GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
            ]),
          ),
          Divider(height: 1, color: divColor),
          if (linkedLabel != null) ...[
            ListTile(
              leading: Icon(Icons.link_off_rounded, size: 18, color: AppColors.error),
              title: Text('Remove link', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.error)),
              onTap: () {
                onRemoveLink();
                Navigator.pop(context);
              },
            ),
            Divider(height: 1, color: divColor),
          ],
          ...types.map((t) => ListTile(
            leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: t.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)), child: Icon(t.icon, size: 17, color: t.color)),
            title: Text(t.label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            subtitle: Text(t.sub, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
            onTap: () { Navigator.pop(context); _showEntityPicker(context, isDark, t.type, selectedId, onSelect, excludeIds); },
          )),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  static void _showEntityPicker(BuildContext context, bool isDark, String entityType, String? selectedId, ValueChanged<EntitySelection> onSelect, Set<String> excludeIds) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);

    String title;
    Widget listWidget;

    Widget buildList<T>(List<T> items, String Function(T) label, String? Function(T) id, Color dotColor, EntitySelection Function(T) toSelection) {
      if (items.isEmpty) {
        return Center(child: Padding(padding: const EdgeInsets.all(24),
            child: Text('No items found', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary))));
      }
      return Column(mainAxisSize: MainAxisSize.min, children: items.map((e) {
        final sel = id(e) == selectedId;
        return ListTile(
          leading: Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          title: Text(label(e), style: GoogleFonts.dmSans(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: textPrimary)),
          trailing: sel ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
          onTap: () { onSelect(toSelection(e)); Navigator.pop(context); },
        );
      }).toList());
    }

    switch (entityType) {
      case 'subscription':
        title = 'Select Subscription';
        final subs = (locator.get<SubscriptionController>().data ?? []).where((s) => s.status == SubscriptionStatus.active && (s.id == selectedId || !excludeIds.contains(s.id))).toList()..sort((a, b) => a.name.compareTo(b.name));
        listWidget = buildList<Subscription>(subs, (s) => s.name, (s) => s.id, AppColors.warning,
            (s) => EntitySelection(type: 'subscription', subscriptionId: s.id, label: s.name));
      case 'debt_payment':
        title = 'Select Debt';
        final debts = (locator.get<DebtController>().data ?? []).where((d) => d.type == DebtType.borrowing && d.status == DebtStatus.active && (d.id == selectedId || !excludeIds.contains(d.id))).toList()..sort((a, b) => a.personName.compareTo(b.personName));
        listWidget = buildList<Debt>(debts, (d) => d.personName, (d) => d.id, AppColors.error,
            (d) => EntitySelection(type: 'debt_payment', debtId: d.id, label: d.personName));
      case 'lending':
        title = 'Select Receivable';
        final recv = (locator.get<DebtController>().data ?? []).where((d) => d.type == DebtType.lending && d.status == DebtStatus.active && (d.id == selectedId || !excludeIds.contains(d.id))).toList()..sort((a, b) => a.personName.compareTo(b.personName));
        listWidget = buildList<Debt>(recv, (d) => d.personName, (d) => d.id, AppColors.success,
            (d) => EntitySelection(type: 'lending', debtId: d.id, label: d.personName));
      case 'goal':
        title = 'Select Goal';
        final goals = (locator.get<GoalController>().data ?? []).where((g) => g.status == GoalStatus.active && (g.id == selectedId || !excludeIds.contains(g.id))).toList()..sort((a, b) => a.name.compareTo(b.name));
        listWidget = buildList<Goal>(goals, (g) => g.name, (g) => g.id, AppColors.accent,
            (g) => EntitySelection(type: 'goal', goalId: g.id, label: g.name));
      default:
        return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
            child: Row(children: [
              Expanded(child: Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary))),
              GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
            ]),
          ),
          Divider(height: 1, color: divColor),
          ConstrainedBox(constraints: const BoxConstraints(maxHeight: 320), child: SingleChildScrollView(child: listWidget)),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }
}
