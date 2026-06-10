import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import '../helpers/editable_scan_item.dart';

class ScanEntityLinkPickerSheet {
  static void showTypePicker(
    BuildContext context, {
    required bool isDark,
    required EditableScanItem item,
    required VoidCallback onChanged,
  }) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);

    final types = [
      (icon: Icons.autorenew_rounded, label: 'Subscription', sub: 'Recurring service payment', type: 'subscription', color: AppColors.warning),
      (icon: Icons.arrow_upward_rounded, label: 'Debt', sub: 'Money you owe to someone', type: 'debt_payment', color: AppColors.error),
      (icon: Icons.arrow_downward_rounded, label: 'Receivable', sub: 'Money owed to you', type: 'lending', color: AppColors.success),
      (icon: Icons.flag_outlined, label: 'Goal', sub: 'Savings contribution', type: 'goal', color: AppColors.accent),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
            child: Text('Link to…', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
          ),
          Divider(height: 1, color: divColor),
          ...types.map((t) => ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: t.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(t.icon, size: 17, color: t.color),
            ),
            title: Text(t.label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            subtitle: Text(t.sub, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
            onTap: () {
              Navigator.pop(context);
              item.entityType = t.type;
              item.entityHint = null;
              onChanged();
              showEntityPicker(context, isDark: isDark, item: item, onChanged: onChanged);
            },
          )),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  static void showEntityPicker(
    BuildContext context, {
    required bool isDark,
    required EditableScanItem item,
    required VoidCallback onChanged,
  }) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);
    final hint = item.entityHint?.toLowerCase() ?? '';

    Widget buildList<T>(
      List<T> items,
      String Function(T) label,
      String Function(T) id,
      String? Function(T) subtitle,
      Color Function(T) color,
      void Function(T) onSelect,
    ) {
      final filtered = hint.isEmpty
          ? items
          : items.where((e) => label(e).toLowerCase().contains(hint)).toList();
      final display = filtered.isEmpty ? items : filtered;
      if (display.isEmpty) {
        return Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No items found', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
        ));
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: display.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: divColor),
        itemBuilder: (_, i) {
          final e = display[i];
          final sel = id(e) == (item.subscriptionId ?? item.debtId ?? item.goalId);
          final sub = subtitle(e);
          return ListTile(
            leading: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color(e), shape: BoxShape.circle),
            ),
            title: Text(label(e), style: GoogleFonts.dmSans(fontSize: 13,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: textPrimary)),
            subtitle: sub != null ? Text(sub, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)) : null,
            trailing: sel ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
            onTap: () { onSelect(e); Navigator.pop(context); },
          );
        },
      );
    }

    String title;
    Widget listContent;

    switch (item.entityType) {
      case 'subscription':
        title = 'Link Subscription';
        final subs = (locator.get<SubscriptionController>().data ?? [])
            .where((s) => s.status == SubscriptionStatus.active)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        listContent = buildList<Subscription>(
          subs,
          (s) => s.name,
          (s) => s.id ?? '',
          (s) => s.provider ?? s.billingCycle.displayName,
          (_) => AppColors.warning,
          (s) { item.subscriptionId = s.id; item.entityLabel = s.name; onChanged(); },
        );
      case 'debt_payment':
        title = 'Link Debt';
        final debts = (locator.get<DebtController>().data ?? [])
            .where((d) => d.type == DebtType.borrowing && d.status == DebtStatus.active)
            .toList()
          ..sort((a, b) => a.personName.compareTo(b.personName));
        listContent = buildList<Debt>(
          debts,
          (d) => d.personName,
          (d) => d.id ?? '',
          (d) => '${currencyFormatter.format(d.remainingAmount, decimalDigits: 0)} remaining',
          (_) => AppColors.error,
          (d) { item.debtId = d.id; item.entityLabel = d.personName; onChanged(); },
        );
      case 'lending':
        title = 'Link Receivable';
        final receivables = (locator.get<DebtController>().data ?? [])
            .where((d) => d.type == DebtType.lending && d.status == DebtStatus.active)
            .toList()
          ..sort((a, b) => a.personName.compareTo(b.personName));
        listContent = buildList<Debt>(
          receivables,
          (d) => d.personName,
          (d) => d.id ?? '',
          (d) => '${currencyFormatter.format(d.remainingAmount, decimalDigits: 0)} remaining',
          (_) => AppColors.success,
          (d) { item.debtId = d.id; item.entityLabel = d.personName; onChanged(); },
        );
      case 'goal':
        title = 'Link Goal';
        final goals = (locator.get<GoalController>().data ?? [])
            .where((g) => g.status == GoalStatus.active)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        listContent = buildList<Goal>(
          goals,
          (g) => g.name,
          (g) => g.id ?? '',
          (g) => '${currencyFormatter.format(g.currentAmount, decimalDigits: 0)} / ${currencyFormatter.format(g.targetAmount, decimalDigits: 0)}',
          (g) => g.colorHex != null
              ? Color(int.parse(g.colorHex!.replaceFirst('#', '0xff')))
              : AppColors.accent,
          (g) { item.goalId = g.id; item.entityLabel = g.name; onChanged(); },
        );
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
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                if (item.entityHint != null)
                  Text('Suggested: ${item.entityHint}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary)),
              ),
            ]),
          ),
          Divider(height: 1, color: divColor),
          // Remove link option
          if (item.entityLabel != null || item.subscriptionId != null || item.debtId != null || item.goalId != null)
            Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: Icon(Icons.link_off_rounded, size: 18, color: AppColors.error),
                title: Text('Remove link', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.error)),
                onTap: () {
                  item.subscriptionId = null;
                  item.debtId = null;
                  item.goalId = null;
                  item.entityLabel = null;
                  item.entityType = null;
                  item.entityHint = null;
                  onChanged();
                  Navigator.pop(context);
                },
              ),
              Divider(height: 1, color: divColor),
            ]),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(child: listContent),
          ),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }
}
