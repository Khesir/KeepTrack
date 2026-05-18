import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/screens/budget_month_screen.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/screens/budget_simple_view.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/budget_settings_sheet.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/finance/presentation/screens/transactions/create_transaction_sheet.dart';
import 'budget_profile_sheet.dart';
import 'budget_selection_screen.dart';
import 'profile_create_group_sheet.dart';

class BudgetTabScreen extends StatefulWidget {
  final bool navVisible;
  const BudgetTabScreen({super.key, this.navVisible = true});

  @override
  State<BudgetTabScreen> createState() => _BudgetTabScreenState();
}

class _BudgetTabScreenState extends State<BudgetTabScreen> {
  late final BudgetController _budgetController;
  late final BudgetProfileController _profileController;
  late final MonthPlanController _monthPlanController;

  // Navigation state
  bool _showMonthly = false;
  BudgetProfile? _activeProfile;
  bool _sheetMode = false;
  int _simpleTab = 0;

  @override
  void initState() {
    super.initState();
    _budgetController = locator.get<BudgetController>();
    _profileController = locator.get<BudgetProfileController>();
    _monthPlanController = locator.get<MonthPlanController>();
  }

  bool get _inBudget => _showMonthly || _activeProfile != null;

  void _back() => setState(() {
    _showMonthly = false;
    _activeProfile = null;
    _sheetMode = false;
  });

  void _toggleView() => setState(() => _sheetMode = !_sheetMode);

  // ── Settings ──────────────────────────────────────────────────────────────

  void _openProfileSettings() {
    final profile = _activeProfile!;
    BudgetSettingsSheet.show(
      context,
      monthLabel: profile.name,
      onEditBudget: _editProfile,
      onDeleteBudget: () => _confirmDeleteProfileBudgets(profile),
    );
  }

  Future<void> _editProfile() async {
    final profile = _activeProfile!;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetProfileSheet(controller: _profileController, existing: profile),
    );
    final s = _profileController.state;
    if (s is AsyncData<List<BudgetProfile>> && mounted) {
      final updated = s.data.firstWhere((p) => p.id == profile.id, orElse: () => profile);
      setState(() => _activeProfile = updated);
    }
  }

  Future<void> _confirmDeleteProfileBudgets(BudgetProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete budgets for "${profile.name}"?'),
        content: const Text('All budget groups and categories for this profile will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final budgets = _budgetController.data ?? [];
    for (final b in budgets.where((b) => b.budgetProfileId == profile.id)) {
      if (b.id != null) await _budgetController.deleteBudget(b.id!);
    }
  }

  void _showAddProfileGroup(bool isIncome) {
    final profile = _activeProfile!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileCreateGroupSheet(
        profile: profile,
        isIncome: isIncome,
        budgetController: _budgetController,
        monthPlanController: _monthPlanController,
        onCreated: () => _budgetController.loadBudgets(),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final bottomOffset = isMobile && widget.navVisible ? 74.0 : 0.0;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      padding: EdgeInsets.only(bottom: bottomOffset),
      child: FloatingActionButton.extended(
        onPressed: () => CreateTransactionSheet.show(
          context,
          onCreated: () {
            final now = DateTime.now();
            locator.get<TransactionController>().loadTransactionsByDateRange(
              DateTime(now.year, now.month, 1),
              DateTime(now.year, now.month + 1, 1),
            );
          },
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Transaction'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Selection screen
    if (!_inBudget) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: _buildFab(),
        body: BudgetSelectionScreen(
          onMonthlyTap: () => setState(() { _showMonthly = true; _sheetMode = false; }),
          onProfileTap: (p) => setState(() { _activeProfile = p; _sheetMode = false; }),
          onNewProfile: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => BudgetProfileSheet(controller: _profileController),
          ),
        ),
      );
    }

    final isProfile = _activeProfile != null;
    final profileColor = isProfile && _activeProfile!.colorHex != null
        ? Color(int.parse(_activeProfile!.colorHex!.replaceFirst('#', '0xFF')))
        : AppColors.accent;

    // Sheets mode
    if (_sheetMode) {
      return BudgetMonthScreen(
        onToggleView: _toggleView,
        onOpenSettings: isProfile ? _openProfileSettings : null,
        budgetProfileId: _activeProfile?.id,
      );
    }

    // Simple mode
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildFab(),
      body: BudgetSimpleView(
        selectedTab: _simpleTab,
        onTabChange: (i) => setState(() => _simpleTab = i),
        onBack: _back,
        budgetProfileId: _activeProfile?.id,
        profileName: _activeProfile?.name,
        profileAccentColor: isProfile ? profileColor : null,
        profileStartDate: _activeProfile?.startDate,
        profileEndDate: _activeProfile?.endDate,
        profileIsMonthly: _activeProfile?.isMonthly ?? false,
        onAddProfileGroup: isProfile ? _showAddProfileGroup : null,
        onToggleView: _toggleView,
        onOpenSettings: isProfile ? _openProfileSettings : null,
      ),
    );
  }
}
