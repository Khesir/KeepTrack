import 'package:flutter/material.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';
import 'tabs/accounts/accounts_tab_new.dart';
import 'tabs/budgets/budgets_tab_new.dart';
import 'tabs/debts/debts_tab_new.dart';
import 'tabs/goals/goals_tab.dart';
import 'tabs/planned_payments/planned_payments_tab.dart';

/// Main Finance Screen with Inner Tabs
class FinanceMainScreen extends ScopedScreen {
  const FinanceMainScreen({super.key});

  @override
  State<FinanceMainScreen> createState() => _FinanceMainScreenState();
}

class _FinanceMainScreenState extends ScopedScreenState<FinanceMainScreen>
    with AppLayoutControlled, SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void registerServices() {
    // Services will be wired later
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void onReady() {
    configureLayout(title: 'Finance', showBottomNav: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Inner Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: const [
              Tab(
                icon: Icon(Icons.account_balance_wallet, size: 20),
                text: 'Accounts',
                height: 65,
              ),
              Tab(
                icon: Icon(Icons.pie_chart, size: 20),
                text: 'Budgets',
                height: 65,
              ),
              Tab(icon: Icon(Icons.flag, size: 20), text: 'Goals', height: 65),
              Tab(
                icon: Icon(Icons.swap_horiz, size: 20),
                text: 'Debts',
                height: 65,
              ),
              Tab(
                icon: Icon(Icons.event_repeat, size: 20),
                text: 'Payments',
                height: 65,
              ),
            ],
          ),
        ),
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              AccountsTabNew(),
              BudgetsTabNew(),
              GoalsTabNew(),
              DebtsTabNew(),
              PlannedPaymentsTabNew(),
            ],
          ),
        ),
      ],
    );
  }
}
