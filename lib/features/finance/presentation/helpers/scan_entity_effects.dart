import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import 'editable_scan_item.dart';

// Try to auto-link the entity from the AI hint so the chip starts green.
void autoLinkScanEntity(EditableScanItem item, String? entityType, String? hint) {
  if (entityType == null) return;
  final h = hint?.toLowerCase() ?? '';

  switch (entityType) {
    case 'subscription':
      final subs = locator.get<SubscriptionController>().data ?? [];
      final match = subs.where((s) =>
          s.status == SubscriptionStatus.active &&
          (h.isEmpty || s.name.toLowerCase().contains(h) || (s.provider?.toLowerCase().contains(h) ?? false))
      ).firstOrNull;
      if (match != null) {
        item.subscriptionId = match.id;
        item.entityLabel = match.name;
      }
    case 'debt_payment':
      final debts = locator.get<DebtController>().data ?? [];
      final match = debts.where((d) =>
          d.type == DebtType.borrowing &&
          d.status == DebtStatus.active &&
          (h.isEmpty || d.personName.toLowerCase().contains(h))
      ).firstOrNull;
      if (match != null) {
        item.debtId = match.id;
        item.entityLabel = match.personName;
      }
    case 'lending':
      final recv = locator.get<DebtController>().data ?? [];
      final match = recv.where((d) =>
          d.type == DebtType.lending &&
          d.status == DebtStatus.active &&
          (h.isEmpty || d.personName.toLowerCase().contains(h))
      ).firstOrNull;
      if (match != null) {
        item.debtId = match.id;
        item.entityLabel = match.personName;
      }
    case 'goal':
      final goals = locator.get<GoalController>().data ?? [];
      final match = goals.where((g) =>
          g.status == GoalStatus.active &&
          (h.isEmpty || g.name.toLowerCase().contains(h))
      ).firstOrNull;
      if (match != null) {
        item.goalId = match.id;
        item.entityLabel = match.name;
      }
  }
}

void autoLinkScanWallet(EditableScanItem item, String? hint) {
  if (hint == null || hint.isEmpty) return;
  final h = hint.toLowerCase();
  final wallets = locator.get<WalletController>().data ?? [];
  final match = wallets.where((w) => w.name.toLowerCase().contains(h) || h.contains(w.name.toLowerCase())).firstOrNull;
  if (match != null) {
    item.walletId = match.id;
    item.walletName = match.name;
  }
}

Future<void> applyScanEntitySideEffects(EditableScanItem item) async {
  final subController = locator.get<SubscriptionController>();
  final debtController = locator.get<DebtController>();
  final goalController = locator.get<GoalController>();
  final walletController = locator.get<WalletController>();

  if (item.subscriptionId != null) {
    await subController.pay(item.subscriptionId!);
  }

  // (payDebt only does an optimistic in-memory update which misses filtered caches)
  if (item.debtId != null) {
    final isPayment = item.entityType == 'debt_payment' ||
        (item.entityType == 'lending' && item.type == TransactionType.income);
    if (isPayment) {
      // Reload if null OR if the specific debt isn't in the current (possibly filtered) cache
      final cached = (debtController.data ?? []).where((d) => d.id == item.debtId).firstOrNull;
      if (cached == null) await debtController.loadDebts();
      final debt = (debtController.data ?? [])
          .where((d) => d.id == item.debtId)
          .firstOrNull;
      if (debt != null) {
        final newRemaining = (debt.remainingAmount - item.amount).clamp(0.0, double.infinity);
        if (newRemaining <= 0) {
          await debtController.updateDebt(debt.copyWith(
            remainingAmount: 0,
            status: DebtStatus.settled,
          ));
        } else {
          await debtController.updateDebtPayment(item.debtId!, newRemaining);
        }
      }
    }
  }

  if (item.goalId != null) {
    await goalController.contributeToGoal(item.goalId!, item.amount);
    if (walletController.data == null) await walletController.loadWallets();
    final goal = (goalController.data ?? []).where((g) => g.id == item.goalId).firstOrNull;
    if (goal?.savingsBucketId != null) {
      final wallet = (walletController.data ?? [])
          .where((w) => w.id == goal!.savingsBucketId)
          .firstOrNull;
      if (wallet != null) {
        await walletController.updateWallet(
          wallet.copyWith(balance: wallet.balance + item.amount),
        );
      }
    }
  }
}
