import 'package:flutter/material.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';
import 'tabs/accounts_tab_new.dart';
import 'tabs/budgets_tab_new.dart';
import 'tabs/transactions_tab_new.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(
                icon: Icon(Icons.account_balance_wallet),
                text: 'Accounts',
              ),
              Tab(
                icon: Icon(Icons.pie_chart),
                text: 'Budgets',
              ),
              Tab(
                icon: Icon(Icons.receipt_long),
                text: 'Transactions',
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
              TransactionsTabNew(),
            ],
          ),
        ),
      ],
    );
  }
}
