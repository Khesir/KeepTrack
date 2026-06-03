import 'dart:io';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/transaction/data/datasources/receipt_parser_service.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:uuid/uuid.dart';
import 'create_transaction_sheet.dart' show TransactionCategoryPicker;

enum _ScanStep { pick, loading, review, saving }

class ScanExpensesSheet extends StatefulWidget {
  final VoidCallback? onConfirmed;

  const ScanExpensesSheet({super.key, this.onConfirmed});

  static Future<void> show(BuildContext context, {VoidCallback? onConfirmed}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => ScanExpensesSheet(onConfirmed: onConfirmed),
      );

  @override
  State<ScanExpensesSheet> createState() => _ScanExpensesSheetState();
}

class _ScanExpensesSheetState extends State<ScanExpensesSheet> {
  late final TransactionController _txController;
  late final FinanceCategoryController _catController;
  late final BudgetProfileController _profileController;
  late final BudgetController _budgetController;
  late final AuthController _authController;
  late final SettingsController _settingsController;
  late final SubscriptionController _subController;
  late final DebtController _debtController;
  late final GoalController _goalController;
  late final WalletController _walletController;
  final ReceiptParserService _parserService = ReceiptParserService();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  _ScanStep _step = _ScanStep.pick;
  File? _pickedFile;
  List<_EditableItem> _items = [];
  String? _errorMessage;
  bool _textMode = false;
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _txController = locator.get<TransactionController>();
    _catController = locator.get<FinanceCategoryController>();
    _profileController = locator.get<BudgetProfileController>();
    _budgetController = locator.get<BudgetController>();
    _authController = locator.get<AuthController>();
    _settingsController = locator.get<SettingsController>();
    _subController = locator.get<SubscriptionController>();
    _debtController = locator.get<DebtController>();
    _goalController = locator.get<GoalController>();
    _walletController = locator.get<WalletController>();
    _textCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  FinanceCategory? _matchCategory(String name, TransactionType type) {
    final cats = _catController.data ?? [];
    final targetType = type == TransactionType.income ? CategoryType.income : CategoryType.expense;
    try {
      return cats.firstWhere(
        (c) => c.type == targetType && !c.isArchive &&
               c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Set<String>? _allowedCategoryIds(String? profileId) {
    if (profileId == null) return null;
    final s = _budgetController.state;
    if (s is! AsyncData<List<Budget>>) return null;
    final ids = s.data
        .where((b) => b.budgetProfileId == profileId)
        .expand((b) => b.categories.map((c) => c.financeCategoryId))
        .toSet();
    return ids.isEmpty ? null : ids;
  }

  void _showCategoryPicker(_EditableItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionCategoryPicker(
        type: item.type,
        selectedId: item.category?.id,
        controller: _catController,
        allowedIds: _allowedCategoryIds(item.profileId),
        isDark: isDark,
        onSelect: (cat) {
          setState(() {
            item.category = cat;
            item.categoryName = cat.name;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  List<BudgetProfile> get _profiles {
    final s = _profileController.state;
    return s is AsyncData<List<BudgetProfile>> ? s.data : [];
  }

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  String? get _defaultProfileId => _profileController.activeProfileId;

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xfile == null) return;
    _pickedFile = File(xfile.path);
    await _parseImage();
  }

  Future<void> _parseImage() async {
    setState(() { _step = _ScanStep.loading; _errorMessage = null; });
    try {
      final parsed = await _parserService.parseReceiptImage(_pickedFile!);
      if (!mounted) return;
      final pid = _defaultProfileId;
      final today = DateTime.now();
      final defaultProfile = pid != null
          ? _profiles.cast<BudgetProfile?>().firstWhere((p) => p?.id == pid, orElse: () => null)
          : null;
      final defaultIsMonthly = defaultProfile?.isMonthly ?? false;
      final defaultBaseName = defaultProfile?.name;
      final defaultDisplayName = defaultProfile == null
          ? null
          : defaultIsMonthly
              ? '${defaultProfile.name} · ${DateFormat('MMM yyyy').format(today)}'
              : defaultProfile.name;
      setState(() {
        _items = parsed.map((p) {
          final txType = p.type == 'income' ? TransactionType.income : TransactionType.expense;
          final matched = _matchCategory(p.categoryName, txType);
          final item = _EditableItem(
            id: _uuid.v4(),
            amount: p.amount,
            type: txType,
            description: p.description,
            date: today,
            categoryName: p.categoryName,
            category: matched,
            profileId: pid,
            profileName: defaultDisplayName,
            profileBaseName: defaultBaseName,
            isMonthlyProfile: defaultIsMonthly,
            entityType: p.entityType,
            entityHint: p.entityHint,
            walletHint: p.walletHint,
          );
          // Auto-match entity and wallet from AI hints
          _autoLinkEntity(item, p.entityType, p.entityHint);
          _autoLinkWallet(item, p.walletHint);
          return item;
        }).toList();
        _step = _ScanStep.review;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _items = []; _errorMessage = _friendlyError(e); _step = _ScanStep.review; });
    }
  }

  Future<void> _parseText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _step = _ScanStep.loading; _errorMessage = null; });
    try {
      final parsed = await _parserService.parseTextInput(text);
      if (!mounted) return;
      final pid = _defaultProfileId;
      final today = DateTime.now();
      final defaultProfile = pid != null
          ? _profiles.cast<BudgetProfile?>().firstWhere((p) => p?.id == pid, orElse: () => null)
          : null;
      final defaultIsMonthly = defaultProfile?.isMonthly ?? false;
      final defaultBaseName = defaultProfile?.name;
      final defaultDisplayName = defaultProfile == null
          ? null
          : defaultIsMonthly
              ? '${defaultProfile.name} · ${DateFormat('MMM yyyy').format(today)}'
              : defaultProfile.name;
      setState(() {
        _items = parsed.map((p) {
          final txType = p.type == 'income' ? TransactionType.income : TransactionType.expense;
          final matched = _matchCategory(p.categoryName, txType);
          final item = _EditableItem(
            id: _uuid.v4(),
            amount: p.amount,
            type: txType,
            description: p.description,
            date: today,
            categoryName: p.categoryName,
            category: matched,
            profileId: pid,
            profileName: defaultDisplayName,
            profileBaseName: defaultBaseName,
            isMonthlyProfile: defaultIsMonthly,
            entityType: p.entityType,
            entityHint: p.entityHint,
            walletHint: p.walletHint,
          );
          _autoLinkEntity(item, p.entityType, p.entityHint);
          _autoLinkWallet(item, p.walletHint);
          return item;
        }).toList();
        _step = _ScanStep.review;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _items = []; _errorMessage = _friendlyError(e); _step = _ScanStep.review; });
    }
  }

  Future<void> _confirmAll() async {
    final toSave = _items.where((i) => i.included).toList();
    if (toSave.isEmpty) return;
    setState(() => _step = _ScanStep.saving);
    final userId = _authController.currentUser?.id ?? '';
    for (final item in toSave) {
      String? categoryId = item.category?.id;
      if (categoryId == null) {
        // Use proper category names for entity-linked transactions
        final String categoryName;
        final CategoryType catType;
        if (item.subscriptionId != null) {
          categoryName = 'Subscriptions';
          catType = CategoryType.expense;
        } else if (item.debtId != null && item.entityType == 'debt_payment') {
          categoryName = 'Debt Payment';
          catType = CategoryType.expense;
        } else if (item.debtId != null && item.entityType == 'lending') {
          categoryName = item.type == TransactionType.income ? 'Receivables' : 'Debt Payment';
          catType = item.type == TransactionType.income ? CategoryType.income : CategoryType.expense;
        } else if (item.goalId != null) {
          categoryName = 'Savings';
          catType = CategoryType.savings;
        } else {
          categoryName = item.categoryName.isNotEmpty ? item.categoryName : 'Other';
          catType = item.type == TransactionType.income ? CategoryType.income : CategoryType.expense;
        }
        categoryId = await _catController.findOrCreate(
          name: categoryName,
          type: catType,
          userId: userId,
        );
      }
      await _txController.createTransaction(Transaction(
        amount: item.amount,
        type: item.type,
        financeCategoryId: categoryId,
        date: item.date,
        description: item.description.isNotEmpty ? item.description : item.categoryName,
        budgetProfileId: item.profileId,
        subscriptionId: item.subscriptionId,
        debtId: item.debtId,
        goalId: item.goalId,
        walletId: item.walletId,
      ));

      if (item.subscriptionId != null || item.debtId != null || item.goalId != null) {
        try {
          await _applyEntitySideEffects(item);
        } catch (_) {}
      }
    }
    widget.onConfirmed?.call();
    if (mounted) Navigator.pop(context);
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('too large')) { return 'Image is too large. Try a smaller or lower-quality photo.'; }
    if (msg.contains('unsupported') || msg.contains('format') || msg.contains('invalid image')) { return 'This file type couldn\'t be read. Use a JPG or PNG image.'; }
    if (msg.contains('no transaction') || msg.contains('no item') || msg.contains('nothing found')) { return 'No transactions were detected. Make sure the document contains clear expense or income entries.'; }
    if (msg.contains('400') || msg.contains('badrequest') || msg.contains('unreadable')) { return 'The image couldn\'t be processed. Make sure the text is sharp and fully visible.'; }
    if (msg.contains('401') || msg.contains('unauthorized')) { return 'Session expired. Please sign in again.'; }
    if (msg.contains('429') || msg.contains('rate limit')) { return 'Too many requests. Wait a moment then try again.'; }
    if (msg.contains('timeout') || msg.contains('socketexception') || msg.contains('network')) { return 'Connection timed out. Check your internet and try again.'; }
    if (msg.contains('parse') || msg.contains('decode') || msg.contains('json')) { return 'The scan result couldn\'t be understood. Try again with a different image.'; }
    return 'We couldn\'t read this document. Try a clearer photo with better lighting and make sure all text is fully visible.';
  }

  void _showProfilePicker(_EditableItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text('Select Budget', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: fg))),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _profiles.length,
              itemBuilder: (_, i) {
                final p = _profiles[i];
                final sel = item.profileId == p.id;
                final displayMonth = DateFormat('MMM yyyy').format(item.date);
                final displayName = p.isMonthly ? '${p.name} · $displayMonth' : p.name;
                return ListTile(
                  title: Text(displayName, style: GoogleFonts.dmSans(fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: fg)),
                  subtitle: p.isMonthly
                      ? Text('Monthly', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary))
                      : null,
                  trailing: sel ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
                  onTap: () {
                    setState(() {
                      item.profileId = p.id;
                      item.profileBaseName = p.name;
                      item.isMonthlyProfile = p.isMonthly;
                      item.profileName = displayName;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  // Try to auto-link the entity from the AI hint so the chip starts green.
  void _autoLinkEntity(_EditableItem item, String? entityType, String? hint) {
    if (entityType == null) return;
    final h = hint?.toLowerCase() ?? '';

    switch (entityType) {
      case 'subscription':
        final subs = _subController.data ?? [];
        final match = subs.where((s) =>
            s.status == SubscriptionStatus.active &&
            (h.isEmpty || s.name.toLowerCase().contains(h) || (s.provider?.toLowerCase().contains(h) ?? false))
        ).firstOrNull;
        if (match != null) {
          item.subscriptionId = match.id;
          item.entityLabel = match.name;
        }
      case 'debt_payment':
        final debts = _debtController.data ?? [];
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
        final recv = _debtController.data ?? [];
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
        final goals = _goalController.data ?? [];
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

  void _autoLinkWallet(_EditableItem item, String? hint) {
    if (hint == null || hint.isEmpty) return;
    final h = hint.toLowerCase();
    final wallets = _walletController.data ?? [];
    final match = wallets.where((w) => w.name.toLowerCase().contains(h) || h.contains(w.name.toLowerCase())).firstOrNull;
    if (match != null) {
      item.walletId = match.id;
      item.walletName = match.name;
    }
  }

  Future<void> _applyEntitySideEffects(_EditableItem item) async {
    if (item.subscriptionId != null) {
      await _subController.pay(item.subscriptionId!);
    }

    // (payDebt only does an optimistic in-memory update which misses filtered caches)
    if (item.debtId != null) {
      final isPayment = item.entityType == 'debt_payment' ||
          (item.entityType == 'lending' && item.type == TransactionType.income);
      if (isPayment) {
        // Reload if null OR if the specific debt isn't in the current (possibly filtered) cache
        final cached = (_debtController.data ?? []).where((d) => d.id == item.debtId).firstOrNull;
        if (cached == null) await _debtController.loadDebts();
        final debt = (_debtController.data ?? [])
            .where((d) => d.id == item.debtId)
            .firstOrNull;
        if (debt != null) {
          final newRemaining = (debt.remainingAmount - item.amount).clamp(0.0, double.infinity);
          if (newRemaining <= 0) {
            await _debtController.updateDebt(debt.copyWith(
              remainingAmount: 0,
              status: DebtStatus.settled,
            ));
          } else {
            await _debtController.updateDebtPayment(item.debtId!, newRemaining);
          }
        }
      }
    }

    if (item.goalId != null) {
      await _goalController.contributeToGoal(item.goalId!, item.amount);
      if (_walletController.data == null) await _walletController.loadWallets();
      final goal = (_goalController.data ?? []).where((g) => g.id == item.goalId).firstOrNull;
      if (goal?.savingsBucketId != null) {
        final wallet = (_walletController.data ?? [])
            .where((w) => w.id == goal!.savingsBucketId)
            .firstOrNull;
        if (wallet != null) {
          await _walletController.updateWallet(
            wallet.copyWith(balance: wallet.balance + item.amount),
          );
        }
      }
    }
  }

  void _showEntityTypePicker(_EditableItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              setState(() { item.entityType = t.type; item.entityHint = null; });
              _showEntityPicker(item);
            },
          )),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  void _showEntityPicker(_EditableItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        final subs = (_subController.data ?? [])
            .where((s) => s.status == SubscriptionStatus.active)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        listContent = buildList<Subscription>(
          subs,
          (s) => s.name,
          (s) => s.id ?? '',
          (s) => s.provider ?? s.billingCycle.displayName,
          (_) => AppColors.warning,
          (s) => setState(() { item.subscriptionId = s.id; item.entityLabel = s.name; }),
        );
      case 'debt_payment':
        title = 'Link Debt';
        final debts = (_debtController.data ?? [])
            .where((d) => d.type == DebtType.borrowing && d.status == DebtStatus.active)
            .toList()
          ..sort((a, b) => a.personName.compareTo(b.personName));
        listContent = buildList<Debt>(
          debts,
          (d) => d.personName,
          (d) => d.id ?? '',
          (d) => '${currencyFormatter.format(d.remainingAmount, decimalDigits: 0)} remaining',
          (_) => AppColors.error,
          (d) => setState(() { item.debtId = d.id; item.entityLabel = d.personName; }),
        );
      case 'lending':
        title = 'Link Receivable';
        final receivables = (_debtController.data ?? [])
            .where((d) => d.type == DebtType.lending && d.status == DebtStatus.active)
            .toList()
          ..sort((a, b) => a.personName.compareTo(b.personName));
        listContent = buildList<Debt>(
          receivables,
          (d) => d.personName,
          (d) => d.id ?? '',
          (d) => '${currencyFormatter.format(d.remainingAmount, decimalDigits: 0)} remaining',
          (_) => AppColors.success,
          (d) => setState(() { item.debtId = d.id; item.entityLabel = d.personName; }),
        );
      case 'goal':
        title = 'Link Goal';
        final goals = (_goalController.data ?? [])
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
          (g) => setState(() { item.goalId = g.id; item.entityLabel = g.name; }),
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
                  setState(() {
                    item.subscriptionId = null;
                    item.debtId = null;
                    item.goalId = null;
                    item.entityLabel = null;
                    item.entityType = null;
                    item.entityHint = null;
                  });
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (_step) {
      _ScanStep.pick => _buildPickStep(isDark),
      _ScanStep.loading => _buildLoadingStep(isDark),
      _ScanStep.review => _buildReviewStep(isDark),
      _ScanStep.saving => _buildSavingStep(isDark),
    };
  }


  Widget _buildPickStep(bool isDark) {
    final bg = isDark ? AppColors.void_ : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + 24;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPad),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _Handle(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _textMode ? Icons.edit_note_rounded : Icons.document_scanner_outlined,
                    size: 22, color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _textMode ? 'Describe your expenses' : 'Add Expenses',
                    style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  Text(
                    _textMode ? 'Type naturally, AI will parse it' : 'Scan an image or type it out',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ])),
                if (_textMode)
                  GestureDetector(
                    onTap: () => setState(() { _textMode = false; _textCtrl.clear(); }),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _textMode
                    ? _buildTextInput(isDark, textPrimary)
                    : _buildImageOptions(isDark),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildImageOptions(bool isDark) {
    return Column(
      key: const ValueKey('image'),
      children: [
        if (!_isDesktop) ...[
          _SourceCard(isDark: isDark, icon: Icons.camera_alt_outlined,
              label: 'Camera', sublabel: 'Take a photo now',
              onTap: () => _pickImage(ImageSource.camera)),
          const SizedBox(height: 10),
        ],
        _SourceCard(isDark: isDark, icon: Icons.photo_library_outlined,
            label: _isDesktop ? 'Choose from Files' : 'Gallery',
            sublabel: _isDesktop ? 'JPG, PNG or WebP' : 'Pick from files',
            onTap: () => _pickImage(ImageSource.gallery)),
        const SizedBox(height: 10),
        _SourceCard(
          isDark: isDark,
          icon: Icons.edit_note_rounded,
          label: 'Type it out',
          sublabel: 'e.g. "500 groceries from GCash yesterday"',
          color: AppColors.success,
          onTap: () => setState(() => _textMode = true),
        ),
      ],
    );
  }

  Widget _buildTextInput(bool isDark, Color textPrimary) {
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.25) : AppColors.border.withValues(alpha: 0.5);
    return Column(
      key: const ValueKey('text'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textCtrl,
          autofocus: true,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. "spent 500 on groceries from GCash, paid 1200 electricity from BDO yesterday"',
            hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary, height: 1.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.success, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _textCtrl.text.trim().isEmpty ? null : _parseText,
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: Text('Parse with AI', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              disabledBackgroundColor: AppColors.textTertiary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildLoadingStep(bool isDark) {
    final bg = isDark ? AppColors.void_ : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Container(
      height: 240,
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Padding(padding: const EdgeInsets.all(14),
              child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5)),
        ),
        const SizedBox(height: 16),
        Text(
          _textMode ? 'Analysing your input…' : 'Scanning expenses…',
          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _textMode ? 'AI is parsing your description' : 'AI is reading your image',
          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
        ),
      ]),
    );
  }


  Widget _buildReviewStep(bool isDark) {
    final bg = isDark ? AppColors.void_ : AppColors.background;
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final includedCount = _items.where((i) => i.included).length;

    return DraggableScrollableSheet(
      initialChildSize: _errorMessage != null || _items.isEmpty ? 0.45 : 0.88,
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
              _Handle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _errorMessage != null
                          ? (_textMode ? 'Couldn\'t parse input' : 'Couldn\'t read document')
                          : _items.isEmpty
                              ? (_textMode ? 'Nothing found' : 'Nothing detected')
                              : '${_items.length} transaction${_items.length == 1 ? '' : 's'} found',
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    Text(
                      _errorMessage != null
                          ? (_textMode ? 'Try rephrasing your input' : 'See tips below and try again')
                          : _items.isEmpty
                              ? (_textMode ? 'Try describing your expenses more clearly' : 'Try a clearer photo of your document')
                              : 'Review and edit before saving',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ])),
                  TextButton.icon(
                    onPressed: () => setState(() { _step = _ScanStep.pick; _items = []; _errorMessage = null; }),
                    icon: Icon(_textMode ? Icons.edit_note_rounded : Icons.camera_alt_outlined, size: 14),
                    label: Text(_textMode ? 'Re-type' : 'Re-scan'),
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
          if (_errorMessage != null)
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
                    Expanded(child: Text(_errorMessage!, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.error, height: 1.45))),
                  ]),
                ),
                const SizedBox(height: 20),
                Text(
                  _textMode ? 'Tips for better results' : 'Tips for a better scan',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: 0.3),
                ),
                const SizedBox(height: 10),
                ...(_textMode ? [
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
          if (_items.isEmpty && _errorMessage == null)
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
                  _textMode
                      ? 'Nothing recognisable was found. Try describing amounts, what they were for, and which wallet.'
                      : 'The document may not contain recognisable expense data, or the image quality is too low. Try a clearer photo.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ]),
            ))),

          // Entity link legend – shown when any item has an unlinked entity chip
          if (_items.isNotEmpty && _items.any((i) => i.entityType != null))
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
          if (_items.isNotEmpty)
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ReviewItemTile(
                  key: ValueKey(_items[i].id),
                  item: _items[i],
                  isDark: isDark,
                  currencySymbol: _settingsController.data?.currency.symbol ?? '₱',
                  onChanged: () => setState(() {}),
                  onPickProfile: () => _showProfilePicker(_items[i]),
                  onPickCategory: () => _showCategoryPicker(_items[i]),
                  onPickWallet: () => _showItemWalletPicker(_items[i]),
                  onPickEntity: () => _items[i].entityType != null
                      ? _showEntityPicker(_items[i])
                      : _showEntityTypePicker(_items[i]),
                ),
              ),
            ),

          // Confirm bar
          if (_items.isNotEmpty)
            _ConfirmBar(isDark: isDark, count: includedCount, onConfirm: includedCount > 0 ? _confirmAll : null),
        ]),
      ),
    );
  }

  void _showItemWalletPicker(_EditableItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallets = _walletController.data ?? [];
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(children: [
              Text('Select Wallet', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary)),
              ),
            ]),
          ),
          if (wallets.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Text('No wallets yet. Create one in the Wallet tab.', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: wallets.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: borderColor, indent: 16, endIndent: 16),
                itemBuilder: (_, i) {
                  final w = wallets[i];
                  final sel = item.walletId == w.id;
                  final wColor = w.colorHex != null
                      ? Color(int.parse(w.colorHex!.replaceFirst('#', '0xff')))
                      : AppColors.accent;
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: wColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                      alignment: Alignment.center,
                      child: Icon(
                        w.type == WalletType.creditCard ? Icons.credit_card_outlined : Icons.account_balance_wallet_outlined,
                        size: 16, color: wColor,
                      ),
                    ),
                    title: Text(w.name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: fg)),
                    subtitle: Text(
                      '${currencyFormatter.format(w.balance, decimalDigits: 2)} • ${w.type.displayName}',
                      style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    trailing: sel ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
                    onTap: () {
                      setState(() { item.walletId = w.id; item.walletName = w.name; });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }


  Widget _buildSavingStep(bool isDark) {
    final bg = isDark ? AppColors.void_ : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Container(
      height: 200,
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5),
        const SizedBox(height: 16),
        Text('Saving transactions…', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 4),
        Text('Please wait', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }
}


class _EditableItem {
  final String id;
  double amount;
  TransactionType type;
  String description;
  DateTime date;
  String categoryName;
  FinanceCategory? category;
  String? profileId;
  String? profileName;
  String? profileBaseName;
  bool isMonthlyProfile;
  bool included;

  // Entity linking
  String? entityType;   // "subscription" | "debt_payment" | "lending" | "goal" | null
  String? entityHint;   // AI-suggested name to pre-filter picker
  String? subscriptionId;
  String? debtId;
  String? goalId;
  String? entityLabel;  // display name of the linked entity

  // Wallet linking
  String? walletId;
  String? walletName;
  String? walletHint;   // AI-suggested wallet name hint

  _EditableItem({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    required this.categoryName,
    this.category,
    this.profileId,
    this.profileName,
    this.profileBaseName,
    this.isMonthlyProfile = false,
    this.included = true,
    this.entityType,
    this.entityHint,
    this.walletHint,
  });
}


class _ReviewItemTile extends StatefulWidget {
  final _EditableItem item;
  final bool isDark;
  final String currencySymbol;
  final VoidCallback onChanged;
  final VoidCallback onPickProfile;
  final VoidCallback onPickCategory;
  final VoidCallback onPickWallet;
  final VoidCallback? onPickEntity;

  const _ReviewItemTile({
    super.key,
    required this.item,
    required this.isDark,
    required this.currencySymbol,
    required this.onChanged,
    required this.onPickProfile,
    required this.onPickCategory,
    required this.onPickWallet,
    this.onPickEntity,
  });

  @override
  State<_ReviewItemTile> createState() => _ReviewItemTileState();
}

class _ReviewItemTileState extends State<_ReviewItemTile> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;

  IconData _entityIcon(String type) => switch (type) {
    'subscription' => Icons.autorenew_rounded,
    'debt_payment' => Icons.arrow_upward_rounded,
    'lending'      => Icons.arrow_downward_rounded,
    'goal'         => Icons.flag_outlined,
    _              => Icons.link_rounded,
  };

  String _entityPlaceholder(String type, String? hint) {
    final suffix = hint != null ? ' ($hint)' : '';
    return switch (type) {
      'subscription' => 'Link Subscription$suffix',
      'debt_payment' => 'Link Debt$suffix',
      'lending'      => 'Link Receivable$suffix',
      'goal'         => 'Link Goal$suffix',
      _              => 'Link Entity',
    };
  }

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.item.description);
    _amountCtrl = TextEditingController(text: widget.item.amount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.item.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        widget.item.date = picked;
        if (widget.item.isMonthlyProfile && widget.item.profileBaseName != null) {
          widget.item.profileName = '${widget.item.profileBaseName!} · ${DateFormat('MMM yyyy').format(picked)}';
        }
      });
      widget.onChanged();
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final item = widget.item;
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final inputBg = isDark ? AppColors.void_ : AppColors.background;
    final borderColor = item.included
        ? AppColors.accent.withValues(alpha: 0.35)
        : AppColors.border.withValues(alpha: isDark ? 0.15 : 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = AppColors.border.withValues(alpha: isDark ? 0.12 : 0.3);
    final typeColor = item.type == TransactionType.income ? AppColors.success : AppColors.error;

    return AnimatedOpacity(
      opacity: item.included ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 160),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.included ? borderColor : AppColors.border.withValues(alpha: isDark ? 0.1 : 0.3),
            width: 0.5,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row: checkbox + description + amount + type toggle
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: item.included,
                onChanged: (v) { setState(() => item.included = v ?? true); widget.onChanged(); },
                activeColor: AppColors.accent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _descCtrl,
                enabled: item.included,
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  border: InputBorder.none,
                  hintText: 'Description',
                  hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary),
                ),
                onChanged: (v) => item.description = v,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _amountCtrl,
                enabled: item.included,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w700, color: typeColor),
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                onChanged: (v) => item.amount = double.tryParse(v) ?? item.amount,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: item.included ? () { setState(() { item.type = item.type == TransactionType.income ? TransactionType.expense : TransactionType.income; }); widget.onChanged(); } : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    item.type == TransactionType.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    size: 11, color: typeColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    item.type == TransactionType.income ? 'In' : 'Out',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: typeColor),
                  ),
                ]),
              ),
            ),
          ]),

          if (item.included) ...[
            const SizedBox(height: 8),
            // Chips row
            Wrap(spacing: 5, runSpacing: 5, children: [
              _ChipButton(
                icon: Icons.account_balance_wallet_outlined,
                label: item.profileName ?? 'Budget',
                color: item.profileName != null ? AppColors.accent : AppColors.error,
                isDark: isDark,
                onTap: widget.onPickProfile,
              ),
              _ChipButton(
                icon: Icons.category_outlined,
                label: item.category?.name ?? 'Category',
                color: item.category != null ? AppColors.textSecondary : AppColors.warning,
                isDark: isDark,
                onTap: widget.onPickCategory,
              ),
              _ChipButton(
                icon: Icons.account_balance_wallet_outlined,
                label: item.walletName ?? 'Wallet',
                color: item.walletId != null ? AppColors.accent : AppColors.warning,
                isDark: isDark,
                onTap: widget.onPickWallet,
              ),
              _ChipButton(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('MMM d').format(item.date),
                color: AppColors.textSecondary,
                isDark: isDark,
                onTap: _pickDate,
              ),
              _ChipButton(
                icon: item.entityType != null ? _entityIcon(item.entityType!) : Icons.link_rounded,
                label: item.entityLabel != null
                    ? item.entityLabel!
                    : item.entityType != null
                        ? _entityPlaceholder(item.entityType!, item.entityHint)
                        : 'Link',
                color: item.entityLabel != null ? AppColors.success : item.entityType != null ? AppColors.error : AppColors.textSecondary,
                isDark: isDark,
                onTap: widget.onPickEntity,
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}


class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  const _ChipButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(trailingIcon, size: 10, color: color.withValues(alpha: 0.7)),
          ],
        ]),
      ),
    );
  }
}


class _ConfirmBar extends StatelessWidget {
  final bool isDark;
  final int count;
  final VoidCallback? onConfirm;

  const _ConfirmBar({required this.isDark, required this.count, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: isDark ? 0.15 : 0.3))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: onConfirm != null ? AppColors.accent : AppColors.textTertiary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            onConfirm != null ? 'Save $count transaction${count == 1 ? '' : 's'}' : 'Select transactions to save',
            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }
}


class _SourceCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final Color? color;

  const _SourceCard({
    required this.isDark, required this.icon,
    required this.label, required this.sublabel, required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    final bg = isDark ? AppColors.cardDark : AppColors.background;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 22, color: c),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 2),
            Text(sublabel, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
        ]),
      ),
    );
  }
}


class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Center(child: Container(
      width: 36, height: 4,
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    )),
  );
}
