import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/services/notification/notification_scheduler.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/debt/domain/entities/debt.dart';
import '../../modules/debt/domain/repositories/debt_repository.dart';
import '../../modules/transaction/domain/entities/transaction.dart';
import '../../modules/wallet/data/models/wallet_model.dart';
import '../../modules/wallet/domain/entities/wallet.dart';
import 'budget_profile_controller.dart';
import 'transaction_controller.dart';
import 'wallet_controller.dart';

/// Controller for managing debt list state
class DebtController extends StreamState<AsyncState<List<Debt>>> {
  final DebtRepository _debtRepository;

  DebtController(this._debtRepository) : super(const AsyncLoading()) {
    loadDebts();
  }

  /// Load all debts, optionally scoped to a budget profile
  Future<void> loadDebts({String? budgetProfileId}) async {
    await execute(() async {
      final debts = await _debtRepository.getDebts(budgetProfileId: budgetProfileId).then((r) => r.unwrap());
      // Schedule notifications for debts with due dates
      _scheduleDebtNotifications(debts);
      return debts;
    });
  }

  Future<void> _scheduleDebtNotifications(List<Debt> debts) async {
    if (!PlatformNotificationHelper.instance.isSupportedPlatform) return;
    for (final debt in debts) {
      _scheduleNotificationForDebt(debt);
    }
  }

  void _scheduleNotificationForDebt(Debt debt) {
    if (!PlatformNotificationHelper.instance.isSupportedPlatform) return;
    if (debt.id == null || debt.dueDate == null) return;
    if (debt.status != DebtStatus.active) return;
    if (debt.dueDate!.isBefore(DateTime.now())) return;
    locator.get<NotificationScheduler>().scheduleDebtDueNotifications(
      debtId: debt.id!,
      personName: debt.personName,
      amount: debt.remainingAmount,
      dueDate: debt.dueDate!,
    );
  }

  void _cancelDebtNotification(String id) {
    if (!PlatformNotificationHelper.instance.isSupportedPlatform) return;
    locator.get<NotificationScheduler>().cancelDebtDueNotifications(id);
  }

  String? get _activeProfileId =>
      locator.get<BudgetProfileController>().activeProfileId;

  Debt _withProfile(Debt debt) =>
      debt.budgetProfileId != null ? debt : debt.copyWith(budgetProfileId: _activeProfileId);

  Future<void> createDebt(Debt debt) async {
    await executeSilent(() async {
      final created = await _debtRepository.createDebt(_withProfile(debt)).then((r) => r.unwrap());
      _scheduleNotificationForDebt(created);
      return await _debtRepository.getDebts().then((r) => r.unwrap());
    });
  }

  /// Creates a debt record and a linked wallet transaction atomically.
  /// Borrowing → income transaction (wallet receives money).
  /// Lending → expense transaction (wallet sends money).
  Future<void> createDebtWithTransaction(
    Debt debt,
    Wallet wallet, {
    String? categoryId,
    String? budgetProfileId,
    List<String> imagePaths = const [],
  }) async {
    final created = await _debtRepository.createDebt(_withProfile(debt)).then((r) => r.unwrap());

    final txType = debt.type == DebtType.borrowing
        ? TransactionType.income
        : TransactionType.expense;
    final description = debt.type == DebtType.borrowing
        ? 'Loan from ${debt.personName}'
        : 'Lent to ${debt.personName}';

    final tx = await locator.get<TransactionController>().createTransaction(Transaction(
      amount: debt.originalAmount,
      type: txType,
      date: debt.startDate,
      walletId: wallet.id,
      debtId: created.id,
      description: description,
      financeCategoryId: categoryId,
      budgetProfileId: budgetProfileId ?? created.budgetProfileId,
      imagePaths: imagePaths,
    ));

    if (tx.id != null) {
      await _debtRepository.updateDebt(created.copyWith(transactionId: tx.id));
    }

    final walletController = locator.get<WalletController>();
    final allWallets = walletController.data ?? [];
    final fresh = allWallets.firstWhere(
      (w) => w.id == wallet.id,
      orElse: () => WalletModel.fromEntity(wallet),
    );
    final delta = debt.type == DebtType.borrowing
        ? debt.originalAmount
        : -debt.originalAmount;
    await walletController.updateWallet(fresh.copyWith(balance: fresh.balance + delta));

    await executeSilent(() async {
      return await _debtRepository.getDebts().then((r) => r.unwrap());
    });
  }

