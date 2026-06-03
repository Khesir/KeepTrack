import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/screens/budget_month_screen.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/screens/budget_simple_view.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/dialogs/budget_settings_dialog.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'budget_profile_sheet.dart';
import 'budget_selection_screen.dart';
import 'profile_create_group_sheet.dart';

class BudgetTabScreen extends StatefulWidget {
  const BudgetTabScreen({super.key});

  @override
  State<BudgetTabScreen> createState() => _BudgetTabScreenState();
}

class _BudgetTabScreenState extends State<BudgetTabScreen> {
  late final BudgetController _budgetController;
  late final BudgetProfileController _profileController;
  late final MonthPlanController _monthPlanController;

  // Navigation state
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

  bool get _inBudget => _activeProfile != null;

  void _back() {
    _profileController.selectedProfileId = null;
    setState(() {
      _activeProfile = null;
      _sheetMode = false;
    });
  }

  void _toggleView() => setState(() => _sheetMode = !_sheetMode);


  void _openSettings(List<Budget> monthBudgets) {
    final profile = _activeProfile!;
    final profileColor = profile.colorHex != null
        ? Color(int.parse(profile.colorHex!.replaceFirst('#', '0xFF')))
        : AppColors.accent;
    // Custom profile — no month plan concept; profile-level settings only
    BudgetSettingsDialog.show(
      context,
      monthLabel: profile.name,
      profileColor: profileColor,
      onEditProfile: _editProfile,
      onDeleteProfile: () => _confirmDeleteProfile(profile),
    );
  }


  Future<void> _confirmCloseProfile(BudgetProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Close "${profile.name}"?'),
        content: const Text(
          'This profile will be marked as completed. You can still view it.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Close Budget')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _profileController.updateProfile(
      profile.copyWith(status: BudgetProfileStatus.completed),
    );

    final s = _profileController.state;
    if (s is AsyncData<List<BudgetProfile>> && mounted) {
      final updated = s.data.firstWhere(
        (p) => p.id == profile.id,
        orElse: () => profile.copyWith(status: BudgetProfileStatus.completed),
      );
      setState(() => _activeProfile = updated);
    }
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

  Future<void> _confirmDeleteProfile(BudgetProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${profile.name}"?'),
        content: const Text(
          'The profile and all its budget groups, categories, and plan data will be permanently removed.',
        ),
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

    // Delete all budget groups for the profile
    final budgets = _budgetController.data ?? [];
    for (final b in budgets.where((b) => b.budgetProfileId == profile.id)) {
      if (b.id != null) await _budgetController.deleteBudget(b.id!);
    }

    // Delete the profile itself
    if (profile.id != null) {
      await _profileController.deleteProfile(profile.id!);
    }

    // Navigate back to profile selection
    if (mounted) _back();
  }

  void _showAddProfileGroup(bool isIncome, String monthKey) {
    final profile = _activeProfile!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileCreateGroupSheet(
        profile: profile,
        isIncome: isIncome,
        monthKey: monthKey,
        budgetController: _budgetController,
        monthPlanController: _monthPlanController,
        onCreated: () => _budgetController.loadBudgets(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Selection screen
    if (!_inBudget) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: BudgetSelectionScreen(
          onMonthlyTap: () {},
          onProfileTap: (p) => setState(() {
            _activeProfile = p;
            _sheetMode = false;
            _profileController.selectedProfileId = p.id;
          }),
          onNewProfile: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => BudgetProfileSheet(controller: _profileController),
          ),
        ),
      );
    }

    final profileColor = _activeProfile!.colorHex != null
        ? Color(int.parse(_activeProfile!.colorHex!.replaceFirst('#', '0xFF')))
        : AppColors.accent;

    // Sheets mode
    if (_sheetMode) {
      return BudgetMonthScreen(
        onToggleView: _toggleView,
        onOpenSettings: () => _openSettings([]),
        onBack: _back,
        budgetProfileId: _activeProfile!.id,
        profileIsMonthly: _activeProfile!.isMonthly,
      );
    }

    // Simple mode
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BudgetSimpleView(
        selectedTab: _simpleTab,
        onTabChange: (i) => setState(() => _simpleTab = i),
        onBack: _back,
        budgetProfileId: _activeProfile!.id,
        profileName: _activeProfile!.name,
        profileAccentColor: profileColor,
        profileStartDate: _activeProfile!.startDate,
        profileEndDate: _activeProfile!.endDate,
        profileIsMonthly: _activeProfile!.isMonthly,
        onAddProfileGroup: _showAddProfileGroup,
        onToggleView: _toggleView,
        onOpenSettings: _openSettings,
        onEditProfile: _editProfile,
        onDeleteProfile: () => _confirmDeleteProfile(_activeProfile!),
      ),
    );
  }
}
