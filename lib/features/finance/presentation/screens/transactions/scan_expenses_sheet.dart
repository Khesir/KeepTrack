import 'dart:io';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
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
  final ReceiptParserService _parserService = ReceiptParserService();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  _ScanStep _step = _ScanStep.pick;
  File? _pickedFile;
  List<_EditableItem> _items = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _txController = locator.get<TransactionController>();
    _catController = locator.get<FinanceCategoryController>();
    _profileController = locator.get<BudgetProfileController>();
    _budgetController = locator.get<BudgetController>();
    _authController = locator.get<AuthController>();
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
  String? _profileNameFor(String? id) {
    if (id == null) return null;
    try { return _profiles.firstWhere((p) => p.id == id).name; }
    catch (_) { return null; }
  }

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
      final pname = _profileNameFor(pid);
      final today = DateTime.now();
      setState(() {
        _items = parsed.map((p) {
          final txType = p.type == 'income' ? TransactionType.income : TransactionType.expense;
          final matched = _matchCategory(p.categoryName, txType);
          return _EditableItem(
            id: _uuid.v4(),
            amount: p.amount,
            type: txType,
            description: p.description,
            date: today,
            categoryName: p.categoryName,
            category: matched,
            profileId: pid,
            profileName: pname,
          );
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
        final catType = item.type == TransactionType.income ? CategoryType.income : CategoryType.expense;
        categoryId = await _catController.findOrCreate(
          name: item.categoryName.isNotEmpty ? item.categoryName : 'Other',
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
      ));
    }
    widget.onConfirmed?.call();
    if (mounted) Navigator.pop(context);
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('too large')) return msg;
    if (msg.contains('400') || msg.contains('BadRequest')) return 'The image could not be read. Try a clearer photo.';
    if (msg.contains('401')) return 'Session expired. Please sign in again.';
    if (msg.contains('429')) return 'Too many requests. Please wait a moment.';
    if (msg.contains('timeout') || msg.contains('SocketException')) return 'Connection timed out. Check your internet.';
    return 'Something went wrong. Please try again.';
  }

  void _showProfilePicker(_EditableItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
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
                return ListTile(
                  title: Text(p.name, style: GoogleFonts.dmSans(fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: fg)),
                  trailing: sel ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent) : null,
                  onTap: () {
                    setState(() { item.profileId = p.id; item.profileName = p.name; });
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

  // ── Pick ─────────────────────────────────────────────────────────────────

  Widget _buildPickStep(bool isDark) {
    final bg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
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
                  child: Icon(Icons.document_scanner_outlined, size: 22, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Scan Expenses', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                  Text('AI reads your handwritten notes', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
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
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoadingStep(bool isDark) {
    final bg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
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
        Text('Scanning expenses…', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 4),
        Text('AI is reading your handwritten notes', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }

  // ── Review ────────────────────────────────────────────────────────────────

  Widget _buildReviewStep(bool isDark) {
    final bg = isDark ? const Color(0xFF1E1E1C) : AppColors.background;
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
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
                      _errorMessage != null ? 'Could not read image'
                          : _items.isEmpty ? 'Nothing found'
                          : '${_items.length} transaction${_items.length == 1 ? '' : 's'} found',
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    Text(
                      _items.isEmpty ? 'Try a clearer photo' : 'Review and edit before saving',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ])),
                  TextButton.icon(
                    onPressed: () => setState(() { _step = _ScanStep.pick; _items = []; _errorMessage = null; }),
                    icon: const Icon(Icons.camera_alt_outlined, size: 14),
                    label: const Text('Re-scan'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
            ]),
          ),

          // Error banner
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2), width: 0.5),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error))),
                ]),
              ),
            ),

          // Empty state
          if (_items.isEmpty && _errorMessage == null)
            Expanded(child: Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.image_search_rounded, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text('No transactions detected', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 6),
                Text('The image may be blurry or not contain expense data.',
                    style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
              ]),
            ))),

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
                  onChanged: () => setState(() {}),
                  onPickProfile: () => _showProfilePicker(_items[i]),
                  onPickCategory: () => _showCategoryPicker(_items[i]),
                ),
              ),
            ),

          // Confirm bar
          if (_items.isNotEmpty) _ConfirmBar(isDark: isDark, count: includedCount, onConfirm: includedCount > 0 ? _confirmAll : null),
        ]),
      ),
    );
  }

  // ── Saving ────────────────────────────────────────────────────────────────

  Widget _buildSavingStep(bool isDark) {
    final bg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
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

// ── Editable item ─────────────────────────────────────────────────────────────

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
  bool included;

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
    this.included = true,
  });
}

