import 'dart:io';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/state/stream_state.dart';
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
import 'package:keep_track/features/finance/presentation/state/wallet_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:uuid/uuid.dart';
import '../../helpers/editable_scan_item.dart';
import '../../helpers/scan_entity_effects.dart';
import '../../sections/scan_review_section.dart';
import '../../sheets/scan_entity_link_picker_sheet.dart';
import '../../sheets/scan_profile_picker_sheet.dart';
import '../../sheets/scan_wallet_picker_sheet.dart';
import '../../widgets/scan_pick_step.dart';
import '../../widgets/transaction_category_picker.dart';

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
  late final WalletController _walletController;
  final ReceiptParserService _parserService = ReceiptParserService();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  _ScanStep _step = _ScanStep.pick;
  File? _pickedFile;
  List<EditableScanItem> _items = [];
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

  void _showCategoryPicker(EditableScanItem item) {
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
          final item = EditableScanItem(
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
          autoLinkScanEntity(item, p.entityType, p.entityHint);
          autoLinkScanWallet(item, p.walletHint);
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
          final item = EditableScanItem(
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
          autoLinkScanEntity(item, p.entityType, p.entityHint);
          autoLinkScanWallet(item, p.walletHint);
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
          await applyScanEntitySideEffects(item);
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

  void _showProfilePicker(EditableScanItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScanProfilePickerSheet.show(
      context,
      isDark: isDark,
      profiles: _profiles,
      selectedProfileId: item.profileId,
      selectedDate: item.date,
      onSelect: (id, baseName, isMonthly, displayName) {
        setState(() {
          item.profileId = id;
          item.profileBaseName = baseName;
          item.isMonthlyProfile = isMonthly;
          item.profileName = displayName;
        });
      },
    );
  }

  void _showItemWalletPicker(EditableScanItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScanWalletPickerSheet.show(
      context,
      isDark: isDark,
      wallets: _walletController.data ?? [],
      selectedWalletId: item.walletId,
      onSelect: (id, name) {
        setState(() { item.walletId = id; item.walletName = name; });
      },
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
    return ScanPickStep(
      isDark: isDark,
      textMode: _textMode,
      isDesktop: _isDesktop,
      textController: _textCtrl,
      onPickImage: _pickImage,
      onSetTextMode: (v) => setState(() => _textMode = v),
      onParseText: _parseText,
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
    final includedCount = _items.where((i) => i.included).length;
    return ScanReviewSection(
      isDark: isDark,
      textMode: _textMode,
      items: _items,
      errorMessage: _errorMessage,
      currencySymbol: _settingsController.data?.currency.symbol ?? '₱',
      onRescan: () => setState(() { _step = _ScanStep.pick; _items = []; _errorMessage = null; }),
      onItemChanged: () => setState(() {}),
      onPickProfile: _showProfilePicker,
      onPickCategory: _showCategoryPicker,
      onPickWallet: _showItemWalletPicker,
      onPickEntity: (item) {
        void onChanged() => setState(() {});
        if (item.entityType != null) {
          ScanEntityLinkPickerSheet.showEntityPicker(context, isDark: isDark, item: item, onChanged: onChanged);
        } else {
          ScanEntityLinkPickerSheet.showTypePicker(context, isDark: isDark, item: item, onChanged: onChanged);
        }
      },
      onConfirm: includedCount > 0 ? _confirmAll : null,
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