  Future<void> updateDebt(Debt debt) async {
    await executeSilent(() async {
      await _debtRepository.updateDebt(debt).then((r) => r.unwrap());
      if (debt.id != null) _cancelDebtNotification(debt.id!);
      _scheduleNotificationForDebt(debt);
      return await _debtRepository.getDebts().then((r) => r.unwrap());
    });
  }

  Future<void> deleteDebt(String id) async {
    await executeSilent(() async {
      await _debtRepository.deleteDebt(id).then((r) => r.unwrap());
      _cancelDebtNotification(id);
      return await _debtRepository.getDebts().then((r) => r.unwrap());
    });
  }

  /// Update debt payment (record partial payment)
  Future<void> updateDebtPayment(String id, double newRemainingAmount) async {
    await executeSilent(() async {
      await _debtRepository.updateDebtPayment(id, newRemainingAmount).then((r) => r.unwrap());
      return await _debtRepository.getDebts().then((r) => r.unwrap());
    });
  }

  Future<void> settleDebt(String id) async {
    await executeSilent(() async {
      await _debtRepository.settleDebt(id).then((r) => r.unwrap());
      _cancelDebtNotification(id);
      return await _debtRepository.getDebts().then((r) => r.unwrap());
    });
  }

  /// Load debts by type
  Future<void> loadDebtsByType(DebtType type) async {
    await execute(() async {
      return await _debtRepository.getDebtsByType(type).then((r) => r.unwrap());
    });
  }

  /// Load debts by status
  Future<void> loadDebtsByStatus(DebtStatus status) async {
    await execute(() async {
      return await _debtRepository
          .getDebtsByStatus(status)
          .then((r) => r.unwrap());
    });
  }

  /// Record a payment against a debt. Returns the updated debt.
  Future<Debt> payDebt(
    String id, {
    required double amount,
    double? fee,
  }) async {
    final updated = await _debtRepository
        .payDebt(id, amount: amount, fee: fee)
        .then((r) => r.unwrap());
    await executeSilent(() async {
      final current = data ?? [];
      return current.map((d) => d.id == id ? updated : d).toList();
    });
    return updated;
  }

  /// Records a payment, creates a linked transaction, and updates wallet balance.
  /// Borrowing payment → expense transaction (money leaves wallet).
  /// Lending collection → income transaction (money enters wallet).
  /// Auto-settles the debt if remaining amount reaches zero.
  Future<void> payDebtWithTransaction(
    Debt debt, {
    required double amount,
    required Wallet wallet,
    double fee = 0,
    String? categoryId,
    String? budgetProfileId,
    List<String> imagePaths = const [],
    DateTime? date,
    String? description,
  }) async {
    final updated = await payDebt(debt.id!, amount: amount, fee: fee > 0 ? fee : null);

    if (updated.remainingAmount <= 0 && updated.status != DebtStatus.settled) {
      await settleDebt(debt.id!);
    }

    final txType = debt.type == DebtType.borrowing
        ? TransactionType.expense
        : TransactionType.income;
    final autoDesc = debt.type == DebtType.borrowing
        ? 'Payment to ${debt.personName}'
        : 'Collected from ${debt.personName}';

    await locator.get<TransactionController>().createTransaction(Transaction(
      amount: amount,
      type: txType,
      date: date ?? DateTime.now(),
      walletId: wallet.id,
      debtId: debt.id,
      description: description ?? autoDesc,
      fee: fee,
      financeCategoryId: categoryId,
      budgetProfileId: budgetProfileId,
      imagePaths: imagePaths,
    ));

    // Gap: wallet update — fetch fresh copy to avoid stale balance
    final walletController = locator.get<WalletController>();
    final allWallets = walletController.data ?? [];
    final fresh = allWallets.firstWhere(
      (w) => w.id == wallet.id,
      orElse: () => WalletModel.fromEntity(wallet),
    );
    final delta = debt.type == DebtType.borrowing ? -amount : amount;
    await walletController.updateWallet(
        fresh.copyWith(balance: fresh.balance + delta));
  }
}