// ── Review tile ───────────────────────────────────────────────────────────────

class _ReviewItemTile extends StatefulWidget {
  final _EditableItem item;
  final bool isDark;
  final VoidCallback onChanged;
  final VoidCallback onPickProfile;
  final VoidCallback onPickCategory;

  const _ReviewItemTile({
    super.key,
    required this.item,
    required this.isDark,
    required this.onChanged,
    required this.onPickProfile,
    required this.onPickCategory,
  });

  @override
  State<_ReviewItemTile> createState() => _ReviewItemTileState();
}

class _ReviewItemTileState extends State<_ReviewItemTile> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;

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
      setState(() => widget.item.date = picked);
      widget.onChanged();
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final item = widget.item;
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = item.included
        ? AppColors.accent.withValues(alpha: 0.35)
        : AppColors.border.withValues(alpha: isDark ? 0.15 : 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = AppColors.border.withValues(alpha: isDark ? 0.12 : 0.3);
    final typeColor = item.type == TransactionType.income ? AppColors.success : AppColors.error;

    return AnimatedOpacity(
      opacity: item.included ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 160),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Row 1: checkbox + description + type ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(
                width: 28,
                child: Checkbox(
                  value: item.included,
                  onChanged: (v) { setState(() => item.included = v ?? true); widget.onChanged(); },
                  activeColor: AppColors.accent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _descCtrl,
                  enabled: item.included,
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                  decoration: InputDecoration(
                    isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none,
                    hintText: 'Description',
                    hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textTertiary),
                  ),
                  onChanged: (v) => item.description = v,
                ),
              ),
              const SizedBox(width: 8),
              // Type toggle
              GestureDetector(
                onTap: item.included ? () { setState(() { item.type = item.type == TransactionType.income ? TransactionType.expense : TransactionType.income; }); widget.onChanged(); } : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: typeColor.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text(
                    item.type == TransactionType.income ? 'Income' : 'Expense',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: typeColor),
                  ),
                ),
              ),
            ]),
          ),

          // ── Row 2: Amount (prominent) ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 2, 12, 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₱', style: GoogleFonts.dmMono(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              const SizedBox(width: 2),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _amountCtrl,
                  enabled: item.included,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.dmMono(
                    fontSize: 28, fontWeight: FontWeight.w700, color: typeColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                  onChanged: (v) => item.amount = double.tryParse(v) ?? item.amount,
                ),
              ),
            ]),
          ),

          Divider(height: 1, color: divColor),

          // ── Row 3: chips ─────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
            child: Row(children: [
              // Budget profile
              _ChipButton(
                icon: Icons.account_balance_wallet_outlined,
                label: item.profileName ?? 'Select Budget',
                color: item.profileName != null ? AppColors.accent : AppColors.error,
                isDark: isDark,
                onTap: item.included ? widget.onPickProfile : null,
              ),
              const SizedBox(width: 6),
              // Date
              _ChipButton(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('MMM d, yyyy').format(item.date),
                color: AppColors.textSecondary,
                isDark: isDark,
                onTap: item.included ? _pickDate : null,
              ),
              const SizedBox(width: 6),
              // Category
              _ChipButton(
                icon: Icons.category_outlined,
                label: item.category?.name ?? 'Select Category',
                color: item.category != null ? AppColors.textSecondary : AppColors.warning,
                isDark: isDark,
                onTap: item.included ? widget.onPickCategory : null,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Chip button ───────────────────────────────────────────────────────────────

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

// ── Confirm bar ───────────────────────────────────────────────────────────────

class _ConfirmBar extends StatelessWidget {
  final bool isDark;
  final int count;
  final VoidCallback? onConfirm;

  const _ConfirmBar({required this.isDark, required this.count, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
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

// ── Source card ───────────────────────────────────────────────────────────────

class _SourceCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _SourceCard({
    required this.isDark, required this.icon,
    required this.label, required this.sublabel, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2C2C2A) : AppColors.background;
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
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 22, color: AppColors.accent),
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

// ── Drag handle ───────────────────────────────────────────────────────────────

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
